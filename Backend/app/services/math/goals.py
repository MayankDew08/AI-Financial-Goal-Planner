"""
LangGraph-based Conversational Chatbot Service.

This service implements a stateful conversational interface for financial planning.
The graph orchestrates:
1. Intent detection
2. Slot collection (field-by-field)
3. Confirmation gate
4. Tool invocation (deterministic math engines)
5. AI explanation (reads only computed numbers)
"""

import json
import logging
from typing import TypedDict, Any, Optional, List
from datetime import datetime

from langgraph.graph import StateGraph, END
from langgraph.checkpoint.memory import MemorySaver

from app.schemas.chat import (
    Intent,
    SLOTS,
    REQUIRED_SLOTS,
    OPTIONAL_SLOTS,
    Slot,
)
from app.services.math.goals import (
    explain_retirement_plan_with_ai,
    explain_one_time_goal_with_ai,
    explain_recurring_goal_with_ai,
)
from app.services.math.conflict_engine import explain_conflict_result
from app.services.utils import call_llm_json, call_llm

logger = logging.getLogger("chatbot_graph")


# ─── STATE DEFINITION ──────────────────────────────────────────────────────

class ChatState(TypedDict):
    """Complete state for one chat session"""
    # Core
    messages: List[dict]        # [{"role": "user", "content": "..."}, ...]
    user_id: str
    session_id: str

    # Intent
    intent: Optional[str]

    # Slot collection
    collected: dict             # {field_name: validated_value, ...}
    pending: List[str]          # field names still needed
    current_slot: Optional[str] # which slot we are asking right now

    # Optional slot tracking
    optional_pending: List[str]
    skip_optionals: bool

    # Confirmation
    awaiting_confirmation: bool
    confirmed: Optional[bool]

    # Tool result
    tool_result: Optional[dict]
    tool_error: Optional[str]

    # Output
    reply: str
    action_state: str           # idle | collecting | confirming | done
    can_confirm: bool


# ─── HELPER FUNCTIONS ──────────────────────────────────────────────────────

def get_slot_def(intent: str, field_name: str) -> Optional[Slot]:
    """Get slot definition for intent+field"""
    intent_enum = normalize_intent(intent)
    if intent_enum not in SLOTS:
        return None
    for slot in SLOTS[intent_enum]:
        if slot.name == field_name:
            return slot
    return None


def normalize_intent(intent_value: Any) -> Intent:
    """Convert raw LLM or state intent values into the Intent enum."""
    if isinstance(intent_value, Intent):
        return intent_value
    if not intent_value:
        return Intent.UNCLEAR
    try:
        return Intent(str(intent_value).strip().lower())
    except ValueError:
        return Intent.UNCLEAR


def build_confirmation_summary(state: ChatState) -> str:
    """Build a human-readable confirmation message"""
    intent = normalize_intent(state["intent"])
    collected = state["collected"]

    lines = ["\n📋 **Confirmation Summary:**\n"]

    for field_name, value in collected.items():
        slot_def = get_slot_def(intent, field_name)
        if slot_def:
            label = field_name.replace("_", " ").title()
            lines.append(f"  • {label}: {value}")

    lines.append("\nPlease confirm: Press **Yes** to proceed, **No** to edit.")
    return "".join(lines)


def normalize_value(text: str, field_type: type) -> Any:
    """
    Parse user text into typed value.
    Handles casual language: "15k" → 15000, "12%" → 0.12 or kept as int
    """
    text = text.strip()

    # Percent normalization
    if "%" in text:
        text = text.replace("%", "").strip()

    # Rupee normalization (k, lakh, crore)
    if "k" in text.lower():
        base = float(text.lower().replace("k", ""))
        return field_type(base * 1000)

    if "lakh" in text.lower():
        base = float(text.lower().replace("lakh", ""))
        return field_type(base * 100000)

    if "crore" in text.lower():
        base = float(text.lower().replace("crore", ""))
        return field_type(base * 10000000)

    # Direct cast
    return field_type(text)


def log_audit(event: str, user_id: str, intent: str, payload: dict):
    """Audit log for HITL and traceability"""
    logger.info({
        "event": event,
        "user_id": user_id,
        "intent": intent,
        "timestamp": datetime.utcnow().isoformat(),
        "payload": payload,
    })


# ─── NODE 1: INTENT CLASSIFICATION ──────────────────────────────────────────

def intent_node(state: ChatState) -> ChatState:
    """
    Classify user message into an intent.
    Also extract any slot values mentioned in the message.
    """
    last_message = state["messages"][-1]["content"]

    prompt = f"""
You are a financial planning chatbot. Classify the user's message into exactly ONE intent.
Return ONLY a valid JSON object with no markdown, no code blocks, no extra text.

Available intents:
- retirement_explain: User asks about their existing retirement plan
- retirement_create: User wants to create/plan for retirement
- onetime_explain: User asks about an existing one-time goal
- onetime_create: User wants to create a one-time goal (e.g., buy a car, house down payment)
- recurring_explain: User asks about an existing recurring goal
- recurring_create: User wants to create a recurring goal (e.g., annual vacation, car replacement)
- scenario_simulate: User says "what if", "suppose", "if I change", "what happens if"
- portfolio_overview: User asks about all goals, complete picture, total planning
- unclear: Cannot determine intent

Also extract ANY slot values already mentioned in the message.

User Message: "{last_message}"

Examples of extraction:
- "I want to retire at 60" → extracted_slots: {{"retirement_age": 60}}
- "Save for a house worth 80 lakhs in 5 years" → extracted_slots: {{"goal_name": "House", "goal_amount": 8000000, "years_to_goal": 5}}
- "What if I retire at 55?" → intent: scenario_simulate, extracted_slots: {{"changed_param": "retirement_age", "new_value": 55}}
- "Plan a 50k annual vacation trip every 2 years" → intent: recurring_create, extracted_slots: {{"goal_name": "Vacation", "current_cost": 50000, "frequency_years": 2}}

Return JSON with exactly these fields:
{{
    "intent": "<intent>",
    "extracted_slots": {{"field_name": value, ...}},
    "confidence": 0.0 to 1.0
}}
"""

    response = call_llm_json(prompt)
    intent = normalize_intent(response.get("intent", Intent.UNCLEAR))
    extracted = response.get("extracted_slots", {})
    confidence = response.get("confidence", 0)

    if confidence < 0.5:
        intent = Intent.UNCLEAR

    # Merge extracted slots
    collected = dict(state.get("collected", {}))
    for field, value in extracted.items():
        slot_def = get_slot_def(intent, field)
        if slot_def:
            try:
                cast_value = normalize_value(str(value), slot_def.type)
                if slot_def.validator(cast_value):
                    collected[field] = cast_value
            except (ValueError, TypeError):
                pass  # Ignore invalid extracted values

    # Compute pending required slots
    required = REQUIRED_SLOTS.get(intent, [])
    pending = [f for f in required if f not in collected]

    state["intent"] = intent.value
    state["collected"] = collected
    state["pending"] = pending

    return state


def route_from_intent(state: ChatState) -> str:
    """Route based on detected intent"""
    intent = normalize_intent(state["intent"])

    if intent == Intent.UNCLEAR:
        return "clarify_node"

    if intent in [
        Intent.RETIREMENT_EXPLAIN,
        Intent.ONETIME_EXPLAIN,
        Intent.RECURRING_EXPLAIN,
        Intent.PORTFOLIO_OVERVIEW,
    ]:
        return "explain_node"

    # Create / simulate intents go to slot collection
    return "slot_node"


def route_from_entry(state: ChatState) -> str:
    """Resume an in-progress conversation or start a new one."""
    if state.get("awaiting_confirmation") or state.get("action_state") == "confirming":
        return "confirm_node"

    if state.get("current_slot") or state.get("pending"):
        return "slot_node"

    return "intent_node"


# ─── NODE 2: SLOT COLLECTION ───────────────────────────────────────────────

def slot_node(state: ChatState) -> ChatState:
    """
    Collect missing fields one at a time.
    Loop until all required (and optionally optional) slots are filled.
    """
    current_slot_name = state.get("current_slot")
    last_message = state["messages"][-1]["content"]

    collected = dict(state.get("collected", {}))
    pending = list(state.get("pending", []))
    optional_pending = list(state.get("optional_pending", []))
    skip_optionals = bool(state.get("skip_optionals", False))
    current_intent = normalize_intent(state.get("intent"))

    if current_slot_name and current_slot_name in optional_pending:
        normalized_message = last_message.lower().strip()

        if normalized_message in {"skip", "no", "n"}:
            optional_pending.remove(current_slot_name)
            state["optional_pending"] = optional_pending
            state["current_slot"] = None

            if optional_pending and not skip_optionals:
                next_opt = optional_pending[0]
                slot_def = get_slot_def(state["intent"], next_opt)
                state["current_slot"] = next_opt
                state["reply"] = (
                    f"📌 **Optional:** {slot_def.prompt}\n\n"
                    "(Say 'skip' or 'no' to continue without answering)"
                )
                state["action_state"] = "collecting"
                state["can_confirm"] = False
                return state

            state["current_slot"] = None
            state["action_state"] = "confirming"
            state["can_confirm"] = True
            state["awaiting_confirmation"] = True
            state["reply"] = build_confirmation_summary(state)
            return state

        slot_def = get_slot_def(state["intent"], current_slot_name)

        try:
            cast_value = normalize_value(last_message.strip(), slot_def.type)

            if slot_def.validator(cast_value):
                collected[current_slot_name] = cast_value
                optional_pending.remove(current_slot_name)
                state["collected"] = collected
                state["optional_pending"] = optional_pending
                state["current_slot"] = None
            else:
                state["reply"] = f"❌ {slot_def.error_msg}\n\n{slot_def.prompt}"
                state["action_state"] = "collecting"
                state["can_confirm"] = False
                return state

        except (ValueError, TypeError):
            state["reply"] = f"I didn't quite understand that.\n\n{slot_def.prompt}"
            state["action_state"] = "collecting"
            state["can_confirm"] = False
            return state

    # If we just asked for a field, try to fill it
    if current_slot_name and current_slot_name in pending:
        slot_def = get_slot_def(state["intent"], current_slot_name)

        try:
            cast_value = normalize_value(last_message.strip(), slot_def.type)

            if slot_def.validator(cast_value):
                # Valid — store it
                collected[current_slot_name] = cast_value
                pending.remove(current_slot_name)
                state["collected"] = collected
                state["pending"] = pending
                state["current_slot"] = None
            else:
                # Failed validation — ask again with error
                state["reply"] = f"❌ {slot_def.error_msg}\n\n{slot_def.prompt}"
                state["action_state"] = "collecting"
                state["can_confirm"] = False
                return state

        except (ValueError, TypeError):
            # Cannot cast — ask again
            state["reply"] = f"I didn't quite understand that.\n\n{slot_def.prompt}"
            state["action_state"] = "collecting"
            state["can_confirm"] = False
            return state

    # Update pending after possible fill
    required = REQUIRED_SLOTS.get(current_intent, [])
    pending = [f for f in required if f not in collected]
    state["collected"] = collected
    state["pending"] = pending

    if pending:
        # Ask for next missing field
        next_field = pending[0]
        slot_def = get_slot_def(state["intent"], next_field)

        state["current_slot"] = next_field
        state["reply"] = slot_def.prompt
        state["action_state"] = "collecting"
        state["can_confirm"] = False
        return state

    # All required slots filled — move toward optional slots
    optional = OPTIONAL_SLOTS.get(current_intent, [])
    optional_pending = [f for f in optional if f not in collected]
    state["optional_pending"] = optional_pending

    if optional_pending and not state.get("skip_optionals"):
        # Ask first optional
        next_opt = optional_pending[0]
        slot_def = get_slot_def(state["intent"], next_opt)
        state["current_slot"] = next_opt
        state["reply"] = f"📌 **Optional:** {slot_def.prompt}\n\n(Say 'skip' or 'no' to continue without answering)"
        state["action_state"] = "collecting"
        state["can_confirm"] = False
        return state

    # All slots done — go to confirm
    state["current_slot"] = None
    state["action_state"] = "confirming"
    state["can_confirm"] = True
    state["awaiting_confirmation"] = True
    state["reply"] = build_confirmation_summary(state)

    return state


def route_from_slot(state: ChatState) -> str:
    """Stop after one response; continue on the next user turn."""
    return END


# ─── NODE 3: CONFIRMATION GATE ────────────────────────────────────────────

def confirm_node(state: ChatState) -> ChatState:
    """
    Ask for explicit confirmation before any write/computation.
    Reparse optional slots if user says 'no'.
    """
    last_message = state["messages"][-1]["content"].lower().strip()

    yes_signals = ["yes", "ok", "okay", "sure", "confirm", "go ahead", "create", "save", "do it", "correct", "right", "proceed", "y"]
    no_signals = ["no", "n", "cancel", "stop", "change", "edit", "wrong", "incorrect", "wait", "hold on", "not yet"]

    is_yes = any(sig in last_message for sig in yes_signals)
    is_no = any(sig in last_message for sig in no_signals)

    # Check for optional slot skip signals
    if state.get("current_slot") and "skip" in last_message:
        collected = dict(state["collected"])
        optional_pending = list(state.get("optional_pending", []))

        if state["current_slot"] in optional_pending:
            optional_pending.remove(state["current_slot"])
            state["optional_pending"] = optional_pending
            state["current_slot"] = None

            # Ask next optional if any
            if optional_pending:
                next_opt = optional_pending[0]
                slot_def = get_slot_def(state["intent"], next_opt)
                state["current_slot"] = next_opt
                state["reply"] = f"📌 **Optional:** {slot_def.prompt}\n\n(Say 'skip' to continue)"
                state["action_state"] = "collecting"
                return state

            # All optionals done
            state["action_state"] = "confirming"
            state["can_confirm"] = True
            state["awaiting_confirmation"] = True
            state["reply"] = build_confirmation_summary(state)
            return state

    if is_yes:
        state["confirmed"] = True
        state["awaiting_confirmation"] = False
        state["action_state"] = "done"

        log_audit(
            "plan_confirmed",
            state["user_id"],
            state["intent"],
            state["collected"],
        )

        return state

    if is_no:
        state["confirmed"] = False
        state["awaiting_confirmation"] = False
        state["current_slot"] = None
        state["pending"] = []
        state["collected"] = {}
        state["optional_pending"] = []
        state["intent"] = None
        state["tool_result"] = None
        state["tool_error"] = None
        state["reply"] = (
            "No problem. Send me the updated request again and I will rebuild it from scratch."
        )
        state["action_state"] = "done"
        return state

    # Ambiguous — ask again
    state["reply"] = f"Just to confirm — shall I create this? Please say **yes** or **no**.\n{build_confirmation_summary(state)}"
    state["can_confirm"] = True
    return state


def route_from_confirm(state: ChatState) -> str:
    """Route based on confirmation"""
    if state.get("confirmed"):
        return "tool_node"
    return END


def _is_infeasible_result(payload: Any) -> bool:
    return isinstance(payload, dict) and str(payload.get("status", "")).lower() == "infeasible"


def _infeasible_reply(payload: dict, goal_label: str) -> str:
    feasibility = payload.get("feasibility") if isinstance(payload, dict) else {}
    if not isinstance(feasibility, dict):
        feasibility = {}
    failure = feasibility.get("failure") if isinstance(feasibility, dict) else {}
    if not isinstance(failure, dict):
        failure = {}

    reason = payload.get("message") or failure.get("message") or "This goal is not feasible with your current profile and assumptions."
    return (
        f"{goal_label} is currently not feasible.\n"
        f"Reason: {reason}\n"
        "Try one of these: extend timeline, reduce goal amount, or increase monthly surplus."
    )


# ─── NODE 4: TOOL INVOCATION ───────────────────────────────────────────────

def tool_node(state: ChatState) -> ChatState:
    """
    Call deterministic math functions.
    Only numbers from math engine go to explain layer.
    """
    import asyncio
    from app.services.math.goals import (
        get_retirement_plan,
        one_time_goal,
        compute_recurring_goal,
        save_retirement_plan,
        save_one_time_goal_plan,
        save_recurring_goal_plan,
    )
    from app.services.math.conflict_engine import run_and_save_conflict_engine
    from app.databse import get_db
    from app.models.db import User

    intent = normalize_intent(state["intent"])
    collected = state["collected"]
    user_id = state["user_id"]

    # Create a fresh session
    from app.databse import SessionLocal
    db = SessionLocal()

    try:
        # Fetch user profile
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError("User not found")

        if intent == Intent.RETIREMENT_CREATE:
            # Build Retirement request from collected + user profile
            from app.schemas.user import Retirement

            profile_data = {
                "name": user.full_name,
                "email": user.email,
                "phone_number": user.phone_number,
                "password": "placeholder",
                "marital_status": user.marital_status or "Single",
                "age": user.age or 30,
                "current_income": user.current_income or 500000,
                "income_raise_pct": user.income_raise_pct or 5.0,
                "current_monthly_expenses": collected.get("current_monthly_expenses", user.current_monthly_expenses or 50000),
                "inflation_rate": user.inflation_rate or 6.0,
                "spouse_age": user.spouse_age,
                "spouse_income": user.spouse_income or 0,
                "spouse_income_raise_pct": user.spouse_income_raise_pct or 0,
            }

            retirement_req = Retirement(
                **profile_data,
                retirement_age=int(collected["retirement_age"]),
                post_retirement_expense_pct=collected["post_retirement_expense_pct"],
                post_retirement_return=user.post_retirement_return or 7.0,
                pre_retirement_return=user.pre_retirement_return or 10.0,
                life_expectancy=int(collected["life_expectancy"]),
                annual_post_retirement_income=collected.get("annual_post_retirement_income", 0),
                existing_corpus=collected.get("existing_corpus", 0),
                existing_monthly_sip=collected.get("existing_monthly_sip", 0),
            )

            result = get_retirement_plan(retirement_req)
            save_retirement_plan(db, user_id, result, retirement_req.retirement_age)
            
            # Run conflict engine - handle async
            try:
                loop = asyncio.get_event_loop()
            except RuntimeError:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
            
            loop.run_until_complete(run_and_save_conflict_engine(user_id, db))

        elif intent == Intent.ONETIME_CREATE:
            from app.schemas.goals import OneTimeGoalRequest

            goal_req = OneTimeGoalRequest(
                goal_name=collected["goal_name"],
                goal_amount=collected["goal_amount"],
                years_to_goal=int(collected["years_to_goal"]),
                pre_ret_return=user.pre_retirement_return or 10.0,
                existing_corpus=collected.get("existing_corpus", 0),
                existing_monthly_sip=0.0,
                risk_tolerance="moderate",
            )

            result = one_time_goal(goal_req, user)
            save_one_time_goal_plan(db, user_id, result)
            
            # Run conflict engine
            try:
                loop = asyncio.get_event_loop()
            except RuntimeError:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
            
            loop.run_until_complete(run_and_save_conflict_engine(user_id, db))

        elif intent == Intent.RECURRING_CREATE:
            from app.schemas.goals import RecurringGoalRequest

            goal_req = RecurringGoalRequest(
                goal_name=collected["goal_name"],
                current_cost=collected["current_cost"],
                years_to_first=int(collected["years_to_first"]),
                frequency_years=int(collected["frequency_years"]),
                num_occurrences=int(collected["num_occurrences"]),
                goal_inflation_pct=collected.get("goal_inflation_pct", 6.0),
                expected_return_pct=user.pre_retirement_return or 10.0,
                income_raise_pct=user.income_raise_pct or 5.0,
                monthly_income=user.current_income / 12 if user.current_income else 40000,
                monthly_expenses=user.current_monthly_expenses or 50000,
                existing_corpus=collected.get("existing_corpus", 0),
            )

            result = compute_recurring_goal(goal_req)
            save_recurring_goal_plan(db, user_id, result)
            
            # Run conflict engine
            try:
                loop = asyncio.get_event_loop()
            except RuntimeError:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
            
            loop.run_until_complete(run_and_save_conflict_engine(user_id, db))

        elif intent == Intent.SCENARIO_SIMULATE:
            # For scenario, we re-fetch the retirement plan and modify one param
            from app.services.math.goals import get_retirement_plan
            from app.models.db import RetirementPlan
            import json

            plan_row = (
                db.query(RetirementPlan)
                .filter(RetirementPlan.user_id == user_id, RetirementPlan.is_active == True)
                .order_by(RetirementPlan.created_at.desc())
                .first()
            )

            if not plan_row:
                raise ValueError("No existing retirement plan to simulate")

            plan_data = json.loads(plan_row.plan_data)
            if not isinstance(plan_data, dict):
                raise ValueError("Existing retirement plan data is invalid. Please create a fresh retirement plan and retry scenario simulation.")

            # Create modified retirement request
            from app.schemas.user import Retirement

            # Extract original values and apply change
            param_name = collected["changed_param"]
            new_value = collected["new_value"]

            profile_data = {
                "name": user.full_name,
                "email": user.email,
                "phone_number": user.phone_number,
                "password": "placeholder",
                "marital_status": user.marital_status or "Single",
                "age": user.age or 30,
                "current_income": user.current_income or 500000,
                "income_raise_pct": user.income_raise_pct or 5.0,
                "current_monthly_expenses": (
                    new_value if param_name == "current_monthly_expenses"
                    else user.current_monthly_expenses or 50000
                ),
                "inflation_rate": user.inflation_rate or 6.0,
                "spouse_age": user.spouse_age,
                "spouse_income": user.spouse_income or 0,
                "spouse_income_raise_pct": user.spouse_income_raise_pct or 0,
            }

            retirement_req = Retirement(
                **profile_data,
                retirement_age=(
                    int(new_value) if param_name == "retirement_age"
                    else plan_data.get("retirement_age", 60)
                ),
                post_retirement_expense_pct=(
                    new_value if param_name == "post_retirement_expense_pct"
                    else plan_data.get("post_retirement_expense_pct", 75)
                ),
                post_retirement_return=user.post_retirement_return or 7.0,
                pre_retirement_return=user.pre_retirement_return or 10.0,
                life_expectancy=(
                    int(new_value) if param_name == "life_expectancy"
                    else plan_data.get("life_expectancy", 85)
                ),
                annual_post_retirement_income=plan_data.get("annual_post_retirement_income", 0),
                existing_corpus=plan_data.get("existing_corpus", 0),
                existing_monthly_sip=plan_data.get("existing_monthly_sip", 0),
            )

            new_plan = get_retirement_plan(retirement_req)
            if not isinstance(new_plan, dict):
                raise ValueError("Scenario simulation returned invalid output. Please retry.")

            if _is_infeasible_result(new_plan):
                result = {
                    "status": "infeasible",
                    "changed_param": param_name,
                    "new_value": new_value,
                    "message": new_plan.get("message") or "This retirement scenario is not feasible.",
                    "feasibility": new_plan.get("feasibility") or {},
                }
            else:
                # Compute delta vs original using nested corpus objects
                orig_corpus = (plan_data.get("corpus") or {}).get("corpus_required", 0)
                new_corpus = (new_plan.get("corpus") or {}).get("corpus_required", 0)
                delta = new_corpus - orig_corpus

                result = {
                    "status": "feasible",
                    "original_corpus": orig_corpus,
                    "new_corpus": new_corpus,
                    "delta": delta,
                    "delta_pct": (delta / orig_corpus * 100) if orig_corpus > 0 else 0,
                    "changed_param": param_name,
                    "new_value": new_value,
                    "message": f"Changing {param_name} to {new_value}",
                }

        else:
            result = {"error": f"No tool for intent {intent}"}

        state["tool_result"] = result
        state["tool_error"] = None

    except Exception as e:
        state["tool_error"] = str(e)
        state["tool_result"] = None
        state["reply"] = f"❌ Error: {str(e)}"
        state["action_state"] = "done"
        logger.error(f"Tool error: {e}")
    
    finally:
        db.close()

    return state


def route_from_tool(state: ChatState) -> str:
    """Route based on tool result"""
    if state.get("tool_error"):
        return "error_node"
    return "explain_node"


# ─── NODE 5: EXPLANATION ───────────────────────────────────────────────────

def explain_node(state: ChatState) -> ChatState:
    """
    Generate AI explanation from computed payload.
    AI reads numbers only, cannot alter them.
    """
    from app.databse import SessionLocal
    from app.models.db import ConflictResults, GoalPlan, OneTimeGoalPlan, RecurringGoalPlan, RetirementPlan, User

    intent = normalize_intent(state["intent"])
    db = SessionLocal()
    user_id = state["user_id"]

    try:
        if intent == Intent.RETIREMENT_EXPLAIN:
            # Fetch all active retirement plans
            plan_rows = (
                db.query(RetirementPlan)
                .filter(RetirementPlan.user_id == user_id, RetirementPlan.is_active == True)
                .order_by(RetirementPlan.created_at.desc())
                .all()
            )
            if not plan_rows:
                reply = "📊 You don't have a retirement plan yet. Would you like to create one?"
            else:
                # Use the most recent plan for explanation
                plan_data = json.loads(plan_rows[0].plan_data)
                reply = explain_retirement_plan_with_ai(plan_data)
                
                # If multiple plans exist, note that
                if len(plan_rows) > 1:
                    reply += f"\n\n📌 *You have {len(plan_rows)} retirement plans in your database.*"

        elif intent == Intent.ONETIME_EXPLAIN:
            # Fetch all active one-time goals
            goal_rows = (
                db.query(OneTimeGoalPlan)
                .filter(OneTimeGoalPlan.user_id == user_id, OneTimeGoalPlan.is_active == True)
                .order_by(OneTimeGoalPlan.created_at.desc())
                .all()
            )
            if not goal_rows:
                reply = "📊 You don't have any one-time goals yet. Would you like to create one?"
            else:
                # Use the most recent goal for detailed explanation
                goal_data = json.loads(goal_rows[0].goal_data)
                reply = explain_one_time_goal_with_ai(goal_data)
                
                # If multiple goals exist, summarize them
                if len(goal_rows) > 1:
                    goals_summary = "\n\n📋 **Your Other One-Time Goals:**\n"
                    for idx, row in enumerate(goal_rows[1:], 1):
                        goals_summary += f"  {idx}. {row.goal_name} - ₹{row.target_amount:,.0f}\n"
                    reply += goals_summary

        elif intent == Intent.RECURRING_EXPLAIN:
            # Fetch all active recurring goals
            goal_rows = (
                db.query(RecurringGoalPlan)
                .filter(RecurringGoalPlan.user_id == user_id, RecurringGoalPlan.is_active == True)
                .order_by(RecurringGoalPlan.created_at.desc())
                .all()
            )
            if not goal_rows:
                reply = "📊 You don't have any recurring goals yet. Would you like to create one?"
            else:
                # Use the most recent goal for detailed explanation
                goal_data = json.loads(goal_rows[0].goal_data)
                reply = explain_recurring_goal_with_ai(goal_data)
                
                # If multiple goals exist, summarize them
                if len(goal_rows) > 1:
                    goals_summary = "\n\n📋 **Your Other Recurring Goals:**\n"
                    for idx, row in enumerate(goal_rows[1:], 1):
                        goals_summary += f"  {idx}. {row.goal_name}\n"
                    reply += goals_summary

        elif intent == Intent.PORTFOLIO_OVERVIEW:
            # Fetch profile and conflict engine result
            profile_row = db.query(User).filter(User.id == user_id).first()
            
            if not profile_row:
                reply = "📊 User profile not found. Please complete your profile first."
            else:
                # Fetch latest conflict engine result
                conflict_row = (
                    db.query(ConflictResults)
                    .filter(ConflictResults.user_id == user_id, ConflictResults.is_latest == True)
                    .first()
                )
                
                if not conflict_row:
                    reply = "📊 Add some goals first, and I'll show you your complete financial picture."
                else:
                    # Build profile overview payload
                    conflict_data = json.loads(conflict_row.result_data)
                    profile_overview = {
                        "profile": {
                            "name": profile_row.full_name,
                            "age": profile_row.age,
                            "marital_status": profile_row.marital_status,
                            "monthly_income": profile_row.current_income / 12 if profile_row.current_income else 0,
                            "monthly_expenses": profile_row.current_monthly_expenses or 0,
                            "inflation_rate": profile_row.inflation_rate or 6.0,
                        },
                        "conflict_result": conflict_data,
                    }
                    # Feed to conflict engine explanation
                    reply = explain_conflict_result(profile_overview)

        elif intent == Intent.SCENARIO_SIMULATE:
            plan_row = (
                db.query(RetirementPlan)
                .filter(RetirementPlan.user_id == user_id, RetirementPlan.is_active == True)
                .order_by(RetirementPlan.created_at.desc())
                .first()
            )

            if not plan_row:
                reply = "📊 You don't have a retirement plan yet. Would you like to create one first?"
            elif state.get("tool_result"):
                delta_info = state["tool_result"]
                if _is_infeasible_result(delta_info):
                    reply = _infeasible_reply(delta_info, "Scenario")
                else:
                    plan_data = json.loads(plan_row.plan_data)
                    scenario_prompt = (
                        "The user ran a retirement scenario simulation. "
                        "Explain the impact of the change using the existing plan and the delta below. "
                        "Focus on what changed and what it means for the user.\n\n"
                        f"Scenario delta:\n{json.dumps(delta_info, indent=2)}"
                    )
                    reply = explain_retirement_plan_with_ai(plan_data, user_question=scenario_prompt)
            else:
                reply = "Could not compute scenario. Please try again."

        elif intent == Intent.RETIREMENT_CREATE and state.get("tool_result"):
            if _is_infeasible_result(state["tool_result"]):
                reply = _infeasible_reply(state["tool_result"], "Retirement goal")
            else:
                reply = explain_retirement_plan_with_ai(state["tool_result"])

        elif intent == Intent.ONETIME_CREATE and state.get("tool_result"):
            if _is_infeasible_result(state["tool_result"]):
                reply = _infeasible_reply(state["tool_result"], "One-time goal")
            else:
                reply = explain_one_time_goal_with_ai(state["tool_result"])

        elif intent == Intent.RECURRING_CREATE and state.get("tool_result"):
            if _is_infeasible_result(state["tool_result"]):
                reply = _infeasible_reply(state["tool_result"], "Recurring goal")
            else:
                reply = explain_recurring_goal_with_ai(state["tool_result"])

        elif state.get("tool_result"):
            reply = "✅ Plan created and saved successfully! You can now explore your goals and scenarios."

        else:
            reply = "I'm not sure how to explain that. Could you rephrase?"

        state["reply"] = reply
        state["action_state"] = "done"
        state["can_confirm"] = False

    except Exception as e:
        state["reply"] = f"Error generating explanation: {str(e)}"
        state["action_state"] = "done"
        state["can_confirm"] = False
        logger.error(f"Explain error: {e}")
    
    finally:
        db.close()

    return state


# ─── FALLBACK NODES ────────────────────────────────────────────────────────

def clarify_node(state: ChatState) -> ChatState:
    """Ask user to clarify their intent"""
    state["reply"] = """
I'm not sure what you mean. Could you clarify?

I can help you with:
• **Retirement** planning (create or review)
• **One-time goals** (e.g., buy a car, house down payment)
• **Recurring goals** (e.g., annual vacation, car replacement)
• **Scenarios** ("What if I retire at 55?")
• **Portfolio overview** (complete financial picture)

What would you like?
"""
    state["action_state"] = "done"
    return state


def error_node(state: ChatState) -> ChatState:
    """Handle errors gracefully"""
    error_msg = state.get("tool_error", "Unknown error")
    state["reply"] = f"⚠️ Something went wrong: {error_msg}\n\nPlease try again or rephrase your request."
    state["action_state"] = "done"
    return state


# ─── GRAPH ASSEMBLY ────────────────────────────────────────────────────────

def build_graph():
    """Build and compile the LangGraph state machine"""
    graph = StateGraph(ChatState)

    # Add nodes
    graph.add_node("entry_node", lambda state: state)
    graph.add_node("intent_node", intent_node)
    graph.add_node("slot_node", slot_node)
    graph.add_node("confirm_node", confirm_node)
    graph.add_node("tool_node", tool_node)
    graph.add_node("explain_node", explain_node)
    graph.add_node("clarify_node", clarify_node)
    graph.add_node("error_node", error_node)

    # Set entry point
    graph.set_entry_point("entry_node")

    graph.add_conditional_edges(
        "entry_node",
        route_from_entry,
        {
            "intent_node": "intent_node",
            "slot_node": "slot_node",
            "confirm_node": "confirm_node",
        },
    )

    # Add edges with conditional routing
    graph.add_conditional_edges(
        "intent_node",
        route_from_intent,
        {
            "slot_node": "slot_node",
            "explain_node": "explain_node",
            "clarify_node": "clarify_node",
        },
    )

    graph.add_conditional_edges(
        "slot_node",
        route_from_slot,
        {
            END: END,
        },
    )

    graph.add_conditional_edges(
        "confirm_node",
        route_from_confirm,
        {
            "tool_node": "tool_node",
            END: END,
        },
    )

    graph.add_conditional_edges(
        "tool_node",
        route_from_tool,
        {
            "explain_node": "explain_node",
            "error_node": "error_node",
        },
    )

    # Terminal nodes
    graph.add_edge("explain_node", END)
    graph.add_edge("clarify_node", END)
    graph.add_edge("error_node", END)

    # Compile with memory checkpointer for session persistence
    app = graph.compile(checkpointer=MemorySaver())
    return app


# Global graph instance
chatbot_app = build_graph()
