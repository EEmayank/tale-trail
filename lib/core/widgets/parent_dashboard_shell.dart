import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kids_stories/core/navigation/app_router.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';

/// Shell widget wrapping all parent-facing screens.
///
/// Provides:
/// - An [AppBar] styled with the Inter font for a "mature" look.
/// - A back button that navigates to `/home`.
/// - A top-tab bar for navigating between the five parent sections.
class ParentDashboardShell extends StatelessWidget {
  const ParentDashboardShell({super.key, required this.child});

  /// The currently active parent screen, injected by [ShellRoute].
  final Widget child;

  // ---------------------------------------------------------------------------
  // Tab definitions
  // ---------------------------------------------------------------------------

  static const List<_ParentTab> _tabs = [
    _ParentTab(label: 'Settings', route: AppRoutes.parentSettings),
    _ParentTab(label: 'Profiles', route: AppRoutes.parentProfiles),
    _ParentTab(label: 'Reports', route: AppRoutes.parentReports),
    _ParentTab(label: 'Subscription', route: AppRoutes.parentSubscription),
    _ParentTab(label: 'Notifications', route: AppRoutes.parentNotifications),
  ];

  int _currentTabIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx =
        _tabs.indexWhere((t) => location.startsWith(t.route));
    return idx < 0 ? 0 : idx;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentTabIndex(context);

    return DefaultTabController(
      length: _tabs.length,
      initialIndex: currentIndex,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: 'Back to TaleTrail',
            onPressed: () => context.go(AppRoutes.home),
          ),
          title: const Text(
            'Parent Dashboard',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: TaleColors.warmGrey900,
            ),
          ),
          centerTitle: false,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: TaleColors.terracotta,
            unselectedLabelColor: TaleColors.warmGrey500,
            indicatorColor: TaleColors.terracotta,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            onTap: (index) => context.go(_tabs[index].route),
            tabs: _tabs
                .map((t) => Tab(text: t.label))
                .toList(),
          ),
        ),
        body: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private tab model
// ---------------------------------------------------------------------------

class _ParentTab {
  const _ParentTab({required this.label, required this.route});
  final String label;
  final String route;
}
