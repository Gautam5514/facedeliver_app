import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Persistent bottom navigation for the organiser workspace.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = <({String path, IconData icon, IconData active, String label})>[
    (
      path: Routes.adminDashboard,
      icon: Icons.dashboard_outlined,
      active: Icons.dashboard_rounded,
      label: 'Home',
    ),
    (
      path: Routes.adminEvents,
      icon: Icons.event_outlined,
      active: Icons.event_rounded,
      label: 'Events',
    ),
    (
      path: Routes.adminAnalytics,
      icon: Icons.insights_outlined,
      active: Icons.insights_rounded,
      label: 'Delivery',
    ),
    (
      path: Routes.adminBilling,
      icon: Icons.credit_card_outlined,
      active: Icons.credit_card_rounded,
      label: 'Billing',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Longest match wins so /admin does not claim /admin/events.
    var selected = 0;
    var bestLength = -1;
    for (var i = 0; i < _tabs.length; i++) {
      final path = _tabs[i].path;
      if (location == path ||
          (location.startsWith('$path/') && path.length > bestLength)) {
        selected = i;
        bestLength = path.length;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavTab(
                      icon: _tabs[i].icon,
                      activeIcon: _tabs[i].active,
                      label: _tabs[i].label,
                      selected: selected == i,
                      onTap: () {
                        if (selected == i) return;
                        context.go(_tabs[i].path);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.faint;

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.ink.withValues(alpha: 0.05),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            duration: AppTokens.fast,
            scale: selected ? 1.05 : 1,
            child: Icon(selected ? activeIcon : icon, size: 21, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppText.micro.copyWith(
              fontSize: 10.5,
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
