// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'widget_glide_path.dart';
import 'widget_portfolio_stats.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ── Portfolio Screen ───────────────────────────────────────────────────────────
// Calls: GET /goals/profile_overview (Bearer)
// Shows: retirement plan, one-time goals, recurring goals, conflict summary
// ══════════════════════════════════════════════════════════════════════════════
class PortfolioScreen extends StatefulWidget {
  final UserProfile user;
  final VoidCallback onCreateGoal; // jumps to GOALS tab

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

  // ── Loading ───────────────────────────────────────────────────────────────
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

  // ── Error ─────────────────────────────────────────────────────────────────
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

  // ── Main content ──────────────────────────────────────────────────────────
  Widget _buildContent() {
    final ov = _overview!;
    final goals = ov['goals'] as Map<String, dynamic>? ?? {};
    final conflict = ov['conflict_summary'] as Map<String, dynamic>? ?? {};
    final retirement = goals['retirement'] as Map<String, dynamic>?;
    final oneTimeRaw = goals['onetime'] as List? ?? [];
    final recurringRaw = goals['recurring'] as List? ?? [];

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

            // ── Combined Portfolio Stats (from widget_portfolio_stats.dart) ──
            if (hasAnyGoal) ...[
              PortfolioStatsWidget(
                user: widget.user,
                retirement: retirement,
                oneTimeGoals: oneTimeRaw,
                recurringGoals: recurringRaw,
                conflict: conflict,
              ),
              const SizedBox(height: 24),
            ],

            // ── Conflict / health banner ─────────────────────────────────
            if (conflict.isNotEmpty) ...[
              _ConflictBanner(data: conflict),
              const SizedBox(height: 24),
            ],

            // ── Empty state ──────────────────────────────────────────────
            if (!hasAnyGoal) ...[
              _buildEmptyState(),
            ] else ...[
              // ── Retirement plan ────────────────────────────────────────
              if (retirement != null) ...[
                _SectionLabel(
                    label: 'RETIREMENT', icon: Icons.beach_access_outlined),
                const SizedBox(height: 12),
                _RetirementCard(data: retirement),
                const SizedBox(height: 28),
              ],

              // ── One-time goals ─────────────────────────────────────────
              if (oneTimeRaw.isNotEmpty) ...[
                _SectionLabel(
                    label: 'ONE-TIME GOALS', icon: Icons.flag_outlined),
                const SizedBox(height: 12),
                ...oneTimeRaw.map((g) {
                  final gm = g as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OneTimeGoalCard(
                      data: gm,
                      onDelete: () =>
                          _deleteOneTime(gm['goal_id']?.toString() ?? ''),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // ── Recurring goals ────────────────────────────────────────
              if (recurringRaw.isNotEmpty) ...[
                _SectionLabel(
                    label: 'RECURRING GOALS', icon: Icons.repeat_rounded),
                const SizedBox(height: 12),
                ...recurringRaw.map((g) {
                  final gm = g as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecurringGoalCard(
                      data: gm,
                      onDelete: () =>
                          _deleteRecurring(gm['goal_id']?.toString() ?? ''),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ],

            // ── Add goal CTA ─────────────────────────────────────────────
            const SizedBox(height: 8),
            _AddGoalButton(onTap: widget.onCreateGoal),
          ],
        ),
      ),
    );
  }

  // ── Delete actions ────────────────────────────────────────────────────────
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

// ══════════════════════════════════════════════════════════════════════════════
// ── Combined Portfolio Summary Card ───────────────────────────────────────────
// Aggregates SIPs + corpus targets across ALL goals. Computed client-side.
// ══════════════════════════════════════════════════════════════════════════════
class _ConflictBanner extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ConflictBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = (data['overall_status'] as String? ?? '').toLowerCase();
    final isGood = status == 'all_clear';
    final isWarn =
        status.contains('warning') || status.contains('under_saving');
    final isConflict = status.contains('conflict');

    final color = isGood
        ? AppColors.green
        : isWarn
            ? const Color(0xFFFFA500)
            : AppColors.error;

    final label = isGood
        ? 'ALL CLEAR'
        : isWarn
            ? 'UNDER SAVING'
            : 'CONFLICT DETECTED';

    final icon = isGood
        ? Icons.check_circle_outline
        : isWarn
            ? Icons.warning_amber_rounded
            : Icons.error_outline;

    final desc = isGood
        ? 'Your goals are on track. Keep investing consistently.'
        : isWarn
            ? 'Your current savings may not cover all goals.'
            : 'Your goals are competing. Review priorities.';

    // surplus waterfall — funded / deferred
    final waterfall = data['surplus_waterfall'] as Map<String, dynamic>?;
    final funded = waterfall?['funded'] as List? ?? [];
    final deferred = waterfall?['deferred'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: color))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  border: Border.all(color: color.withOpacity(0.3))),
              child: Text('PORTFOLIO HEALTH',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 7,
                      letterSpacing: 2,
                      color: color.withOpacity(0.6))),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Text(desc,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  height: 1.6,
                  color: AppColors.textMuted.withOpacity(0.45))),
        ),

        // Waterfall chips
        if (funded.isNotEmpty || deferred.isNotEmpty) ...[
          Container(height: 1, color: color.withOpacity(0.1)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (funded.isNotEmpty)
                Expanded(
                    child: _WaterfallCol(
                        label: 'FUNDED',
                        items: funded,
                        color: AppColors.green)),
              if (funded.isNotEmpty && deferred.isNotEmpty)
                const SizedBox(width: 12),
              if (deferred.isNotEmpty)
                Expanded(
                    child: _WaterfallCol(
                        label: 'DEFERRED',
                        items: deferred,
                        color: AppColors.error.withOpacity(0.7))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _WaterfallCol extends StatelessWidget {
  final String label;
  final List items;
  final Color color;
  const _WaterfallCol(
      {required this.label, required this.items, required this.color});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 2,
                color: color.withOpacity(0.7))),
        const SizedBox(height: 6),
        ...items.map((item) {
          final name = item is Map
              ? (item['goal_name'] ?? item['name'] ?? item.toString())
              : item.toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 7),
              Expanded(
                  child: Text(name.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          color: AppColors.textMuted.withOpacity(0.55)))),
            ]),
          );
        }),
      ]);
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Retirement Card ────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _RetirementCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _RetirementCard({required this.data});

  @override
  State<_RetirementCard> createState() => _RetirementCardState();
}

class _RetirementCardState extends State<_RetirementCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // plan may be nested under 'plan' key or at root
    final plan = (widget.data['plan'] as Map<String, dynamic>?) ?? widget.data;
    final status = (plan['status'] as String? ?? '').toLowerCase();
    final isFeasible = status == 'feasible';
    final statusColor = isFeasible ? AppColors.green : AppColors.error;

    final corpus = plan['corpus'] as Map<String, dynamic>? ?? {};
    final feasibility = plan['feasibility'] as Map<String, dynamic>? ?? {};

    final requiredCorpus = _fmtCurrency(corpus['required_corpus']);
    final monthlyShortfall = _fmtCurrency(feasibility['monthly_shortfall']);
    final requiredSip = _fmtCurrency(corpus['starting_monthly_sip'] ??
        corpus['required_sip'] ??
        corpus['monthly_sip']);
    final retirementAge = plan['retirement_age']?.toString() ??
        corpus['retirement_age']?.toString() ??
        '—';

    return Container(
      decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                  color: statusColor.withOpacity(0.07)),
              child: Icon(Icons.beach_access_outlined,
                  color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('RETIREMENT PLAN',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('Retire at $retirementAge',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          color: AppColors.textMuted.withOpacity(0.4))),
                ])),
            _StatusChip(status: status, color: statusColor),
          ]),
        ),

        // ── Key metrics row ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            _MetricMini(label: 'CORPUS NEEDED', value: requiredCorpus),
            const SizedBox(width: 12),
            _MetricMini(
                label: isFeasible ? 'MONTHLY SIP' : 'MONTHLY SHORTFALL',
                value: isFeasible ? requiredSip : monthlyShortfall,
                valueColor: isFeasible ? AppColors.green : AppColors.error),
          ]),
        ),

        // ── Expandable details ───────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.green.withOpacity(0.08)))),
            child: Row(children: [
              Text(_expanded ? 'HIDE DETAILS' : 'VIEW DETAILS',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      letterSpacing: 2,
                      color: AppColors.green.withOpacity(0.5))),
              const Spacer(),
              Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.green.withOpacity(0.4),
                  size: 16),
            ]),
          ),
        ),

        if (_expanded) _RetirementDetail(plan: plan),
      ]),
    );
  }
}

class _RetirementDetail extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _RetirementDetail({required this.plan});

  @override
  Widget build(BuildContext context) {
    final corpus = plan['corpus'] as Map<String, dynamic>? ?? {};
    final feasibility = plan['feasibility'] as Map<String, dynamic>? ?? {};
    // glide_path can be a List, Map, or nested — GlidePathWidget handles all shapes
    final glideRaw = plan['glide_path'];
    final buckets = plan['buckets'] as Map<String, dynamic>?;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (corpus.isNotEmpty) _DetailSection(title: 'CORPUS', data: corpus),
      if (feasibility.isNotEmpty)
        _DetailSection(title: 'FEASIBILITY', data: feasibility),
      if (glideRaw != null) GlidePathWidget(raw: glideRaw),
      if (buckets != null && buckets.isNotEmpty) _BucketsSection(data: buckets),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── One-Time Goal Card ─────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _OneTimeGoalCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  const _OneTimeGoalCard({required this.data, required this.onDelete});

  @override
  State<_OneTimeGoalCard> createState() => _OneTimeGoalCardState();
}

class _OneTimeGoalCardState extends State<_OneTimeGoalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final plan = (widget.data['plan'] as Map<String, dynamic>?) ?? widget.data;
    final status = (plan['status'] as String? ?? '').toLowerCase();
    final isFeasible = status == 'feasible';
    final statusColor = isFeasible ? AppColors.green : AppColors.error;

    final summary = plan['goal_summary'] as Map<String, dynamic>? ?? {};
    final sipPlan = plan['sip_plan'] as Map<String, dynamic>? ?? {};
    final goalName = plan['goal_name'] ??
        summary['goal_name'] ??
        widget.data['goal_name'] ??
        'GOAL';

    final targetAmount = _fmtCurrency(summary['target_amount'] ??
        summary['goal_amount'] ??
        plan['goal_amount']);
    final monthlySip = _fmtCurrency(sipPlan['starting_monthly_sip'] ??
        sipPlan['monthly_sip'] ??
        plan['monthly_sip']);
    final yearsToGoal = summary['years_to_goal']?.toString() ??
        plan['years_to_goal']?.toString() ??
        '—';

    return Container(
      decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                  color: statusColor.withOpacity(0.06)),
              child: Icon(Icons.flag_outlined, color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(goalName.toString().toUpperCase(),
                      style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('$yearsToGoal years away',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          color: AppColors.textMuted.withOpacity(0.35))),
                ])),
            // Delete button
            GestureDetector(
              onTap: widget.onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.delete_outline,
                    color: AppColors.textMuted.withOpacity(0.3), size: 18),
              ),
            ),
            const SizedBox(width: 4),
            _StatusChip(status: status, color: statusColor),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            _MetricMini(label: 'TARGET', value: targetAmount),
            const SizedBox(width: 12),
            _MetricMini(
                label: 'MONTHLY SIP',
                value: monthlySip,
                valueColor: AppColors.green),
          ]),
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.green.withOpacity(0.06)))),
            child: Row(children: [
              Text(_expanded ? 'HIDE DETAILS' : 'VIEW DETAILS',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      letterSpacing: 2,
                      color: AppColors.green.withOpacity(0.5))),
              const Spacer(),
              Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.green.withOpacity(0.4),
                  size: 16),
            ]),
          ),
        ),
        if (_expanded) _OneTimeDetail(plan: plan),
      ]),
    );
  }
}

class _OneTimeDetail extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _OneTimeDetail({required this.plan});

  @override
  Widget build(BuildContext context) {
    final summary = plan['goal_summary'] as Map<String, dynamic>? ?? {};
    final sipPlan = plan['sip_plan'] as Map<String, dynamic>? ?? {};
    final feasibility = plan['feasibility'] as Map<String, dynamic>? ?? {};
    final allocation = plan['allocation'] as Map<String, dynamic>?;
    final glideRaw = plan['glide_path'];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (summary.isNotEmpty)
        _DetailSection(title: 'GOAL SUMMARY', data: summary),
      if (sipPlan.isNotEmpty) _DetailSection(title: 'SIP PLAN', data: sipPlan),
      if (feasibility.isNotEmpty)
        _DetailSection(title: 'FEASIBILITY', data: feasibility),
      if (allocation != null && allocation.isNotEmpty)
        _AllocationBar(data: allocation),
      if (glideRaw != null) GlidePathWidget(raw: glideRaw),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Recurring Goal Card ────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _RecurringGoalCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  const _RecurringGoalCard({required this.data, required this.onDelete});

  @override
  State<_RecurringGoalCard> createState() => _RecurringGoalCardState();
}

class _RecurringGoalCardState extends State<_RecurringGoalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final plan = (widget.data['plan'] as Map<String, dynamic>?) ?? widget.data;
    final status = (plan['status'] as String? ?? '').toLowerCase();
    final isFeasible = status == 'feasible';
    final statusColor = isFeasible ? AppColors.green : AppColors.error;

    final summary = plan['goal_summary'] as Map<String, dynamic>? ?? {};
    final sipPlan = plan['sip_plan'] as Map<String, dynamic>? ?? {};
    final goalName = plan['goal_name'] ??
        summary['goal_name'] ??
        widget.data['goal_name'] ??
        'RECURRING GOAL';

    final totalSip =
        _fmtCurrency(sipPlan['total_monthly_sip'] ?? sipPlan['monthly_sip']);
    final occurrences = sipPlan['num_occurrences']?.toString() ??
        summary['num_occurrences']?.toString() ??
        '—';

    return Container(
      decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                  color: statusColor.withOpacity(0.06)),
              child: Icon(Icons.repeat_rounded, color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(goalName.toString().toUpperCase(),
                      style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('$occurrences occurrences',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          color: AppColors.textMuted.withOpacity(0.35))),
                ])),
            GestureDetector(
              onTap: widget.onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.delete_outline,
                    color: AppColors.textMuted.withOpacity(0.3), size: 18),
              ),
            ),
            const SizedBox(width: 4),
            _StatusChip(status: status, color: statusColor),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _MetricMini(
              label: 'TOTAL MONTHLY SIP',
              value: totalSip,
              valueColor: AppColors.green),
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.green.withOpacity(0.06)))),
            child: Row(children: [
              Text(_expanded ? 'HIDE DETAILS' : 'VIEW DETAILS',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      letterSpacing: 2,
                      color: AppColors.green.withOpacity(0.5))),
              const Spacer(),
              Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.green.withOpacity(0.4),
                  size: 16),
            ]),
          ),
        ),
        if (_expanded) _RecurringDetail(plan: plan),
      ]),
    );
  }
}

class _RecurringDetail extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _RecurringDetail({required this.plan});

  @override
  Widget build(BuildContext context) {
    final summary = plan['goal_summary'] as Map<String, dynamic>? ?? {};
    final sipPlan = plan['sip_plan'] as Map<String, dynamic>? ?? {};
    final feasibility = plan['feasibility'] as Map<String, dynamic>? ?? {};
    final occurrencePlans = sipPlan['occurrence_plans'] as List? ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (summary.isNotEmpty)
        _DetailSection(title: 'GOAL SUMMARY', data: summary),
      if (feasibility.isNotEmpty)
        _DetailSection(title: 'FEASIBILITY', data: feasibility),
      if (occurrencePlans.isNotEmpty) _OccurrenceTable(items: occurrencePlans),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Shared detail sub-widgets ──────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

// Generic key-value detail section — skips nulls, arrays, nested maps
class _DetailSection extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  const _DetailSection({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = data.entries
        .where((e) =>
            e.value != null &&
            e.value is! List &&
            e.value is! Map &&
            e.value.toString().isNotEmpty &&
            e.value.toString() != 'null')
        .toList();

    if (rows.isEmpty) return const SizedBox();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Text(title,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.45))),
      ),
      ...rows.asMap().entries.map((e) {
        final isLast = e.key == rows.length - 1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.green.withOpacity(0.05)),
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(color: AppColors.green.withOpacity(0.05)),
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                flex: 2,
                child: Text(_label(e.value.key),
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9,
                        letterSpacing: 1,
                        color: AppColors.textMuted.withOpacity(0.35)))),
            const SizedBox(width: 8),
            Expanded(
                flex: 3,
                child: Text(_fmt(e.value.key, e.value.value),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted.withOpacity(0.75)))),
          ]),
        );
      }),
    ]);
  }
}

// Glide path — list of {age, equity, debt} objects
// ══════════════════════════════════════════════════════════════════════════════
// Bucket strategy display
class _BucketsSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BucketsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Text('BUCKET STRATEGY',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.45))),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Column(
          children: data.entries.map((bucket) {
            final bm = bucket.value is Map
                ? Map<String, dynamic>.from(bucket.value as Map)
                : <String, dynamic>{};
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blackMid,
                border: Border.all(color: AppColors.green.withOpacity(0.1)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bucket.key.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9,
                            letterSpacing: 2,
                            color: AppColors.green.withOpacity(0.65),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...bm.entries
                        .where((e) =>
                            e.value != null &&
                            e.value is! List &&
                            e.value is! Map)
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(children: [
                                Expanded(
                                    flex: 2,
                                    child: Text(_label(e.key),
                                        style: TextStyle(
                                            fontFamily: 'Courier',
                                            fontSize: 9,
                                            color: AppColors.textMuted
                                                .withOpacity(0.35)))),
                                Text(_fmt(e.key, e.value),
                                    style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted
                                            .withOpacity(0.75))),
                              ]),
                            )),
                  ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}

// Allocation equity/debt bar
class _AllocationBar extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AllocationBar({required this.data});

  @override
  Widget build(BuildContext context) {
    double equity = 0;
    double debt = 0;
    data.forEach((k, v) {
      final lk = k.toLowerCase();
      final n = num.tryParse(v?.toString() ?? '')?.toDouble() ?? 0;
      if (lk.contains('equity')) equity = n > 1 ? n : n * 100;
      if (lk.contains('debt') || lk.contains('bond'))
        debt = n > 1 ? n : n * 100;
    });
    if (equity > 0 && debt == 0) debt = 100 - equity;
    if (equity == 0 && debt == 0) return const SizedBox();

    final eqI = equity.round().clamp(1, 99);
    final dtI = (100 - eqI).clamp(1, 99);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ALLOCATION',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.45))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              flex: eqI, child: Container(height: 8, color: AppColors.green)),
          Expanded(
              flex: dtI,
              child: Container(
                  height: 8, color: AppColors.textMuted.withOpacity(0.18))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _AllocLeg(color: AppColors.green, label: 'EQUITY', pct: eqI),
          const SizedBox(width: 20),
          _AllocLeg(
              color: AppColors.textMuted.withOpacity(0.5),
              label: 'DEBT',
              pct: dtI),
        ]),
      ]),
    );
  }
}

class _AllocLeg extends StatelessWidget {
  final Color color;
  final String label;
  final int pct;
  const _AllocLeg(
      {required this.color, required this.label, required this.pct});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 6),
        Text('$label  $pct%',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 9,
                color: AppColors.textMuted.withOpacity(0.5))),
      ]);
}

// Occurrence plans table for recurring goals
// Local table helpers for _OccurrenceTable (replaces deleted _GlideHeader/_GlideCell)
class _OccHdr extends StatelessWidget {
  final String text;
  const _OccHdr(this.text);
  @override
  Widget build(BuildContext context) => Expanded(
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 7,
              letterSpacing: 1,
              color: AppColors.green.withOpacity(0.5))));
}

class _OccCell extends StatelessWidget {
  final String text;
  final Color? color;
  const _OccCell(this.text, {this.color});
  @override
  Widget build(BuildContext context) => Expanded(
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textMuted.withOpacity(0.65))));
}

class _OccurrenceTable extends StatelessWidget {
  final List items;
  const _OccurrenceTable({required this.items});

  @override
  Widget build(BuildContext context) {
    final rows = items.take(6).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Text('OCCURRENCE PLANS',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.45))),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.green.withOpacity(0.1))),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.green.withOpacity(0.05),
              child: Row(children: [
                _OccHdr('OCC.'),
                _OccHdr('COST'),
                _OccHdr('SIP'),
              ]),
            ),
            ...rows.asMap().entries.map((e) {
              final row = e.value is Map
                  ? Map<String, dynamic>.from(e.value as Map)
                  : <String, dynamic>{};
              final isLast = e.key == rows.length - 1;
              final occ =
                  row['occurrence']?.toString() ?? (e.key + 1).toString();
              final cost = _fmtCurrency(
                  row['cost'] ?? row['inflated_cost'] ?? row['goal_cost']);
              final sip = _fmtCurrency(row['monthly_sip'] ?? row['sip']);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: AppColors.green.withOpacity(0.05)))),
                child: Row(children: [
                  _OccCell(occ),
                  _OccCell(cost),
                  _OccCell(sip, color: AppColors.green.withOpacity(0.8)),
                ]),
              );
            }),
          ]),
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Shared small widgets ───────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.green.withOpacity(0.6), size: 14),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                letterSpacing: 4,
                color: AppColors.green.withOpacity(0.7))),
      ]);
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.4)),
            color: color.withOpacity(0.07)),
        child: Text(status.isEmpty ? '—' : status.toUpperCase(),
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                color: color)),
      );
}

class _MetricMini extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _MetricMini(
      {required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  letterSpacing: 1,
                  color: AppColors.textMuted.withOpacity(0.35))),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: valueColor ?? Colors.white)),
          ),
        ]),
      );
}

class _AddGoalButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddGoalButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.green.withOpacity(0.35)),
              color: AppColors.green.withOpacity(0.04)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add, color: AppColors.green.withOpacity(0.7), size: 16),
            const SizedBox(width: 10),
            Text('CREATE NEW GOAL',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    letterSpacing: 3,
                    color: AppColors.green.withOpacity(0.7))),
          ]),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Formatting helpers ─────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

String _label(String key) => key.replaceAll('_', ' ').trim().toUpperCase();

String _fmt(String key, dynamic raw) {
  if (raw == null) return '—';
  final s = raw.toString().trim();
  if (s.isEmpty || s == 'null' || s == 'None') return '—';
  if (s.toLowerCase() == 'true') return 'YES';
  if (s.toLowerCase() == 'false') return 'NO';
  final n = num.tryParse(s);
  if (n == null) return s.length > 40 ? '${s.substring(0, 40)}…' : s;
  final lk = key.toLowerCase();
  if (lk.contains('pct') ||
      lk.contains('rate') ||
      lk.contains('return') ||
      lk.contains('percent') ||
      lk.contains('raise') ||
      lk.contains('yield') ||
      lk.contains('allocation') ||
      lk.contains('equity') ||
      lk.contains('debt')) {
    final isRatio = n.abs() <= 1.0;
    return isRatio
        ? '${(n * 100).toStringAsFixed(1)}%'
        : '${n.toStringAsFixed(1)}%';
  }
  if (lk.contains('age') ||
      lk.contains('year') ||
      lk.contains('duration') ||
      lk.contains('period') ||
      lk.contains('count') ||
      lk.contains('occurrence')) {
    return n.toInt().toString();
  }
  return _fmtCurrency(raw);
}

String _fmtCurrency(dynamic raw) {
  if (raw == null) return '—';
  final s = raw.toString().trim();
  final n = num.tryParse(s);
  if (n == null) return s.length > 30 ? '${s.substring(0, 30)}…' : s;
  final abs = n.abs();
  if (abs >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
  if (abs >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
  if (abs >= 1000) return '₹${(n / 1000).toStringAsFixed(1)} K';
  if (abs == 0) return '₹0';
  return '₹${n.toStringAsFixed(0)}';
}
