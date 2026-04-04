# Frontend Build PR/TDR for AI Agent

## 1. Document Purpose
This document defines:
- Product Requirements (PR): what frontend must do for this backend.
- Technical Design Requirements (TDR): how frontend should be built.
- A copy-paste prompt for an AI coding agent.

This is based on backend contracts in:
- `Backend/app/main.py`
- `Backend/app/routes/auth.py`
- `Backend/app/routes/user.py`
- `Backend/app/routes/calaculation.py`
- `Backend/app/routes/goals.py`
- `Backend/app/schemas/*.py`
- `Backend/app/services/math/*.py`

## 2. Product Requirements (PR)

### 2.1 Product Goal
Build a production-ready web frontend for a personal financial planning system that supports:
- Authentication and profile onboarding.
- Retirement planning.
- One-time goal planning.
- Recurring goal planning.
- Conflict/corridor analysis dashboard and portfolio visualization.
- Settings and profile updates.

### 2.2 Core User Outcomes
Users must be able to:
1. Register and log in.
2. Enter or update financial profile (income, expenses, spouse, assumptions).
3. Create retirement, one-time, and recurring plans.
4. View feasibility (feasible/infeasible), SIP requirements, and strategy outputs.
5. See all active goals and overall conflict status in one place.
6. Understand recommendations when goals exceed corridor limits.

### 2.3 In Scope
- Responsive web app (desktop and mobile).
- Token-based authenticated UX using backend OAuth login.
- Form-driven workflows with strict validation and inline field errors.
- Goal list, create, delete, and detail views.
- Dashboard + portfolio visualization using conflict engine results.
- AI explanation UX for retirement and one-time goals.

### 2.4 Out of Scope
- Backend schema changes.
- New backend endpoints.
- Admin-only user list management UI.
- Offline mode.

### 2.5 Success Criteria
- End-to-end flows work against current backend without backend changes.
- 0 blocking runtime errors in core routes (`/dashboard`, `/portfolio`, `/plan/*`).
- Frontend handles backend shape variants robustly (no "all zeros" regressions from parsing issues).
- Type-safe build and passing production build.

## 3. Backend Contract Summary (Source of Truth)

## 3.1 Base API
- No `/api/v1` prefix.
- CORS is open in backend (`allow_origins=["*"]`).
- Auth token: Bearer JWT returned by `/auth/login`.

## 3.2 Content-Type Rules (Critical)
- `POST /auth/login`: `application/x-www-form-urlencoded`.
- Most `/user/*` writes: `multipart/form-data`.
- Most `/goals/*` writes: `multipart/form-data`.
- `POST /goals/explain_*`: JSON body.
- `/calculation/*`: mostly JSON, except `/calculation/required_annual_saving` uses form-data.

Do not force global `Content-Type: application/json` in API client.

## 3.3 Endpoint Matrix

### Auth
- `POST /auth/login`
  - Body (form-urlencoded): `username`, `password`
  - Returns: `{ access_token, token_type }`
- `GET /auth/profile` (Bearer)
  - Returns normalized user profile with aliases:
  - `name` and `full_name`
  - `phone` and `phone_number`
  - `current_monthly_expenses` and `monthly_expenses`
  - `savings_floor_pct` (maps from DB `savings_pct`)

### User
- `POST /user/` (form-data)
  - Required: name/email/phone/password + financial profile fields.
  - Returns: `{ user_id, message, user }`
- `PUT /user/{user_id}` (form-data, partial)
  - Supports `savings_pct`, `buffer_pct`, `pre_retirement_return`, `post_retirement_return`, etc.
  - Returns: `{ user_id, message, user }`
- `GET /user/{user_id}` / `DELETE /user/{user_id}` / `GET /user/`
  - Available but not primary UX paths for end-user app.

### Goals and Conflict Engine
- `POST /goals/retirement` (Bearer, form-data)
  - Returns route wrapper: `{ plan, conflict }`
  - `plan` (feasible):
    - `status`, `corpus`, `feasibility`, `glide_path`, `buckets`
  - `plan` (infeasible):
    - `status: infeasible`, `corpus`, `feasibility`, `glide_path: null`, `buckets: null`
  - `conflict`: conflict engine summary object.

- `POST /goals/explain_retirement_plan` (JSON)
  - Body: `{ retirement_plan: dict, user_question?: string }`
  - Returns: `{ explanation }`

- `POST /goals/one_time_goal` (Bearer, form-data)
  - Returns route wrapper: `{ plan, conflict }`
  - `plan` feasible includes:
    - `status`, `goal_name`, `goal_summary`, `sip_plan`, `feasibility`, `allocation`, `glide_path`
  - `plan` infeasible includes:
    - `status`, `goal_name`, `sip_report`, `feasibility_report`, `message`, `suggestion`

- `POST /goals/explain_one_time_goal` (JSON)
  - Body: `{ goal_plan: dict, user_question?: string }`
  - Returns: `{ explanation }`

- `POST /goals/recurring_goal` (Bearer, form-data)
  - Returns route wrapper: `{ plan, conflict }`
  - `plan` includes:
    - `status`, `goal_name`, `goal_summary`, `sip_plan`, `feasibility`, `glide_paths`

- `GET /goals/profile_overview` (Bearer)
  - Returns:
    - `profile`
    - `goals: { retirement, onetime[], recurring[] }`
    - `conflict_summary`
    - `last_updated`

- `GET /goals/retirement` (Bearer)
- `GET /goals/one_time_goal` (Bearer)
- `DELETE /goals/one_time_goal/{goal_id}` (Bearer)
- `GET /goals/recurring_goal` (Bearer)
- `DELETE /goals/recurring_goal/{goal_id}` (Bearer)

### Calculation Utilities
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

## 3.4 Conflict Summary Shape (important for dashboard/portfolio)
Use these fields when present:
- `overall_status`: `all_clear | under_saving | warning | conflict_detected`
- `critical_breach_count`, `warning_breach_count`, `advisory_count`
- `corridor_config`: `ceiling_pct`, `savings_pct`, `buffer_pct`
- `surplus_waterfall`:
  - `funded_goals[]`, `deferred_goals[]`, `funded_count`, `deferred_count`
  - `ceiling_amount`, `buffer_amount`, `remaining_surplus`, etc.
- `deferred_goals[]`
- `yearly_summary[]`: includes `monthly_income`, `monthly_expenses`, `total_sip`, `ceiling_amount`, `savings_amount`, `buffer_amount`, and nested `corridor`
- `recommendations[]`

## 3.5 Compatibility Requirements (must implement)
The frontend adapter layer must gracefully handle variant shapes:
- Route wrappers vs direct plan payloads (`{ plan, conflict }` vs plan-only).
- `profile_overview` wrapped payload vs possible bare conflict object in older deployments.
- Alias keys:
  - `savings_floor_pct` vs `savings_pct`
  - `current_monthly_expenses` vs `monthly_expenses`
  - `onetime` vs `one_time` vs `one_time_goals`
  - `recurring` vs `recurring_goals`
- Numeric parsing must accept numbers and numeric strings safely.

## 4. Functional Requirements by Screen

## 4.1 Public
- `/` landing page with CTA.
- `/register`:
  - full registration form.
  - conditional spouse fields when married.
- `/login`:
  - username=email + password.

## 4.2 Protected Shell
- Auth guard with token check.
- Sidebar/top-nav linking:
  - Dashboard
  - Retirement Plan
  - One-Time Goals
  - Recurring Goals
  - Portfolio
  - Settings

## 4.3 Dashboard
Show at minimum:
- Corridor summary strip:
  - status, monthly income, savings floor amount, buffer amount, goal ceiling amount.
- Explicit cards:
  - savings floor %
  - savings floor amount
  - buffer %
  - buffer amount
- Active goals list/cards loaded from backend.
- Conflict summary and deferred goals.
- Clicking a goal card opens the relevant details page.

## 4.4 Retirement Planner
- Form for retirement inputs.
- Submit to `/goals/retirement`.
- Display plan:
  - corpus summary
  - feasibility summary + yearly trend
  - glide path
  - buckets
- Handle infeasible plan without fake zeros.
- AI explanation panel using `/goals/explain_retirement_plan`.

## 4.5 One-Time Goals
- Create form for one-time goal.
- List all active goals.
- Expand card to show details and feasibility.
- Delete goal.
- AI explanation using `/goals/explain_one_time_goal`.

## 4.6 Recurring Goals
- Create recurring goal form.
- List active recurring goals.
- Show occurrence-wise SIP and glide paths.
- Delete goal.

## 4.7 Portfolio
- Visualize conflict engine output:
  - corridor split
  - surplus waterfall
  - year-wise projection
  - recommendations
- Clear messaging for `all_clear`, `under_saving`, `warning`, `conflict_detected`.

## 4.8 Settings/Profile
- Load from `/auth/profile`.
- Update via `/user/{user_id}`.
- Include corridor controls:
  - `savings_pct`
  - `buffer_pct`
- Persist profile assumptions used in planning.

## 5. Technical Design Requirements (TDR)

## 5.1 Recommended Stack
- Next.js 14 (App Router)
- TypeScript strict mode
- React Hook Form + Zod
- Axios API client
- Zustand (or equivalent) for auth + portfolio state
- Recharts for charts
- Tailwind for styling

## 5.2 Frontend Architecture
- `lib/api/client.ts`: Axios instance, token interceptor, retry policy for 401.
- `lib/api/services.ts`: endpoint functions with request encoding and response normalization.
- `lib/utils/normalizers.ts`:
  - profile alias normalization
  - goal and conflict shape normalization
  - safe number parsing
- `stores/`:
  - auth store (token + user)
  - profile store
  - portfolio store
- `app/(auth)` and `app/(protected)` route groups.

## 5.3 Data and State Strategy
- Source of truth for aggregate UI: `/goals/profile_overview`.
- On create/delete of goals:
  - optimistic local update optional,
  - then refresh overview to keep dashboard/portfolio consistent.
- Persist auth token and basic profile locally.

## 5.4 Error Handling Requirements
Map backend status codes:
- 401: logout/redirect to login, keep original destination.
- 400: show user-actionable message (e.g., profile incomplete).
- 409: registration duplicate email.
- 422: map field-level errors to form controls.
- 500: toast + retry CTA.

## 5.5 Validation Rules (frontend mirrors backend)
- Registration:
  - age 18-80
  - income > 0
  - monthly expenses > 0
  - spouse age required if married
- Retirement:
  - retirement_age 35-80
  - life_expectancy 60-100 and > retirement age
- One-time:
  - years_to_goal > 0
  - risk_tolerance in `low|moderate|high`
- Recurring:
  - years_to_first >= 0
  - frequency_years >= 1
  - num_occurrences >= 1

## 5.6 Security Requirements
- Store token securely (prefer httpOnly cookie if backend supports; else local storage with strict handling).
- Attach `Authorization: Bearer ...` only for protected endpoints.
- Never log token or full PII in console.

## 5.7 Performance Requirements
- Route-level code splitting for heavy planner pages.
- Skeleton loading states.
- Memoized chart transforms.
- Avoid blocking render on non-critical requests.

## 5.8 Accessibility Requirements
- Keyboard-navigable forms and dialogs.
- Proper labels and error associations.
- Color contrast for status badges/charts.

## 5.9 Test Requirements
- Unit tests:
  - normalizers and number parsing
  - form schema validation
- Integration tests:
  - auth flow
  - create one plan of each type
  - dashboard renders active goals and corridor metrics
- E2E (Playwright preferred):
  - register -> login -> create plans -> verify dashboard/portfolio

## 6. Delivery Plan (Milestones)

### Milestone 1: Foundation
- App shell, auth flow, API client, token handling, error framework.

### Milestone 2: Profile and Settings
- Profile load/update, onboarding-ready forms.

### Milestone 3: Planning Flows
- Retirement + one-time + recurring create/list/delete/detail pages.

### Milestone 4: Dashboard and Portfolio
- Corridor, conflict summaries, recommendations, charts, active goals.

### Milestone 5: Hardening
- Normalization edge cases, empty states, test suite, build/typecheck clean.

## 7. Definition of Done
A build is done when:
1. All required pages are implemented and routed.
2. Authenticated flows work end-to-end against backend.
3. `npm run typecheck` passes.
4. `npm run build` passes.
5. No known zero-value rendering bug from parsing/backend alias mismatch.
6. Tests for core flows pass.

## 8. Copy-Paste Prompt for AI Agent
Use the following prompt as-is:

```text
You are a senior frontend engineer. Build a production-ready Next.js 14 + TypeScript frontend for the existing FastAPI backend in this repo.

Goal:
Implement complete user-facing financial planning app flows: auth, profile/settings, retirement planning, one-time goals, recurring goals, dashboard, and portfolio/conflict visualization.

Hard constraints:
1) Do NOT modify backend code.
2) Integrate exactly with existing backend routes and payload formats.
3) Use strict TypeScript, robust runtime normalization, and resilient error handling.
4) Ensure `npm run typecheck` and `npm run build` pass.

Backend contract requirements:
- Base path has NO /api/v1 prefix.
- Auth:
  - POST /auth/login (application/x-www-form-urlencoded: username, password) => {access_token, token_type}
  - GET /auth/profile (Bearer)
- User:
  - POST /user/ (multipart/form-data)
  - PUT /user/{user_id} (multipart/form-data, partial)
- Goals:
  - POST /goals/retirement (multipart/form-data, Bearer) => wrapper { plan, conflict }
  - POST /goals/one_time_goal (multipart/form-data, Bearer) => wrapper { plan, conflict }
  - POST /goals/recurring_goal (multipart/form-data, Bearer) => wrapper { plan, conflict }
  - POST /goals/explain_retirement_plan (JSON)
  - POST /goals/explain_one_time_goal (JSON)
  - GET /goals/profile_overview (Bearer) => { profile, goals, conflict_summary, last_updated }
  - GET /goals/retirement
  - GET /goals/one_time_goal
  - DELETE /goals/one_time_goal/{goal_id}
  - GET /goals/recurring_goal
  - DELETE /goals/recurring_goal/{goal_id}
- Calculation endpoints exist under /calculation/* (mostly JSON; required_annual_saving uses form-data).

Critical normalization requirements:
- Handle wrappers and variant shapes gracefully.
- Handle alias keys such as:
  - savings_floor_pct vs savings_pct
  - current_monthly_expenses vs monthly_expenses
  - goals.onetime vs goals.one_time
- Parse numeric strings safely and prevent zero-fallback regressions.

Required screens:
- Public: landing, register, login
- Protected: dashboard, retirement page, one-time goals page, recurring goals page, portfolio page, settings page

Required behavior:
- Dashboard must show savings floor %/amount and buffer %/amount.
- Dashboard must list all active goals from backend.
- Goal cards must deep-link to full detail page and auto-expand the target goal.
- Portfolio must visualize corridor split, waterfall, and recommendations.
- Retirement and goal pages must display feasible/infeasible details correctly.

Implementation instructions:
- Use App Router route groups for auth/protected sections.
- Build an API layer that sends correct content-type per endpoint (do not force global JSON content-type).
- Add form validation with clear per-field errors.
- Add loading, empty, and error states for all data views.
- Keep code modular: api client, services, normalizers, stores, pages, components.

Testing and verification:
- Add/maintain tests for normalizers and critical UI flows.
- Run and ensure success:
  - npm run typecheck
  - npm run build

Deliverables in PR:
1) Implemented frontend code.
2) Updated README with run/setup instructions.
3) Short architecture note explaining API normalization strategy and known backend shape variants.
4) Evidence of passing typecheck/build.
```

## 9. Optional Add-On Prompt (for stricter output)
If your AI agent supports role constraints, prepend this:

```text
Before writing code:
- First generate a concise implementation plan by feature milestones.
- Then implement milestone-by-milestone.
- After each milestone, run typecheck and fix all errors before moving on.
- Never assume backend response shape is fixed; always normalize with safe fallbacks.
```
