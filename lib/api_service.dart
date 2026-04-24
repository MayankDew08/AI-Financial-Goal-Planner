import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Base URL — swap for your deployed backend ─────────────────────────────────
const String kBaseUrl = 'https://ai-financial-goal-planner.onrender.com';

// ── API Service (singleton) ───────────────────────────────────────────────────
// Usage:
//   await ApiService.instance.login(email: '...', password: '...');
//   final plan = await ApiService.instance.postRetirementGoal(...);
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // Set automatically after login()
  String? token;

  // Cached profile fetched from /auth/profile after login
  Map<String, dynamic>? cachedProfile;

  // ── Headers ──────────────────────────────────────────────────────────────────
  Map<String, String> get _formHeaders => {
        'Content-Type': 'application/x-www-form-urlencoded',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ── POST /users/ — register new user ─────────────────────────────────────────
  // ── Debug logger — shows in Flutter console (flutter run output) ─────────────
  // Set _debugMode = false before releasing to production.
  static const bool _debugMode = true;
  static void debugLog(String msg) {
    if (_debugMode) {
      // ignore: avoid_print
      print('[ApiService] $msg');
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String maritalStatus,
    required int age,
    required double currentIncome,
    required double incomeRaisePct,
    required double currentMonthlyExpenses,
    required double inflationRate,
    int? spouseAge,
    double? spouseIncome,
    double? spouseIncomeRaisePct,
  }) async {
    final body = {
      'email': email,
      'password': password,
      'name': fullName,
      'phone_number': phoneNumber,
      'marital_status': maritalStatus,
      'age': age.toString(),
      'current_income': currentIncome.toString(),
      'income_raise_pct': incomeRaisePct.toString(),
      'current_monthly_expenses': currentMonthlyExpenses.toString(),
      'inflation_rate': inflationRate.toString(),
      if (spouseAge != null) 'spouse_age': spouseAge.toString(),
      if (spouseIncome != null) 'spouse_income': spouseIncome.toString(),
      if (spouseIncomeRaisePct != null)
        'spouse_income_raise_pct': spouseIncomeRaisePct.toString(),
    };

    debugLog('>>> POST $kBaseUrl/user/');
    debugLog('>>> FIELDS: ${body.keys.join(', ')}');

    final response = await http.post(
      Uri.parse('$kBaseUrl/user/'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    debugLog('<<< REGISTER STATUS: ${response.statusCode}');
    debugLog('<<< REGISTER BODY:   ${response.body}');

    return _handle(response);
  }

  // ── POST /auth/login — get JWT token ─────────────────────────────────────────
  // FastAPI OAuth2PasswordRequestForm expects:
  //   username = email address
  //   password = plain password
  // Returns the access_token and stores it in [token].
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email, // FastAPI OAuth2 always uses 'username' key
        'password': password,
      },
    );

    final data = _handle(response);
    final t = data['access_token'] as String?;
    if (t == null) {
      throw const ApiException('No access_token in login response');
    }
    token = t;
    return t;
  }

  // ── GET /auth/profile — fetch full user profile ─────────────────────────────
  // Returns the profile map and caches it in [cachedProfile].
  Future<Map<String, dynamic>> fetchProfile() async {
    _requireToken();

    final response = await http.get(
      Uri.parse('$kBaseUrl/auth/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    debugLog('<<< PROFILE STATUS: ${response.statusCode}');
    debugLog('<<< PROFILE BODY:   ${response.body}');

    final data = _handle(response);
    cachedProfile = data;
    return data;
  }

  // ── GET /user/{user_id} — fetch profile by ID (fallback if /auth/profile fails)
  Future<Map<String, dynamic>> fetchProfileById(String userId) async {
    _requireToken();

    final response = await http.get(
      Uri.parse('$kBaseUrl/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    debugLog('<<< PROFILE-BY-ID STATUS: ${response.statusCode}');
    debugLog('<<< PROFILE-BY-ID BODY:   ${response.body}');

    final data = _handle(response);
    // /user/{id} wraps profile in { "user_id": ..., "user": {...} }
    final inner = data['user'] as Map<String, dynamic>? ?? data;
    cachedProfile = inner;
    return inner;
  }

  // ── Convenience: build UserProfile from cached backend profile ────────────────
  // Call fetchProfile() first, then this converts it to the Flutter model.
  UserProfileFromApi buildUserProfile() {
    final p = cachedProfile;
    if (p == null) {
      throw const ApiException(
          'Profile not loaded. Call fetchProfile() first.');
    }

    return UserProfileFromApi(
      id: p['id']?.toString() ?? '',
      name: p['name'] ?? 'User',
      email: p['email'] ?? '',
      phoneNumber: p['phone_number'] ?? '',
      maritalStatus: p['marital_status'] ?? 'single',
      age: (p['age'] as num?)?.toInt() ?? 0,
      currentIncome: (p['current_income'] as num?)?.toDouble() ?? 0,
      incomeRaisePct: (p['income_raise_pct'] as num?)?.toDouble() ?? 0,
      currentMonthlyExpenses:
          (p['current_monthly_expenses'] as num?)?.toDouble() ?? 0,
      inflationRate: (p['inflation_rate'] as num?)?.toDouble() ?? 3.0,
      spouseAge: (p['spouse_age'] as num?)?.toInt(),
      spouseIncome: (p['spouse_income'] as num?)?.toDouble(),
      spouseIncomeRaisePct: (p['spouse_income_raise_pct'] as num?)?.toDouble(),
      onboardingComplete: p['onboarding_complete'] as bool? ?? false,
    );
  }

  // ── POST /goals/retirement ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> postRetirementGoal({
    required int retirementAge,
    required double postRetirementExpensePct,
    required int lifeExpectancy,
    double postRetirementReturn = 7.0,
    double preRetirementReturn = 10.0,
    double annualPostRetirementIncome = 0.0,
    double existingCorpus = 0.0,
    double existingMonthlySip = 0.0,
    double sipRaisePct = 0.0,
  }) async {
    _requireToken();

    final response = await http.post(
      Uri.parse('$kBaseUrl/goals/retirement'),
      headers: _formHeaders,
      body: {
        'retirement_age': retirementAge.toString(),
        'post_retirement_expense_pct': postRetirementExpensePct.toString(),
        'life_expectancy': lifeExpectancy.toString(),
        'post_retirement_return': postRetirementReturn.toString(),
        'pre_retirement_return': preRetirementReturn.toString(),
        'annual_post_retirement_income': annualPostRetirementIncome.toString(),
        'existing_corpus': existingCorpus.toString(),
        'existing_monthly_sip': existingMonthlySip.toString(),
        'sip_raise_pct': sipRaisePct.toString(),
      },
    );

    return _handle(response);
  }

  // ── POST /goals/one_time_goal ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> postOneTimeGoal({
    required String goalName,
    required double goalAmount,
    required double yearsToGoal,
    double preRetReturn = 10.0,
    double existingCorpus = 0.0,
    double existingMonthlySip = 0.0,
    String riskTolerance = 'moderate',
  }) async {
    _requireToken();

    final response = await http.post(
      Uri.parse('$kBaseUrl/goals/one_time_goal'),
      headers: _formHeaders,
      body: {
        'goal_name': goalName,
        'goal_amount': goalAmount.toString(),
        'years_to_goal': yearsToGoal.toString(),
        'pre_ret_return': preRetReturn.toString(),
        'existing_corpus': existingCorpus.toString(),
        'existing_monthly_sip': existingMonthlySip.toString(),
        'risk_tolerance': riskTolerance,
      },
    );

    return _handle(response);
  }

  // ── POST /goals/explain_retirement_plan ──────────────────────────────────────
  Future<String> explainRetirementPlan({
    required Map<String, dynamic> retirementPlan,
    required String userQuestion,
  }) async {
    _requireToken();

    final response = await http.post(
      Uri.parse('$kBaseUrl/goals/explain_retirement_plan'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'retirement_plan': retirementPlan,
        'user_question': userQuestion,
      }),
    );

    final data = _handle(response);
    return data['explanation'] as String? ?? '';
  }

  // ── POST /goals/explain_one_time_goal ────────────────────────────────────────
  Future<String> explainOneTimeGoal({
    required Map<String, dynamic> goalPlan,
    required String userQuestion,
  }) async {
    _requireToken();

    final response = await http.post(
      Uri.parse('$kBaseUrl/goals/explain_one_time_goal'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'goal_plan': goalPlan,
        'user_question': userQuestion,
      }),
    );

    final data = _handle(response);
    return data['explanation'] as String? ?? '';
  }

  // ── POST /goals/recurring_goal ───────────────────────────────────────────────
  Future<Map<String, dynamic>> postRecurringGoal({
    required String goalName,
    required double currentCost,
    required double yearsToFirst,
    required double frequencyYears,
    required int numOccurrences,
    double goalInflationPct = 6.0,
    double expectedReturnPct = 10.0,
    double existingCorpus = 0.0,
  }) async {
    _requireToken();

    final response = await http.post(
      Uri.parse('$kBaseUrl/goals/recurring_goal'),
      headers: _formHeaders,
      body: {
        'goal_name': goalName,
        'current_cost': currentCost.toString(),
        'years_to_first': yearsToFirst.toString(),
        'frequency_years': frequencyYears.toString(),
        'num_occurrences': numOccurrences.toString(),
        'goal_inflation_pct': goalInflationPct.toString(),
        'expected_return_pct': expectedReturnPct.toString(),
        'existing_corpus': existingCorpus.toString(),
      },
    );

    return _handle(response);
  }

  // ── GET /goals/profile_overview — full portfolio snapshot ────────────────────
  // Returns: { profile, goals: { retirement, onetime, recurring }, conflict_summary, last_updated }
  Future<Map<String, dynamic>> fetchProfileOverview() async {
    _requireToken();
    final response = await http.get(
      Uri.parse('$kBaseUrl/goals/profile_overview'),
      headers: {'Authorization': 'Bearer $token'},
    );
    debugLog('<<< OVERVIEW STATUS: ${response.statusCode}');
    debugLog(
        '<<< OVERVIEW BODY:   ${response.body.substring(0, response.body.length.clamp(0, 400))}');
    return _handle(response);
  }

  // ── GET /goals/retirement ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchRetirementGoal() async {
    _requireToken();
    final response = await http.get(
      Uri.parse('$kBaseUrl/goals/retirement'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 404) return null;
    return _handle(response);
  }

  // ── GET /goals/one_time_goal ──────────────────────────────────────────────────
  Future<List<dynamic>> fetchOneTimeGoals() async {
    _requireToken();
    final response = await http.get(
      Uri.parse('$kBaseUrl/goals/one_time_goal'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _handle(response);
    return data['goals'] as List? ?? (data['data'] as List? ?? [data]);
  }

  // ── GET /goals/recurring_goal ─────────────────────────────────────────────────
  Future<List<dynamic>> fetchRecurringGoals() async {
    _requireToken();
    final response = await http.get(
      Uri.parse('$kBaseUrl/goals/recurring_goal'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _handle(response);
    return data['goals'] as List? ?? (data['data'] as List? ?? [data]);
  }

  // ── DELETE /goals/one_time_goal/{goal_id} ─────────────────────────────────────
  Future<void> deleteOneTimeGoal(String goalId) async {
    _requireToken();
    final response = await http.delete(
      Uri.parse('$kBaseUrl/goals/one_time_goal/$goalId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _handle(response);
  }

  // ── DELETE /goals/recurring_goal/{goal_id} ────────────────────────────────────
  Future<void> deleteRecurringGoal(String goalId) async {
    _requireToken();
    final response = await http.delete(
      Uri.parse('$kBaseUrl/goals/recurring_goal/$goalId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _handle(response);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  void _requireToken() {
    if (token == null) {
      throw const ApiException('Not authenticated. Please sign in.');
    }
  }

  Map<String, dynamic> _handle(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    final bodyStart = response.body.trimLeft();
    final isHtml = contentType.contains('text/html') ||
        bodyStart.startsWith('<!') ||
        bodyStart.startsWith('<html');

    // HTML on 5xx = Render cold start / server waking up
    if (isHtml && response.statusCode >= 500) {
      throw ApiException(
        'Server is starting up. Please wait ~30 seconds and try again.'
        ' (Render cold start — status ${response.statusCode})',
      );
    }

    // HTML on 2xx = wrong URL or redirect — show what we actually hit
    if (isHtml && response.statusCode >= 200 && response.statusCode < 300) {
      final snippet = response.body
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final preview =
          snippet.length > 120 ? snippet.substring(0, 120) : snippet;
      throw ApiException(
        '[${response.statusCode}] Server returned HTML — possible wrong API URL or redirect.\n'
        'Preview: $preview',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Extract the real FastAPI error message.
    // FastAPI sends { "detail": "..." } or { "detail": [ { "msg": "..." } ] } for 422s.
    String message =
        '[${response.statusCode}] ${response.reasonPhrase ?? 'Error'}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final detail = body['detail'];
        if (detail is String) {
          message = '[${response.statusCode}] $detail';
        } else if (detail is List && detail.isNotEmpty) {
          final msgs = detail
              .map((e) => e is Map ? (e['msg'] ?? e.toString()) : e.toString())
              .join(', ');
          message = '[422] $msgs';
        }
      }
    } catch (_) {
      final raw = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      message = '[${response.statusCode}] $raw';
    }

    throw ApiException(message);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── /calculation endpoints (JSON body, no auth required) ─────────────────
  // ══════════════════════════════════════════════════════════════════════════

  // POST /calculation/future_value_goal
  // Schema: FutureValue { principal, infation_rate (typo in backend), years }
  // Answers: "What is the inflation-adjusted future value of a lump sum?"
  Future<Map<String, dynamic>> calcFutureValue({
    required double principal,
    required double inflationRate,
    required double years,
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/calculation/future_value_goal'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'principal': principal,
        'infation_rate': inflationRate, // backend typo — keep as-is
        'years': years,
      }),
    );
    return _handle(response);
  }

  // POST /calculation/required_annual_saving  (Form fields)
  // Answers: "To reach corpus X in N years at R%, how much must I save/year?"
  Future<Map<String, dynamic>> calcRequiredAnnualSaving({
    required double futureValue,
    required double returnRate,
    required double years,
    double currentSavings = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/calculation/required_annual_saving'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'future_value': futureValue.toString(),
        'return_rate': returnRate.toString(),
        'years': years.toString(),
        'current_savings': currentSavings.toString(),
      },
    );
    return _handle(response);
  }

  // POST /calculation/starting-sip
  // Answers: "What monthly SIP do I need to reach a target corpus?"
  // Schema: SIPRequest { target_corpus, years, annual_return, existing_corpus? }
  // POST /calculation/starting-sip
  // Schema: SIPRequest { goal_amount, years_to_goal, pre_ret_return, inflation_rate, income_raise_pct }
  Future<Map<String, dynamic>> calcStartingSip({
    required double goalAmount,
    required double yearsToGoal,
    required double preRetReturn,
    required double inflationRate,
    required double incomeRaisePct,
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/calculation/starting-sip'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'goal_amount': goalAmount,
        'years_to_goal': yearsToGoal,
        'pre_ret_return': preRetReturn,
        'inflation_rate': inflationRate,
        'income_raise_pct': incomeRaisePct,
      }),
    );
    return _handle(response);
  }

  // Schema: SuggestedAllocation { years, risk }
  // Response keys: equity_allocation, debt_allocation
  Future<Map<String, dynamic>> calcSuggestAllocation({
    required int years, // years until goal (not age)
    required String risk, // 'conservative' | 'moderate' | 'aggressive'
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/calculation/suggest_allocation'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'years': years,
        'risk': risk,
      }),
    );
    return _handle(response);
  }

  // POST /calculation/check_feasibility
  // Schema: CheckFeasibilityRequest {
  //   starting_monthly_sip, annual_step_up_pct, monthly_income, income_raise_pct,
  //   monthly_expenses, years_to_goal, existing_monthly_sip, savings_cap_pct }
  Future<Map<String, dynamic>> calcCheckFeasibility({
    required double startingMonthlySip,
    required double annualStepUpPct,
    required double monthlyIncome,
    required double incomeRaisePct,
    required double monthlyExpenses,
    required double yearsToGoal,
    double existingMonthlySip = 0,
    double savingsCapPct = 50,
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/calculation/check_feasibility'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'starting_monthly_sip': startingMonthlySip,
        'annual_step_up_pct': annualStepUpPct,
        'monthly_income': monthlyIncome,
        'income_raise_pct': incomeRaisePct,
        'monthly_expenses': monthlyExpenses,
        'years_to_goal': yearsToGoal,
        'existing_monthly_sip': existingMonthlySip,
        'savings_cap_pct': savingsCapPct,
      }),
    );
    return _handle(response);
  }

  // POST /calculation/glide-path
  // Schema: GlidePathRequest { current_age, goal_age, start_equity_percent, end_equity_percent }
  // Constraint: goal_age > current_age, start_equity >= end_equity
  Future<Map<String, dynamic>> calcGlidePath({
    required int currentAge,
    required int goalAge,
    required double startEquityPercent,
    required double endEquityPercent,
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/calculation/glide-path'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'current_age': currentAge,
        'goal_age': goalAge,
        'start_equity_percent': startEquityPercent,
        'end_equity_percent': endEquityPercent,
      }),
    );
    return _handle(response);
  }

  // POST /calculation/blended_return
  // Schema: BlendedReturn { equity_pct, debt_pct, return_equity, return_debt }
  Future<Map<String, dynamic>> calcBlendedReturn({
    required double equityPct,
    required double debtPct,
    required double returnEquity,
    required double returnDebt,
  }) async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/calculation/blended_return'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'equity_pct': equityPct,
        'debt_pct': debtPct,
        'return_equity': returnEquity,
        'return_debt': returnDebt,
      }),
    );
    return _handle(response);
  }
}

// ── Full User Profile from backend /auth/profile ──────────────────────────────
// Use this wherever you need backend-sourced data (richer than the Flutter model)
class UserProfileFromApi {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String maritalStatus;
  final int age;
  final double currentIncome;
  final double incomeRaisePct;
  final double currentMonthlyExpenses;
  final double inflationRate;
  final int? spouseAge;
  final double? spouseIncome;
  final double? spouseIncomeRaisePct;
  final bool onboardingComplete;

  const UserProfileFromApi({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.maritalStatus,
    required this.age,
    required this.currentIncome,
    required this.incomeRaisePct,
    required this.currentMonthlyExpenses,
    required this.inflationRate,
    required this.onboardingComplete,
    this.spouseAge,
    this.spouseIncome,
    this.spouseIncomeRaisePct,
  });

  bool get isMarried => maritalStatus.toLowerCase() == 'married';
}

// ── Custom Exception ──────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}
