import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/api_result_card.dart';
import '../widgets/goal_card.dart';
import '../widgets/retirement_sheet.dart';
import '../widgets/one_time_goal_sheet.dart';

class GoalsScreen extends StatefulWidget {
  final UserProfile user;
  const GoalsScreen({super.key, required this.user});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  Map<String, dynamic>? _retirementResult;
  Map<String, dynamic>? _lastOneTimeResult;
  String? _lastOneTimeGoalName;
  String? _errorMsg;

  static const _goalTemplates = [
    GoalTemplate(
        icon: Icons.house_outlined, title: 'BUY A HOME', tag: 'PROPERTY'),
    GoalTemplate(
        icon: Icons.school_outlined, title: 'EDUCATION FUND', tag: 'EDUCATION'),
    GoalTemplate(
        icon: Icons.directions_car_outlined,
        title: 'BUY A VEHICLE',
        tag: 'LIFESTYLE'),
    GoalTemplate(
        icon: Icons.flight_outlined, title: 'TRAVEL FUND', tag: 'LIFESTYLE'),
    GoalTemplate(
        icon: Icons.savings_outlined, title: 'EMERGENCY CORPUS', tag: 'SAFETY'),
    GoalTemplate(
        icon: Icons.celebration_outlined,
        title: 'WEDDING FUND',
        tag: 'LIFESTYLE'),
  ];

  void _openRetirementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blackCard,
      shape: const RoundedRectangleBorder(),
      builder: (_) => RetirementGoalSheet(
        user: widget.user,
        onSubmit: (result) => setState(() {
          _retirementResult = result;
          _errorMsg = null;
        }),
        onError: (msg) => setState(() => _errorMsg = msg),
      ),
    );
  }

  void _openOneTimeGoalSheet(String goalName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blackCard,
      shape: const RoundedRectangleBorder(),
      builder: (_) => OneTimeGoalSheet(
        goalName: goalName,
        user: widget.user,
        onSubmit: (result) => setState(() {
          _lastOneTimeResult = result;
          _lastOneTimeGoalName = goalName;
          _errorMsg = null;
        }),
        onError: (msg) => setState(() => _errorMsg = msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          CustomPaint(
              size: MediaQuery.of(context).size, painter: GridPainter()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMsg != null) ...[
                          _buildErrorBanner(),
                          const SizedBox(height: 16)
                        ],
                        const SizedBox(height: 4),

                        // ── Retirement ─────────────────────────────────────
                        _buildSectionLabel('RETIREMENT GOAL'),
                        const SizedBox(height: 12),
                        _buildRetirementCard(),
                        if (_retirementResult != null) ...[
                          const SizedBox(height: 20),
                          ApiResultCard(
                              rawData: _retirementResult!,
                              title: 'RETIREMENT PLAN RESULT'),
                        ],

                        const SizedBox(height: 28),

                        // ── One-time goals ─────────────────────────────────
                        _buildSectionLabel('ONE-TIME GOALS'),
                        const SizedBox(height: 4),
                        Text(
                          'Tap a goal to set your target & calculate',
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 10,
                              letterSpacing: 2,
                              color: AppColors.textMuted.withOpacity(0.3)),
                        ),
                        const SizedBox(height: 16),
                        _buildGoalGrid(),
                        if (_lastOneTimeResult != null) ...[
                          const SizedBox(height: 28),
                          ApiResultCard(
                              rawData: _lastOneTimeResult!,
                              title:
                                  '${_lastOneTimeGoalName ?? "GOAL"} — RESULT'),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 20, height: 1, color: AppColors.green),
            const SizedBox(width: 10),
            Text('FINANCIAL GOALS',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 9,
                    letterSpacing: 4,
                    color: AppColors.green.withOpacity(0.6))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.green.withOpacity(0.3))),
              child: Text('LIVE',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 8,
                      letterSpacing: 2,
                      color: AppColors.green)),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('YOUR\nGOALS.',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.0,
                  color: Colors.white)),
        ]),
      );

  Widget _buildErrorBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.error.withOpacity(0.4)),
            color: AppColors.error.withOpacity(0.06)),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_errorMsg!,
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      height: 1.5,
                      color: AppColors.error.withOpacity(0.8)))),
          GestureDetector(
              onTap: () => setState(() => _errorMsg = null),
              child: Icon(Icons.close,
                  color: AppColors.error.withOpacity(0.5), size: 16)),
        ]),
      );

  Widget _buildRetirementCard() => GestureDetector(
        onTap: _openRetirementSheet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.blackCard,
              border: Border.all(color: AppColors.green.withOpacity(0.3))),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.green.withOpacity(0.4)),
                  color: AppColors.green.withOpacity(0.07)),
              child: const Icon(Icons.beach_access_outlined,
                  color: AppColors.green, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('RETIREMENT PLANNER',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    _retirementResult != null
                        ? 'Plan calculated \u2713  \u2014  tap to recalculate'
                        : 'Set your retirement age & corpus target',
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        color: AppColors.textMuted.withOpacity(0.4)),
                  ),
                ])),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.green.withOpacity(0.5)),
          ]),
        ),
      );

  Widget _buildGoalGrid() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _goalTemplates.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (_, i) => GoalCard(
          template: _goalTemplates[i],
          onTap: () => _openOneTimeGoalSheet(_goalTemplates[i].title),
        ),
      );

  Widget _buildSectionLabel(String title) => Row(children: [
        Container(width: 20, height: 1, color: AppColors.green),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                letterSpacing: 4,
                color: AppColors.green.withOpacity(0.7))),
      ]);
}
