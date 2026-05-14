import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_service.dart';
import '../../../features/portfolio/widgets/portfolio_helpers.dart';
import '../../../features/portfolio/widgets/portfolio_stats_widget.dart';
import '../../../features/portfolio/widgets/retirement_card.dart';
import '../../../features/portfolio/widgets/one_time_goal_card.dart';
import '../../../features/portfolio/widgets/recurring_goal_card.dart';
import '../../../features/portfolio/widgets/conflict_banner.dart';

class PortfolioScreen extends StatefulWidget {
  final UserProfile user;
  final VoidCallback onCreateGoal;

  const PortfolioScreen({
    super.key,
    required this.user,
    required this.onCreateGoal,
  });

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _overview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.instance.fetchProfileOverview();
      setState(() => _overview = data);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Failed to load portfolio: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          CustomPaint(
              size: MediaQuery.of(context).size, painter: GridPainter()),
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.green.withOpacity(0.05),
                  Colors.transparent
                ]),
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? _buildLoader()
                : _error != null
                    ? _buildError()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.green.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Text('LOADING PORTFOLIO...',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  letterSpacing: 4,
                  color: AppColors.textMuted.withOpacity(0.3))),
        ]),
      );

  Widget _buildError() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  color: AppColors.error.withOpacity(0.05)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(_error!,
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            height: 1.6,
                            color: AppColors.error.withOpacity(0.8)))),
              ]),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                color: AppColors.green,
                child: const Text('RETRY',
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black)),
              ),
            ),
          ],
        ),
      );

  Widget _buildContent() {
    final ov = _overview!;
    final goals = ov['goals'] as Map<String, dynamic>? ?? {};
    final conflict = ov['conflict_summary'] as Map<String, dynamic>? ?? {};

    final retirement =
        decodePlanData(goals['retirement'] as Map<String, dynamic>?);
    final oneTimeRaw = (goals['onetime'] as List? ?? [])
        .map((g) =>
            decodePlanData(g as Map<String, dynamic>?) ??
            (g as Map<String, dynamic>))
        .toList();
    final recurringRaw = (goals['recurring'] as List? ?? [])
        .map((g) =>
            decodePlanData(g as Map<String, dynamic>?) ??
            (g as Map<String, dynamic>))
        .toList();

    final hasAnyGoal =
        retirement != null || oneTimeRaw.isNotEmpty || recurringRaw.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      backgroundColor: AppColors.blackCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            if (hasAnyGoal) ...[
              SizedBox(
                width: double.infinity,
                child: PortfolioStatsWidget(
                  user: widget.user,
                  retirement: retirement,
                  oneTimeGoals: oneTimeRaw,
                  recurringGoals: recurringRaw,
                  conflict: conflict,
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (!hasAnyGoal) ...[
              _buildEmptyState(),
            ] else ...[
              if (retirement != null) ...[
                const SectionLabel(
                    label: 'RETIREMENT', icon: Icons.beach_access_outlined),
                const SizedBox(height: 12),
                RetirementCard(data: retirement),
                const SizedBox(height: 28),
              ],
              if (oneTimeRaw.isNotEmpty) ...[
                const SectionLabel(
                    label: 'ONE-TIME GOALS', icon: Icons.flag_outlined),
                const SizedBox(height: 12),
                ...oneTimeRaw.map((g) {
                  final gm = g;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OneTimeGoalCard(
                      data: gm,
                      onDelete: () =>
                          _deleteOneTime(gm['goal_id']?.toString() ?? ''),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
              if (recurringRaw.isNotEmpty) ...[
                const SectionLabel(
                    label: 'RECURRING GOALS', icon: Icons.repeat_rounded),
                const SizedBox(height: 12),
                ...recurringRaw.map((g) {
                  final gm = g;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RecurringGoalCard(
                      data: gm,
                      onDelete: () =>
                          _deleteRecurring(gm['goal_id']?.toString() ?? ''),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ],
            if (conflict.isNotEmpty) ...[
              ConflictBanner(data: conflict),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 8),
            AddGoalButton(onTap: widget.onCreateGoal),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteOneTime(String goalId) async {
    if (goalId.isEmpty) return;
    final confirmed = await _confirmDelete(context);
    if (!confirmed) return;
    try {
      await ApiService.instance.deleteOneTimeGoal(goalId);
      _load();
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    }
  }

  Future<void> _deleteRecurring(String goalId) async {
    if (goalId.isEmpty) return;
    final confirmed = await _confirmDelete(context);
    if (!confirmed) return;
    try {
      await ApiService.instance.deleteRecurringGoal(goalId);
      _load();
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    }
  }

  Future<bool> _confirmDelete(BuildContext ctx) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (_) => Dialog(
            backgroundColor: AppColors.blackCard,
            shape: const RoundedRectangleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DELETE GOAL',
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    Text('This will archive the goal. It cannot be undone.',
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            height: 1.6,
                            color: AppColors.textMuted.withOpacity(0.5))),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(
                          child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.green.withOpacity(0.3))),
                          child: const Center(
                              child: Text('CANCEL',
                                  style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 10,
                                      letterSpacing: 2,
                                      color: Colors.white))),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: AppColors.error.withOpacity(0.8),
                          child: const Center(
                              child: Text('DELETE',
                                  style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 10,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))),
                        ),
                      )),
                    ]),
                  ]),
            ),
          ),
        ) ??
        false;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Courier', fontSize: 11)),
      backgroundColor: AppColors.error.withOpacity(0.85),
    ));
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 20, height: 1, color: AppColors.green),
            const SizedBox(width: 10),
            Text('MY PORTFOLIO',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 9,
                    letterSpacing: 4,
                    color: AppColors.green.withOpacity(0.6))),
            const Spacer(),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.refresh_rounded,
                    color: AppColors.green.withOpacity(0.5), size: 18),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('GOAL\nOVERVIEW.',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.0,
                  color: Colors.white)),
          const SizedBox(height: 20),
        ]),
      );

  Widget _buildEmptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.green.withOpacity(0.1)),
            color: AppColors.blackCard),
        child: Column(children: [
          Icon(Icons.flag_outlined,
              color: AppColors.green.withOpacity(0.25), size: 36),
          const SizedBox(height: 16),
          Text('NO GOALS YET',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  letterSpacing: 3,
                  color: AppColors.textMuted.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Create your first goal to start\nbuilding your financial plan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  height: 1.7,
                  color: AppColors.textMuted.withOpacity(0.25))),
        ]),
      );
}
