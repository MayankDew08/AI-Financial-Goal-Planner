import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'screen_dashboard.dart';
import 'screen_goals.dart';
import 'screen_planner.dart';
import 'screen_profile.dart';

// ── Main Navigation Shell ─────────────────────────────────────────────────────
class MainNav extends StatefulWidget {
  final UserProfile user;
  const MainNav({super.key, required this.user});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(user: widget.user),
      GoalsScreen(user: widget.user),
      PlannerScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];
  }

  static const _navItems = [
    _NavItem(icon: Icons.grid_view_rounded, label: 'HOME'),
    _NavItem(icon: Icons.flag_outlined, label: 'GOALS'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'PLANNER'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      // Keep screens alive when switching tabs
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blackMid,
        border: Border(
          top: BorderSide(color: AppColors.green.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final selected = i == _currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color:
                              selected ? AppColors.green : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.green.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _navItems[i].icon,
                            size: 20,
                            color: selected
                                ? AppColors.green
                                : AppColors.textMuted.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _navItems[i].label,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 8,
                            letterSpacing: 2,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            color: selected
                                ? AppColors.green
                                : AppColors.textMuted.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
