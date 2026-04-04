# GoalPath Frontend API Contract (Minimum Scope)

This file is intentionally narrow: only what a frontend engineer needs to integrate quickly.

## 1) Backend files the frontend should care about

Primary API behavior:
- `app/routes/auth.py`
- `app/routes/user.py`
- `app/routes/goals.py`
- `app/routes/calaculation.py`

Request/response schema references:
- `app/schemas/user.py`
- `app/schemas/goals.py`
- `app/schemas/calculation.py`

Auth/token behavior:
- `app/services/auth.py`

Notes and real payload examples:
- `tests/integration_test/test_calculations.py`
- `tests/integration_test/test_one_time_goal.py`
- `tests/integration_test/test_retirement.py`
- `tests/test_e2e_smoke.py`

---

## 2) Base URL and auth

- Base URL: your deployed backend host (or local `http://localhost:8000`)
- Auth type: Bearer token (JWT)
- Login endpoint returns token from `POST /auth/login`

Header for protected routes:

```http
Authorization: Bearer <access_token>
```

---

## 3) Endpoint contract table (frontend-facing)

## Auth

| Method | Path | Auth | Content-Type | Request Body | Success Response |
|---|---|---|---|---|---|
| POST | /auth/login | No | form-data | `username`, `password` | `{ access_token, token_type }` |
| GET | /auth/profile | Yes | - | none | user profile object |

## User

| Method | Path | Auth | Content-Type | Request Body | Success Response |
|---|---|---|---|---|---|
| POST | /user/ | No | form-data | create user fields | `{ user_id, message, user }` |
| GET | /user/{user_id} | No | - | none | `{ user_id, user }` |
| PUT | /user/{user_id} | No | form-data | partial update fields | `{ user_id, message, user }` |
| DELETE | /user/{user_id} | No | - | none | `{ user_id, message }` |
| GET | /user/ | No | - | none | `{ users: UserProfile[] }` |

## Calculation

| Method | Path | Auth | Content-Type | Request Body | Success Response |
|---|---|---|---|---|---|
| GET | /calculation/ | No | - | none | `{ Message }` |
| POST | /calculation/future_value_goal | No | JSON | `FutureValueRequest` | `{ future_value }` |
| POST | /calculation/blended_return | No | JSON | `BlendedReturnRequest` | `{ blended_return }` |
| POST | /calculation/required_annual_saving | No | form-data | `RequiredAnnualSavingRequest` | `{ required_annual_saving }` |
| POST | /calculation/suggest_allocation | No | JSON | `SuggestAllocationRequest` | `{ equity_allocation, debt_allocation }` |
| POST | /calculation/check_feasibility | No | JSON | `CheckFeasibilityRequest` | `FeasibilityResponse` |
| POST | /calculation/check_rebalancing | No | JSON | `CheckRebalancingRequest` | `{ needs_rebalancing, deviations }` |
| POST | /calculation/starting-sip | No | JSON | `StartingSipRequest` | `StartingSipResponse` |
| POST | /calculation/glide-path | No | JSON | `GlidePathRequest` | `GlidePathResponse` |
| POST | /calculation/drift | No | JSON | `DriftRequest` | `DriftResponse` |

## Goals

| Method | Path | Auth | Content-Type | Request Body | Success Response |
|---|---|---|---|---|---|
| POST | /goals/retirement | Yes | form-data | `RetirementGoalForm` | `{ plan, conflict }` |
| POST | /goals/one_time_goal | Yes | form-data | `OneTimeGoalForm` | `{ plan, conflict }` |
| POST | /goals/recurring_goal | Yes | form-data | `RecurringGoalForm` | currently inconsistent (see notes) |
| POST | /goals/explain_retirement_plan | No | JSON | `{ retirement_plan, user_question? }` | `{ explanation }` |
| POST | /goals/explain_one_time_goal | No | JSON | `{ goal_plan, user_question? }` | `{ explanation }` |
| POST | /goals/explain_recurring_goal | No | JSON | `{ goal_plan, user_question? }` | `{ explanation }` |
| GET | /goals/profile_overview | Yes | - | none | `{ profile, goals, conflict_summary, last_updated }` |
| GET | /goals/retirement | Yes | - | none | latest retirement plan or `null` |
| GET | /goals/one_time_goal | Yes | - | none | one-time goals list |
| DELETE | /goals/one_time_goal/{goal_id} | Yes | - | none | `{ message }` |
| GET | /goals/recurring_goal | Yes | - | none | recurring goals list |
| DELETE | /goals/recurring_goal/{goal_id} | Yes | - | none | `{ message }` |

---

## 4) Request payload samples

## Login (form-data)

```http
username=smoke_test_e2e@example.com&password=SecurePass123!
```

## Create User (form-data)

```http
name=Smoke Test User E2E
email=smoke_test_e2e@example.com
phone_number=9876543222
password=SecurePass123!
age=35
marital_status=Married
current_income=1200000
income_raise_pct=8.0
current_monthly_expenses=50000
spouse_age=33
spouse_income=600000
spouse_income_raise_pct=7.0
inflation_rate=6.0
```

## Retirement Plan (form-data)

```http
retirement_age=60
post_retirement_expense_pct=70.0
post_retirement_return=7.0
pre_retirement_return=10.0
life_expectancy=85
annual_post_retirement_income=0
existing_corpus=500000
existing_monthly_sip=10000
sip_raise_pct=8.0
```

## One-Time Goal (form-data)

```http
goal_name=Car Purchase
goal_amount=1500000
years_to_goal=3
pre_ret_return=10.0
existing_corpus=0
existing_monthly_sip=0
risk_tolerance=moderate
```

## Recurring Goal (form-data)

```http
goal_name=International Vacation
current_cost=200000
years_to_first=2
frequency_years=2
num_occurrences=5
goal_inflation_pct=6.0
expected_return_pct=10.0
existing_corpus=0
```

## Calculation example (JSON)

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

---

## 5) Flutter/Dart models (ready to copy)

```dart
typedef JsonMap = Map<String, dynamic>;

class AuthTokenResponse {
  final String accessToken;
  final String tokenType;

  AuthTokenResponse({required this.accessToken, required this.tokenType});

  factory AuthTokenResponse.fromJson(JsonMap json) {
    return AuthTokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }
}

class UserProfile {
  final String id;
  final String? name;
  final String? fullName;
  final String email;
  final String? phone;
  final String? phoneNumber;
  final String? maritalStatus;
  final int? age;
  final double? currentIncome;
  final double? incomeRaisePct;
  final double? currentMonthlyExpenses;
  final double? inflationRate;
  final double? spouseIncome;
  final int? spouseAge;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.fullName,
    this.phone,
    this.phoneNumber,
    this.maritalStatus,
    this.age,
    this.currentIncome,
    this.incomeRaisePct,
    this.currentMonthlyExpenses,
    this.inflationRate,
    this.spouseIncome,
    this.spouseAge,
  });

  factory UserProfile.fromJson(JsonMap json) {
    double? asDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    int? asInt(dynamic v) => v == null ? null : (v as num).toInt();

    return UserProfile(
      id: (json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      name: json['name'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      phoneNumber: json['phone_number'] as String?,
      maritalStatus: json['marital_status'] as String?,
      age: asInt(json['age']),
      currentIncome: asDouble(json['current_income']),
      incomeRaisePct: asDouble(json['income_raise_pct']),
      currentMonthlyExpenses: asDouble(json['current_monthly_expenses']),
      inflationRate: asDouble(json['inflation_rate']),
      spouseIncome: asDouble(json['spouse_income']),
      spouseAge: asInt(json['spouse_age']),
    );
  }
}

class GoalConflictSummary {
  final String overallStatus;
  final int? criticalBreachCount;
  final int? warningBreachCount;
  final int? advisoryCount;
  final JsonMap? corridorConfig;
  final JsonMap? surplusWaterfall;
  final List<dynamic>? yearlySummary;

  GoalConflictSummary({
    required this.overallStatus,
    this.criticalBreachCount,
    this.warningBreachCount,
    this.advisoryCount,
    this.corridorConfig,
    this.surplusWaterfall,
    this.yearlySummary,
  });

  factory GoalConflictSummary.fromJson(JsonMap json) {
    return GoalConflictSummary(
      overallStatus: (json['overall_status'] ?? 'all_clear') as String,
      criticalBreachCount: (json['critical_breach_count'] as num?)?.toInt(),
      warningBreachCount: (json['warning_breach_count'] as num?)?.toInt(),
      advisoryCount: (json['advisory_count'] as num?)?.toInt(),
      corridorConfig: json['corridor_config'] as JsonMap?,
      surplusWaterfall: json['surplus_waterfall'] as JsonMap?,
      yearlySummary: json['yearly_summary'] as List<dynamic>?,
    );
  }
}

class GoalWrappedResponse {
  final JsonMap plan;
  final GoalConflictSummary conflict;

  GoalWrappedResponse({required this.plan, required this.conflict});

  factory GoalWrappedResponse.fromJson(JsonMap json) {
    return GoalWrappedResponse(
      plan: (json['plan'] as JsonMap?) ?? <String, dynamic>{},
      conflict: GoalConflictSummary.fromJson(
        (json['conflict'] as JsonMap?) ?? <String, dynamic>{'overall_status': 'all_clear'},
      ),
    );
  }
}

class ProfileOverviewResponse {
  final UserProfile profile;
  final JsonMap goals;
  final GoalConflictSummary conflictSummary;
  final String lastUpdated;

  ProfileOverviewResponse({
    required this.profile,
    required this.goals,
    required this.conflictSummary,
    required this.lastUpdated,
  });

  factory ProfileOverviewResponse.fromJson(JsonMap json) {
    return ProfileOverviewResponse(
      profile: UserProfile.fromJson((json['profile'] as JsonMap?) ?? <String, dynamic>{}),
      goals: (json['goals'] as JsonMap?) ?? <String, dynamic>{},
      conflictSummary: GoalConflictSummary.fromJson(
        (json['conflict_summary'] as JsonMap?) ?? <String, dynamic>{'overall_status': 'all_clear'},
      ),
      lastUpdated: (json['last_updated'] ?? '') as String,
    );
  }
}
```

Recommended package set:

```yaml
dependencies:
  dio: ^5.8.0
  flutter_secure_storage: ^9.2.2
```

Optional for model generation:

```yaml
dependencies:
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
dev_dependencies:
  build_runner: ^2.4.15
  freezed: ^2.5.7
  json_serializable: ^6.9.0
```

---

## 6) Practical Flutter integration notes

1. Use form-data for:
- `/auth/login`
- `/user/` create
- `/user/{id}` update
- all `POST /goals/*` create endpoints
- `POST /calculation/required_annual_saving`

2. Use JSON for:
- other `/calculation/*` posts
- `/goals/explain_*`

3. Defensive parsing recommendation:
- For goal create endpoints, parse both wrapped and direct formats while backend stabilizes.

4. Use Dio `FormData` for form endpoints:

```dart
final dio = Dio(BaseOptions(baseUrl: baseUrl));

Future<AuthTokenResponse> login(String email, String password) async {
  final form = FormData.fromMap({
    'username': email,
    'password': password,
  });
  final res = await dio.post('/auth/login', data: form);
  return AuthTokenResponse.fromJson(res.data as JsonMap);
}

Future<GoalWrappedResponse> createOneTimeGoal(
  String token,
  JsonMap payload,
) async {
  final form = FormData.fromMap(payload);
  final res = await dio.post(
    '/goals/one_time_goal',
    data: form,
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  final data = res.data as JsonMap;
  if (data.containsKey('plan') && data.containsKey('conflict')) {
    return GoalWrappedResponse.fromJson(data);
  }

  // Fallback for unstable response shape.
  return GoalWrappedResponse.fromJson({
    'plan': data,
    'conflict': {'overall_status': 'all_clear'},
  });
}
```

5. Known backend inconsistencies to handle:
- `POST /goals/recurring_goal` currently may not return `{ plan, conflict }` due to missing explicit return in route.
- `infation_rate` spelling is required exactly for future value payload key.

---

## 7) Suggested Flutter folder usage (minimum)

Create only these API/domain files:
- `lib/core/network/api_client.dart` (Dio instance + interceptors)
- `lib/core/network/auth_storage.dart` (token save/load with secure storage)
- `lib/features/api/contracts.dart` (Dart models from section 5)
- `lib/features/api/endpoints.dart` (endpoint calls)
- `lib/features/goals/response_normalizer.dart` (wrapped vs direct plan parsing)

This is enough to integrate without reading the full backend internals.
