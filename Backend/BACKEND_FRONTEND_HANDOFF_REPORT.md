# GoalPath Backend Handoff Report (Frontend-Focused)

## 1) What this backend is

This backend is a FastAPI service for financial planning. It supports:
- User onboarding/profile management
- JWT login authentication
- Financial utility calculations
- Goal planning for:
  - retirement
  - one-time goals
  - recurring goals
- Conflict analysis across all active goals (corridor + priority waterfall)
- AI explanation endpoints that convert plan JSON into human-readable explanation

Core idea:
- Math is deterministic in `app/services/math/*`
- AI explanation is separate and should not change math outputs

---

## 2) Tech stack and runtime

- Python 3.11
- FastAPI + Uvicorn
- SQLAlchemy ORM
- PostgreSQL/Supabase (also supports sqlite URL)
- Pydantic models for validation
- JWT using `authlib`
- Password hashing with `passlib` + `bcrypt`
- OpenAI SDK pointed at HuggingFace router for explanation endpoints
- Pytest (unit + integration + e2e style tests)

---

## 3) Environment variables used

From `.env` keys referenced in code:
- `SQLALCHEMY_DATABASE_URL`
- `SECRET_KEY`
- `ALGORITHM`
- `ACCESS_TOKEN_EXPIRE_MINUTES`
- `HF_TOKEN`

---

## 4) API quick summary (what frontend should call)

### Auth endpoints
- `POST /auth/login` (form-data) -> returns bearer token
- `GET /auth/profile` (Bearer token required) -> returns authenticated user profile

### User endpoints
- `POST /user/` (form-data) -> creates user
- `GET /user/{user_id}`
- `PUT /user/{user_id}` (form-data partial update)
- `DELETE /user/{user_id}`
- `GET /user/` (list users)

### Calculation endpoints
- `GET /calculation/`
- `POST /calculation/future_value_goal` (JSON)
- `POST /calculation/blended_return` (JSON)
- `POST /calculation/required_annual_saving` (form-data)
- `POST /calculation/suggest_allocation` (JSON)
- `POST /calculation/check_feasibility` (JSON)
- `POST /calculation/check_rebalancing` (JSON)
- `POST /calculation/starting-sip` (JSON)
- `POST /calculation/glide-path` (JSON)
- `POST /calculation/drift` (JSON)

### Goal endpoints (all major goal creation endpoints require Bearer token)
- `POST /goals/retirement` (form-data, Bearer)
- `POST /goals/one_time_goal` (form-data, Bearer)
- `POST /goals/recurring_goal` (form-data, Bearer)
- `POST /goals/explain_retirement_plan` (JSON)
- `POST /goals/explain_one_time_goal` (JSON)
- `POST /goals/explain_recurring_goal` (JSON)
- `GET /goals/profile_overview` (Bearer)
- `GET /goals/retirement` (Bearer)
- `GET /goals/one_time_goal` (Bearer)
- `DELETE /goals/one_time_goal/{goal_id}` (Bearer)
- `GET /goals/recurring_goal` (Bearer)
- `DELETE /goals/recurring_goal/{goal_id}` (Bearer)

---

## 5) Auth contract for frontend

### Login request
`POST /auth/login`
Content-Type: `application/x-www-form-urlencoded`

Sample:
```http
username=smoke_test_e2e@example.com&password=SecurePass123!
```

Response:
```json
{
  "access_token": "<jwt>",
  "token_type": "bearer"
}
```

### Authenticated calls
Send:
```http
Authorization: Bearer <access_token>
```

---

## 6) File-by-file documentation

## Top-level files

### `Readme.md`
Purpose:
- High-level architecture and conceptual docs.
- Useful overview, but not fully aligned with current code in some endpoint paths/response shapes.

Inputs/outputs:
- No runtime execution.

### `requirements.txt`
Purpose:
- Python package dependencies.

### `pytest.ini`
Purpose:
- pytest option: `--import-mode=importlib`.

### `.dockerignore`
Purpose:
- Docker build hygiene.

### `.env`
Purpose:
- Runtime configuration (secret + DB + token keys).

### `__init__.py`
Purpose:
- Package marker; empty.

---

## `app/`

### `app/main.py`
Purpose:
- FastAPI app bootstrap.
- Adds permissive CORS (`*`).
- Includes routers from auth, user, goals, calculation.
- On startup creates DB tables (`Base.metadata.create_all`).

Functions:
- `startup_event()`
- `read_root()` -> `{"Message": "Welcome to Financial Planning API"}`

Input/Output:
- No direct input models.

---

### `app/databse.py` (note filename typo: databse)
Purpose:
- DB connection setup.
- URL normalization for postgres/supabase.
- Session factory and `get_db()` dependency.

Functions:
- `_running_in_container()`
- `_normalize_database_url(database_url)`
- `_get_database_url()`
- `get_db()` generator dependency

Behavior details:
- Converts `postgres://` to `postgresql://`
- Auto-adds `sslmode=require` for Supabase hosts
- If inside container and DB host is localhost, raises RuntimeError

Expected input:
- env URL from `SQLALCHEMY_DATABASE_URL` (or fallback env names)

Output:
- `engine`, `SessionLocal`, `Base`, dependency generator for routes

---

## `app/models/`

### `app/models/db.py`
Purpose:
- SQLAlchemy ORM models.

Classes/tables:
- `User`
- `RetirementPlan`
- `GoalPlan` (generic table, appears mostly unused by routes)
- `OneTimeGoalPlan`
- `RecurringGoalPlan`
- `ConflictResults`

Input expectations:
- ORM object creation by route/service layers.

Output usage:
- Persisted records returned by SQLAlchemy query operations.

Important fields for frontend understanding:
- `User` stores onboarding + financial profile + conflict corridor config (`savings_pct`, `buffer_pct`)
- `RetirementPlan.plan_data` stores full JSON string plan
- `OneTimeGoalPlan.goal_data` and `RecurringGoalPlan.goal_data` store full JSON string plans
- `ConflictResults.result_data` stores full conflict output JSON and marks latest via `is_latest`

---

## `app/routes/`

### `app/routes/auth.py`
Purpose:
- Login and authenticated profile retrieval.

Functions/endpoints:
- `POST /auth/login`
  - Input type: form-data (`username`, `password`)
  - Auth: none
  - Output: token object
- `GET /auth/profile`
  - Auth: required
  - Output: user profile object with aliases (`name` + `full_name`, `phone` + `phone_number`, etc.)

Internal helpers:
- `decode_token()`
- `get_current_user()` (core auth dependency)

Sample response (`GET /auth/profile`):
```json
{
  "id": "<uuid>",
  "name": "Smoke Test User E2E",
  "full_name": "Smoke Test User E2E",
  "email": "smoke_test_e2e@example.com",
  "phone": "9876543222",
  "phone_number": "9876543222",
  "marital_status": "Married",
  "age": 35,
  "current_income": 1200000.0,
  "income_raise_pct": 8.0,
  "current_monthly_expenses": 50000.0,
  "monthly_expenses": 50000.0,
  "inflation_rate": 6.0,
  "spouse_age": 33,
  "spouse_income": 600000.0,
  "spouse_income_raise_pct": 7.0,
  "pre_retirement_return": 10.0,
  "post_retirement_return": 7.0,
  "savings_floor_pct": 20.0,
  "buffer_pct": 10.0,
  "onboarding_complete": true,
  "onboarding_step": 1
}
```

---

### `app/routes/user.py`
Purpose:
- User CRUD endpoints.

Shared serializer:
- `_serialize_user(user)`

Endpoints:
- `POST /user/` (status 201)
  - Input: form-data
  - Required fields:
    - `name`, `email`, `phone_number(10 chars)`, `password(min6)`
    - `marital_status`, `age`, `current_income`, `income_raise_pct`
    - `current_monthly_expenses`, `inflation_rate`
  - Optional spouse fields:
    - `spouse_age`, `spouse_income`, `spouse_income_raise_pct`
  - Response:
```json
{
  "user_id": "<uuid>",
  "message": "User created successfully",
  "user": {"...serialized user...": "..."}
}
```

- `GET /user/{user_id}`
  - Response:
```json
{
  "user_id": "<uuid>",
  "user": {"...serialized user...": "..."}
}
```

- `PUT /user/{user_id}`
  - Input: form-data partial update
  - Accepts profile updates + `full_name`, `phone_number`, `pre_retirement_return`, `post_retirement_return`, `savings_pct`, `buffer_pct`
  - Response similar to create

- `DELETE /user/{user_id}`
  - Output: success message

- `GET /user/`
  - Output: list of serialized users

Error behavior:
- 409 on duplicate email during create
- 404 for missing user id in get/update/delete

---

### `app/routes/calaculation.py` (filename typo: calaculation)
Purpose:
- Expose stateless financial utility functions.

Endpoints + inputs:
- `POST /calculation/future_value_goal`
  - JSON schema: `FutureValue`
  - Fields: `principal`, `infation_rate` (typo key), `years`

Sample:
```json
{
  "principal": 1000000,
  "infation_rate": 6.0,
  "years": 10
}
```

Response:
```json
{
  "future_value": 1790847.6965428544
}
```

- `POST /calculation/blended_return`
  - JSON: `equity_pct`, `debt_pct`, `return_equity`, `return_debt`
  - Response key: `blended_return`

- `POST /calculation/required_annual_saving`
  - form-data: `future_value`, `return_rate`, `years`, `current_savings`
  - Response key: `required_annual_saving`

- `POST /calculation/suggest_allocation`
  - JSON: `years`, `risk`
  - Response keys: `equity_allocation`, `debt_allocation`

- `POST /calculation/check_feasibility`
  - JSON: `starting_monthly_sip`, `annual_step_up_pct`, `monthly_income`, `income_raise_pct`, `monthly_expenses`, `years_to_goal`, `existing_monthly_sip`, `savings_cap_pct`
  - Response: feasibility summary + yearly details

- `POST /calculation/check_rebalancing`
  - JSON: `planned_alloc` map, `current_alloc` map, `threshold`

- `POST /calculation/starting-sip`
  - JSON: `goal_amount`, `years_to_goal`, `pre_ret_return`, `inflation_rate`, `income_raise_pct`

- `POST /calculation/glide-path`
  - JSON: `current_age`, `goal_age`, `start_equity_percent`, `end_equity_percent`

- `POST /calculation/drift`
  - JSON: `current_equity_value`, `current_debt_value`, `current_year_target_ratio`

---

### `app/routes/goals.py`
Purpose:
- Main financial planning endpoints (retirement, one-time, recurring)
- profile aggregation endpoints
- AI explanation endpoints
- triggers conflict engine after plan saves

#### 1) `POST /goals/retirement`
Input type: form-data
Auth: Bearer required

Required fields:
- `retirement_age`
- `post_retirement_expense_pct`
- `life_expectancy`

Optional (have defaults in endpoint):
- `post_retirement_return`, `pre_retirement_return`
- `annual_post_retirement_income`, `existing_corpus`, `existing_monthly_sip`, `sip_raise_pct`
- profile override fields (`marital_status`, `age`, `current_income`, etc.)

Response shape (actual route):
```json
{
  "plan": {
    "status": "feasible|infeasible",
    "corpus": {"...": "..."},
    "feasibility": {"...": "..."},
    "glide_path": {"...": "..."},
    "buckets": {"...": "..."}
  },
  "conflict": {
    "overall_status": "all_clear|warning|conflict_detected|under_saving",
    "yearly_summary": []
  }
}
```

#### 2) `POST /goals/one_time_goal`
Input type: form-data
Auth: Bearer required

Fields:
- `goal_name`
- `goal_amount`
- `years_to_goal`
- `pre_ret_return` (default 10)
- `existing_corpus` (default 0)
- `existing_monthly_sip` (default 0)
- `risk_tolerance` (default "moderate")

Response shape (actual route):
```json
{
  "plan": {
    "status": "feasible|infeasible",
    "goal_name": "Buy a Car",
    "goal_summary": {"...": "..."},
    "sip_plan": {"...": "..."},
    "feasibility": {"...": "..."}
  },
  "conflict": {
    "overall_status": "..."
  }
}
```

#### 3) `POST /goals/recurring_goal`
Input type: form-data
Auth: Bearer required

Fields:
- `goal_name`
- `current_cost`
- `years_to_first`
- `frequency_years`
- `num_occurrences`
- `goal_inflation_pct` (default 6)
- `expected_return_pct` (default 10)
- `existing_corpus` (default 0)

Expected design response should mirror retirement/one-time: `{ "plan": ..., "conflict": ... }`.

Important code note:
- Current function computes/saves conflict but does not return the payload from endpoint (missing explicit return at end).

#### 4) Explanation endpoints
- `POST /goals/explain_retirement_plan`
- `POST /goals/explain_one_time_goal`
- `POST /goals/explain_recurring_goal`

Input type: JSON
Output:
```json
{
  "explanation": "<natural language explanation>"
}
```

#### 5) Portfolio retrieval endpoints
- `GET /goals/profile_overview`
  - returns merged profile + goals + latest conflict summary + timestamp
- `GET /goals/retirement`
  - returns latest retirement plan object or `null`
- `GET /goals/one_time_goal`
  - returns active one-time goal list (each with `goal_id`)
- `DELETE /goals/one_time_goal/{goal_id}`
  - soft delete (`is_active=False`)
- `GET /goals/recurring_goal`
  - returns active recurring goal list
- `DELETE /goals/recurring_goal/{goal_id}`
  - soft delete

Sample `GET /goals/profile_overview` response (shape):
```json
{
  "profile": {"...": "..."},
  "goals": {
    "retirement": {"...": "..."},
    "onetime": [{"goal_id": "..."}],
    "recurring": [{"goal_id": "..."}]
  },
  "conflict_summary": {"overall_status": "all_clear"},
  "last_updated": "2026-03-28T12:34:56.123456"
}
```

---

## `app/schemas/`

### `app/schemas/user.py`
Purpose:
- Request models for user + retirement + explanation payloads.

Classes:
- `UserBase`
- `CreateUser` (validator: if married, `spouse_age` required)
- `UpdateUser` (same spouse validation rule when marital status is married)
- `UserOut`
- `Retirement` (extends create-user fields and retirement parameters)
  - computed properties:
    - `years_to_retirement`
    - `retirement_duration`
- `RetirementRequest` (standalone retirement-only schema)
- `BucketAllocation`
- `ExplainRetirementRequest` (`retirement_plan`, `user_question?`)
- `ExplainOneTimeGoalRequest` (`goal_plan`, `user_question?`)
- `ChatState`

Input expectations:
- strong validation ranges (ages, percentages, positive amounts)

Important note:
- `ExplainRecurringGoalRequest` is imported in goals route but this class is not present here.

---

### `app/schemas/goals.py`
Purpose:
- Goal-specific payload models.

Classes:
- `OneTimeGoalRequest`
  - fields: `goal_name`, `goal_amount`, `years_to_goal`, `pre_ret_return`, `existing_corpus`, `existing_monthly_sip`, `risk_tolerance`
- `RecurringGoalRequest`
  - fields: `goal_name`, `current_cost`, `years_to_first`, `frequency_years`, `num_occurrences`, `goal_inflation_pct`, `expected_return_pct`, `income_raise_pct`, `monthly_income`, `monthly_expenses`, `existing_corpus`
  - validator: `monthly_expenses` cannot exceed `monthly_income`

---

### `app/schemas/calculation.py`
Purpose:
- Request schemas for `/calculation` and conflict engine input.

Classes:
- `FutureValue`
- `BlendedReturn`
- `RequiredAnnualSavings`
- `SuggestedAllocation`
- `CheckFeasibilityRequest` (validator: income positive and expenses < income)
- `CheckRebalancing`
- `SIPRequest`
- `GlidePathRequest` (validator: goal_age > current_age, start_equity >= end_equity)
- `RebalanceRequest`
- `ConflictEngineRequest` (computes `ceiling_pct = 100 - (savings_pct + buffer_pct)`)

---

## `app/services/`

### `app/services/auth.py`
Purpose:
- JWT create/verify.

Functions:
- `create_access_token(data: dict)`
- `verify_tokens(token: str)`
- `verufy_tokens(token: str)` (typo alias calling verify_tokens)

Input:
- `data` includes at least `sub`
- JWT token string

Output:
- encoded token string
- token subject (`sub`) on verify

Error behavior:
- raises HTTP 401 on invalid token/claims

---

### `app/services/utils.py`
Purpose:
- password hashing helpers.

Functions:
- `hash_password(password) -> str`
- `verify_password(plain_password, hashed_password) -> bool`
- local `get_db()` stub exists here but app routes use database dependency from `app/databse.py`

---

### `app/services/one_time_agent_prompt.txt`
Purpose:
- System prompt and initial prompts for one-time goal explanation agent.
- Enforces numeric containment (copy exact values from payload, avoid recomputation).

### `app/services/retirement_agent_prompt.txt`
Purpose:
- System + initial prompt for retirement explanation agent.
- Includes strict rules not to recompute numbers.

### `app/services/recurring_agent_prompt.txt`
Purpose:
- Prompt content for recurring goal explanations.
- Contains reusable blocks and recurring-specific explanation instructions.

---

## `app/services/math/`

### `app/services/math/calculation.py`
Purpose:
- Stateless calculation functions used by calculation route and goal services.

Functions and expected I/O:
- `future_value_goal(data: FutureValue) -> {"future_value": float}`
- `blended_return(data: BlendedReturn) -> {"blended_return": float}`
- `required_annual_saving(data: RequiredAnnualSavings) -> {"required_annual_saving": float}`
- `suggest_allocation(data: SuggestedAllocation) -> {"equity_allocation": int, "debt_allocation": int}`
- `check_feasibility(data: CheckFeasibilityRequest) -> detailed dict`
  - includes `feasible`, `status`, `breach_count`, `peak_savings_ratio`, `yearly_summary`, etc.
- `check_rebalancing(data: CheckRebalancing)`
- `calculate_sip(data: SIPRequest)`
  - returns `goal_at_target_date`, `starting_monthly_sip`, `annual_step_up_pct`, etc.
- `calculate_glide_path(data: GlidePathRequest)`
  - returns year-wise equity/debt table
- `check_portfolio_rebalance(data: RebalanceRequest)`
  - implements 5/25 rebalance logic

Sample input/output for `/calculation/check_feasibility`:

Input:
```json
{
  "starting_monthly_sip": 30000,
  "annual_step_up_pct": 0.94,
  "monthly_income": 200000,
  "income_raise_pct": 7.0,
  "monthly_expenses": 50000,
  "years_to_goal": 5,
  "existing_monthly_sip": 0,
  "savings_cap_pct": 50
}
```

Output (shape):
```json
{
  "feasible": true,
  "status": "feasible",
  "monthly_shortfall": 0.0,
  "breach_count": 0,
  "first_breach_year": null,
  "peak_savings_ratio": 20.0,
  "yearly_summary": [
    {
      "year": 1,
      "monthly_income": 200000.0,
      "monthly_expenses": 50000.0,
      "disposable_income": 150000.0,
      "this_goal_sip": 30000.0,
      "existing_sip": 0.0,
      "total_sip": 30000.0,
      "savings_ratio_pct": 20.0,
      "cap_pct": 50.0,
      "within_cap": true
    }
  ],
  "breach_years": [],
  "inputs": {"...": "..."}
}
```

---

### `app/services/math/goals.py`
Purpose:
- Main deterministic goal-planning engine.

Major functions:

Retirement:
- `check_feasibility_retirement(r, additional_monthly_sip)`
- `compute_retirement_corpus(r)`
- `compute_bucket_strategy(...)`
- `compute_pre_retirement_glide_path(r, monthly_sip)`
- `get_retirement_plan(r)` (orchestrator)
- `save_retirement_plan(db, user_id, plan, retirement_age)`

One-time:
- `one_time_goal(data, user)` (orchestrator)
- `_build_goal_feasibility_payload(plan)`
- `_build_goal_base_payload(plan)`
- `build_onetime_goal_ai_payload(plan)`
- `save_one_time_goal_plan(db, user_id, plan)`

Recurring:
- `compute_occurrence_costs(data)`
- `compute_sip_for_occurrence(...)`
- `apply_existing_corpus(...)`
- `compute_recurring_goal(data)`
- `build_recurring_goal_ai_payload(plan)`
- `save_recurring_goal_plan(db, user_id, plan)`

AI explainers:
- `explain_retirement_plan_with_ai(retirement_plan, user_question?)`
- `explain_one_time_goal_with_ai(goal_plan, user_question?)`
- `explain_recurring_goal_with_ai(goal_plan, user_question?)`

Utility:
- `format_inr(value)`
- `build_ai_payload(plan)`

Typical outputs:
- Retirement plan:
  - `status`
  - `corpus` (required corpus + SIP figures)
  - `feasibility`
  - `glide_path`
  - `buckets`
- One-time plan:
  - `status`
  - `goal_summary`
  - `sip_report` + `sip_plan`
  - `feasibility`
  - `allocation`
  - `glide_path`
- Recurring plan:
  - `status`
  - `goal_summary`
  - `sip_plan` (`total_monthly_sip`, `occurrence_plans`)
  - `feasibility`
  - `glide_paths`

---

### `app/services/math/conflict_engine.py`
Purpose:
- Runs conflict analysis across retirement + one-time + recurring goals.
- Applies corridor thresholds and priority waterfall logic.

Core functions:
- horizon extractors:
  - `_extract_retirement_horizon`, `_extract_onetime_horizon`, `_extract_recurring_horizon`
- corridor:
  - `compute_corridor_status(total_sip, disposable, floor_pct, ceiling_pct, buffer_pct)`
- simulation:
  - `compute_max_horizon(data)`
  - `compute_all_goal_sips_for_year(data, year)`
  - `compute_conflict_engine(data)`
- priority/waterfall:
  - `prioritised_goal(data, year)`
  - `compute_surplus_waterfall(data, first_year_summary)`
  - `generate_recommendations(...)`
- DB I/O:
  - `fetch_retirement_plan`, `fetch_onetime_goals`, `fetch_recurring_goals`, `fetch_user_profile`
  - `normalize_goal_priorities`, `fetch_priority_order`
  - `save_conflict_result`
  - `run_and_save_conflict_engine(user_id, db)`

Key output from `run_and_save_conflict_engine`:
- `overall_status`
- breach counts
- `corridor_config`
- `surplus_waterfall` (funded/deferred goals)
- `yearly_summary`
- `recommendations`
- optional `priority_input_required`

---

## `app/utils/`

### `app/utils/log_format.py`
Purpose:
- JSON logging formatter.

Class:
- `JSONFormatter(logging.Formatter)`
  - emits timestamp, level, message
  - merges dictionary log payload into final JSON

---

## `tests/`

### `tests/conftest.py`
Purpose:
- Adds backend path to Python path for imports.

### `tests/test_e2e_smoke.py`
Purpose:
- End-to-end smoke flow:
  - create user
  - login
  - create retirement plan
  - create one-time goals
  - create recurring goal
  - fetch profile overview

Contains reusable sample payloads for frontend testing.

### `tests/integration_test/test_calculations.py`
Purpose:
- Integration coverage for all `/calculation/*` endpoints.
- Shows exact request payload shapes and edge cases.

### `tests/integration_test/test_one_time_goal.py`
Purpose:
- Integration tests for one-time goal endpoint and auth dependency.

### `tests/integration_test/test_retirement.py`
Purpose:
- Integration scenarios for retirement endpoint:
  - feasible and infeasible
  - single/married variants

### `tests/unit_test/test_calculation.py`
Purpose:
- Unit tests for calculation functions (FV, feasibility, allocation, SIP, glide path).

### `tests/unit_test/test_conflict_engine.py`
Purpose:
- Unit tests for conflict engine horizon + empty-goal behavior.

### `tests/unit_test/test_one_time_goal.py`
Purpose:
- Unit tests for one-time goal planner logic.

### `tests/unit_test/test_retirement.py`
Purpose:
- Comprehensive retirement math tests (corpus, feasibility, buckets, glide path).

### `tests/__init__.py`, `tests/unit_test/__init__.py`, `tests/integration_test/__init__.py`
Purpose:
- package markers

---

## 7) Request/response samples frontend can copy

### A) Create user
`POST /user/` (form-data)

Sample form fields:
- `name=Smoke Test User E2E`
- `email=smoke_test_e2e@example.com`
- `phone_number=9876543222`
- `password=SecurePass123!`
- `age=35`
- `marital_status=Married`
- `current_income=1200000`
- `income_raise_pct=8.0`
- `current_monthly_expenses=50000`
- `spouse_age=33`
- `spouse_income=600000`
- `spouse_income_raise_pct=7.0`
- `inflation_rate=6.0`

### B) Login
`POST /auth/login` form-data:
- `username=smoke_test_e2e@example.com`
- `password=SecurePass123!`

### C) Retirement goal
`POST /goals/retirement` (Bearer + form-data)

Sample:
- `retirement_age=60`
- `post_retirement_expense_pct=70.0`
- `post_retirement_return=7.0`
- `pre_retirement_return=10.0`
- `life_expectancy=85`
- `annual_post_retirement_income=0`
- `existing_corpus=500000`
- `existing_monthly_sip=10000`
- `sip_raise_pct=8.0`

Expected response top-level keys:
- `plan`
- `conflict`

### D) One-time goal
`POST /goals/one_time_goal` (Bearer + form-data)

Sample:
- `goal_name=Car Purchase`
- `goal_amount=1500000`
- `years_to_goal=3`
- `pre_ret_return=10.0`
- `existing_corpus=0`
- `existing_monthly_sip=0`
- `risk_tolerance=moderate`

Expected response top-level keys:
- `plan`
- `conflict`

### E) Recurring goal
`POST /goals/recurring_goal` (Bearer + form-data)

Sample:
- `goal_name=International Vacation`
- `current_cost=200000`
- `years_to_first=2`
- `frequency_years=2`
- `num_occurrences=5`
- `goal_inflation_pct=6.0`
- `expected_return_pct=10.0`
- `existing_corpus=0`

Expected design:
- should return `plan` + `conflict`
- current code has missing final return in endpoint function

### F) Profile overview
`GET /goals/profile_overview` with Bearer token

Response:
- `profile`
- `goals` (`retirement`, `onetime`, `recurring`)
- `conflict_summary`
- `last_updated`

---

## 8) Frontend integration notes (important)

1. Content types differ by endpoint:
- Auth login and most create/update endpoints use form-data.
- Utility calc endpoints mostly use JSON, except `required_annual_saving` which expects form-data.

2. Goal creation endpoints are async and DB-backed:
- They trigger conflict engine every time after save.
- Handle potentially larger response payloads.

3. Response-shape consistency:
- In services, plan object has `status` etc.
- In current goals routes for retirement/one-time, top-level response wraps as `{ plan, conflict }`.

4. Soft deletes:
- Goal delete endpoints do not remove rows; set `is_active=False`.

5. IDs:
- Goal retrieval endpoints attach `goal_id` in each returned plan object for frontend actions.

---

## 9) Known code issues and mismatches discovered during audit

These are implementation-level observations useful for frontend expectations and backend follow-up:

1. `POST /goals/recurring_goal` currently has no final `return` statement in endpoint body.
- Effect: may return null/empty response despite successful processing.

2. `ExplainRecurringGoalRequest` is imported/used in goals route but not defined in schemas.
- Effect: import/runtime issues possible depending on execution path.

3. `app/schemas/user.py` imports `langchain_core.messsages` (typo in module name).
- Effect: potential import failure if this branch executes.

4. Several naming typos are present but used consistently:
- `databse.py`
- `calaculation.py`
- schema field `infation_rate`
- function `verufy_tokens`

5. `required_annual_saving` ignores incoming `current_savings` internally (`current_savings = 0` in service).
- Effect: API parameter accepted but not effectively used.

6. Docs/tests and route responses have drift in places.
- Example: integration tests for goal endpoints expect direct `status` at top level, while route returns wrapper `{plan, conflict}` for retirement/one-time.

---

## 10) Practical frontend implementation checklist

- Build a shared API client that supports both JSON and form-data payloads.
- Store and inject bearer token globally after login.
- For goals pages, parse both:
  - wrapper responses (`plan`, `conflict`)
  - direct plan objects (in case endpoint behavior changes/fixes)
- Expect and render:
  - feasible/infeasible states
  - rich nested data (`yearly_summary`, `glide_path`, `buckets`, `surplus_waterfall`)
- Use goal IDs from GET endpoints for delete actions.
- Add robust error handling for 401, 404, 409, 422.

---

## 11) Complete file inventory covered in this report

Top level:
- `__init__.py`
- `.dockerignore`
- `.env` (keys only documented)
- `Readme.md`
- `requirements.txt`
- `pytest.ini`

App files:
- `app/__init__.py`
- `app/main.py`
- `app/databse.py`
- `app/Dockerfile`
- `app/models/__init__.py`
- `app/models/db.py`
- `app/routes/__init__.py`
- `app/routes/auth.py`
- `app/routes/user.py`
- `app/routes/goals.py`
- `app/routes/calaculation.py`
- `app/schemas/__init__.py`
- `app/schemas/user.py`
- `app/schemas/goals.py`
- `app/schemas/calculation.py`
- `app/services/__init__.py`
- `app/services/auth.py`
- `app/services/utils.py`
- `app/services/one_time_agent_prompt.txt`
- `app/services/retirement_agent_prompt.txt`
- `app/services/recurring_agent_prompt.txt`
- `app/services/math/__init__.py`
- `app/services/math/calculation.py`
- `app/services/math/goals.py`
- `app/services/math/conflict_engine.py`
- `app/utils/log_format.py`

Tests:
- `tests/__init__.py`
- `tests/conftest.py`
- `tests/test_e2e_smoke.py`
- `tests/unit_test/__init__.py`
- `tests/unit_test/test_calculation.py`
- `tests/unit_test/test_conflict_engine.py`
- `tests/unit_test/test_one_time_goal.py`
- `tests/unit_test/test_retirement.py`
- `tests/integration_test/__init__.py`
- `tests/integration_test/test_calculations.py`
- `tests/integration_test/test_one_time_goal.py`
- `tests/integration_test/test_retirement.py`

---
