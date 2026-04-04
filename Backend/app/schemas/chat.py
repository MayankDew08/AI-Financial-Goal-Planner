from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from enum import Enum


class Intent(str, Enum):
    """All supported chat intents"""
    RETIREMENT_EXPLAIN   = "retirement_explain"
    RETIREMENT_CREATE    = "retirement_create"
    ONETIME_EXPLAIN      = "onetime_explain"
    ONETIME_CREATE       = "onetime_create"
    RECURRING_EXPLAIN    = "recurring_explain"
    RECURRING_CREATE     = "recurring_create"
    SCENARIO_SIMULATE    = "scenario_simulate"
    PORTFOLIO_OVERVIEW   = "portfolio_overview"
    UNCLEAR              = "unclear"


class ChatRequest(BaseModel):
    """User message to chatbot"""
    message: str = Field(..., description="User's message/question")
    session_id: str = Field(..., description="Unique session identifier")


class ChatResponse(BaseModel):
    """Chatbot response to user"""
    reply: str = Field(..., description="Bot's response text")
    pending_fields: List[str] = Field(default_factory=list, description="Fields still needed from user")
    action_state: str = Field(default="idle", description="State: idle, collecting, confirming, done")
    can_confirm: bool = Field(default=False, description="Whether user can confirm action")
    session_id: str = Field(..., description="Session ID echo")


class Slot:
    """Schema for a single input field"""
    def __init__(
        self,
        name: str,
        type: type,
        prompt: str,
        validator,
        error_msg: str,
    ):
        self.name = name
        self.type = type
        self.prompt = prompt
        self.validator = validator
        self.error_msg = error_msg


# ─── SLOT DEFINITIONS (FROZEN) ──────────────────────────────────────────────

SLOTS: Dict[str, List[Slot]] = {
    Intent.RETIREMENT_CREATE: [
        Slot(
            name      = "retirement_age",
            type      = int,
            prompt    = "At what age do you plan to retire?",
            validator = lambda v: 30 <= int(v) <= 80,
            error_msg = "Retirement age must be between 30 and 80."
        ),
        Slot(
            name      = "current_monthly_expenses",
            type      = float,
            prompt    = "What are your current monthly household expenses in rupees?",
            validator = lambda v: float(v) > 0,
            error_msg = "Monthly expenses must be greater than 0."
        ),
        Slot(
            name      = "post_retirement_expense_pct",
            type      = float,
            prompt    = "After retirement, what percentage of your current expenses do you expect to need? (50–100%, most people say 70–75%)",
            validator = lambda v: 50 <= float(v) <= 100,
            error_msg = "Must be between 50 and 100 percent."
        ),
        Slot(
            name      = "life_expectancy",
            type      = int,
            prompt    = "Up to what age do you want to plan for? (most people use 85–90)",
            validator = lambda v: 60 <= int(v) <= 100,
            error_msg = "Life expectancy must be between 60 and 100."
        ),
        # Optional slots below
        Slot(
            name      = "existing_corpus",
            type      = float,
            prompt    = "Do you have any existing retirement savings? (Enter 0 if none)",
            validator = lambda v: float(v) >= 0,
            error_msg = "Must be 0 or a positive amount."
        ),
        Slot(
            name      = "existing_monthly_sip",
            type      = float,
            prompt    = "Are you already investing a monthly SIP toward retirement? (Enter 0 if none)",
            validator = lambda v: float(v) >= 0,
            error_msg = "Must be 0 or a positive amount."
        ),
        Slot(
            name      = "annual_post_retirement_income",
            type      = float,
            prompt    = "Will you have any income after retirement — pension, rent, etc.? (Enter 0 if none)",
            validator = lambda v: float(v) >= 0,
            error_msg = "Must be 0 or a positive amount."
        ),
    ],

    Intent.ONETIME_CREATE: [
        Slot(
            name      = "goal_name",
            type      = str,
            prompt    = "What would you like to call this goal? (e.g., 'Buy a car', 'Home down payment')",
            validator = lambda v: len(str(v).strip()) > 0,
            error_msg = "Goal name cannot be empty."
        ),
        Slot(
            name      = "goal_amount",
            type      = float,
            prompt    = "What does this goal cost today in rupees?",
            validator = lambda v: float(v) > 0,
            error_msg = "Goal amount must be greater than 0."
        ),
        Slot(
            name      = "years_to_goal",
            type      = int,
            prompt    = "How many years from now do you want to achieve this?",
            validator = lambda v: 1 <= int(v) <= 40,
            error_msg = "Years to goal must be between 1 and 40."
        ),
        # Optional
        Slot(
            name      = "goal_inflation_pct",
            type      = float,
            prompt    = "What inflation rate should we assume for this goal? (default is 6%)",
            validator = lambda v: 0 <= float(v) <= 20,
            error_msg = "Inflation must be between 0 and 20 percent."
        ),
        Slot(
            name      = "existing_corpus",
            type      = float,
            prompt    = "Do you have any existing savings toward this goal? (Enter 0 if none)",
            validator = lambda v: float(v) >= 0,
            error_msg = "Must be 0 or a positive amount."
        ),
    ],

    Intent.RECURRING_CREATE: [
        Slot(
            name      = "goal_name",
            type      = str,
            prompt    = "What is this recurring goal? (e.g., 'Annual Europe trip', 'Car replacement')",
            validator = lambda v: len(str(v).strip()) > 0,
            error_msg = "Goal name cannot be empty."
        ),
        Slot(
            name      = "current_cost",
            type      = float,
            prompt    = "What does one occurrence of this cost today in rupees?",
            validator = lambda v: float(v) > 0,
            error_msg = "Cost must be greater than 0."
        ),
        Slot(
            name      = "years_to_first",
            type      = int,
            prompt    = "How many years until the first occurrence?",
            validator = lambda v: 1 <= int(v) <= 30,
            error_msg = "Must be between 1 and 30 years."
        ),
        Slot(
            name      = "frequency_years",
            type      = int,
            prompt    = "How often does this recur — every how many years? (1 = annual, 2 = every 2 years)",
            validator = lambda v: 1 <= int(v) <= 10,
            error_msg = "Frequency must be between 1 and 10 years."
        ),
        Slot(
            name      = "num_occurrences",
            type      = int,
            prompt    = "How many times total do you want to plan for?",
            validator = lambda v: 1 <= int(v) <= 20,
            error_msg = "Must be between 1 and 20 occurrences."
        ),
        # Optional
        Slot(
            name      = "goal_inflation_pct",
            type      = float,
            prompt    = "What inflation rate for this goal? (default 6%, use 9% for travel)",
            validator = lambda v: 0 <= float(v) <= 20,
            error_msg = "Inflation must be between 0 and 20 percent."
        ),
        Slot(
            name      = "existing_corpus",
            type      = float,
            prompt    = "Any existing savings toward this goal? (Enter 0 if none)",
            validator = lambda v: float(v) >= 0,
            error_msg = "Must be 0 or a positive amount."
        ),
    ],

    Intent.SCENARIO_SIMULATE: [
        Slot(
            name      = "changed_param",
            type      = str,
            prompt    = "Which parameter would you like to change? (retirement_age / current_monthly_expenses / life_expectancy / post_retirement_expense_pct)",
            validator = lambda v: str(v).lower() in ["retirement_age", "current_monthly_expenses", "life_expectancy", "post_retirement_expense_pct"],
            error_msg = "Must be one of: retirement_age, current_monthly_expenses, life_expectancy, post_retirement_expense_pct."
        ),
        Slot(
            name      = "new_value",
            type      = float,
            prompt    = "What is the new value?",
            validator = lambda v: float(v) > 0,
            error_msg = "Value must be greater than 0."
        ),
    ],

    # Explain and overview intents need no slots
    Intent.RETIREMENT_EXPLAIN:  [],
    Intent.ONETIME_EXPLAIN:     [],
    Intent.RECURRING_EXPLAIN:   [],
    Intent.PORTFOLIO_OVERVIEW:  [],
}

# Required slots — always asked
# Optional slots — asked after required slots complete
REQUIRED_SLOTS = {
    Intent.RETIREMENT_CREATE: ["retirement_age", "current_monthly_expenses", "post_retirement_expense_pct", "life_expectancy"],
    Intent.ONETIME_CREATE:    ["goal_name", "goal_amount", "years_to_goal"],
    Intent.RECURRING_CREATE:  ["goal_name", "current_cost", "years_to_first", "frequency_years", "num_occurrences"],
    Intent.SCENARIO_SIMULATE: ["changed_param", "new_value"],
    Intent.RETIREMENT_EXPLAIN:  [],
    Intent.ONETIME_EXPLAIN:     [],
    Intent.RECURRING_EXPLAIN:   [],
    Intent.PORTFOLIO_OVERVIEW:  [],
}

OPTIONAL_SLOTS = {
    Intent.RETIREMENT_CREATE: ["existing_corpus", "existing_monthly_sip", "annual_post_retirement_income"],
    Intent.ONETIME_CREATE:    ["goal_inflation_pct", "existing_corpus"],
    Intent.RECURRING_CREATE:  ["goal_inflation_pct", "existing_corpus"],
    Intent.SCENARIO_SIMULATE: [],
    Intent.RETIREMENT_EXPLAIN:  [],
    Intent.ONETIME_EXPLAIN:     [],
    Intent.RECURRING_EXPLAIN:   [],
    Intent.PORTFOLIO_OVERVIEW:  [],
}
