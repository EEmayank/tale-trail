import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kids_stories/core/navigation/app_router.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';

/// Bottom-navigation shell for the kid context.
///
/// Wraps the four primary kid-facing destinations:
///   0 — Home       (/home)
///   1 — My Books   (/library)
///   2 — Me         (/achievements)
///   3 — Parent     → /parent-gate?redirect=/parent/settings
///
/// The bottom navigation bar is hidden while the Story Player route is active
/// (i.e. the path contains `/play`).
class MainAppShell extends StatelessWidget {
  const MainAppShell({super.key, required this.child});

  /// The currently active child screen injected by [ShellRoute].
  final Widget child;

  // ---------------------------------------------------------------------------
  // Tab definitions
  // ---------------------------------------------------------------------------

  static const List<_TabItem> _tabs = [
    _TabItem(
      label: 'Home',
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
      route: AppRoutes.home,
    ),
    _TabItem(
      label: 'My Books',
      icon: Icons.library_books_outlined,
      activeIcon: Icons.library_books_rounded,
      route: AppRoutes.library,
    ),
    _TabItem(
      label: 'Me',
      icon: Icons.star_outline_rounded,
      activeIcon: Icons.star_rounded,
      route: AppRoutes.achievements,
    ),
    _TabItem(
      label: 'Parent',
      icon: Icons.lock_outline_rounded,
      activeIcon: Icons.lock_rounded,
      route: null, // handled specially
    ),
  ];

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the index of the currently active tab based on GoRouter location.
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.library)) return 1;
    if (location.startsWith(AppRoutes.achievements)) return 2;
    if (location.startsWith('/parent')) return 3;
    return 0; // Home (default)
  }

  /// `true` when the story player is active — hides the bottom bar.
  bool _isPlayerActive(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return location.endsWith('/play');
  }

  void _onTabTapped(BuildContext context, int index) {
    final tab = _tabs[index];
    if (tab.route == null) {
      // Parent tab — navigate to parental gate first.
      context.push(
        '${AppRoutes.parentGate}?redirect=${Uri.encodeComponent(AppRoutes.parentSettings)}',
      );
    } else {
      context.go(tab.route!);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hideNav = _isPlayerActive(context);
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: hideNav
          ? null
          : SizedBox(
              height: 80,
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (i) => _onTabTapped(context, i),
                selectedItemColor: TaleColors.terracotta,
                unselectedItemColor: TaleColors.warmGrey400,
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                items: _tabs
                    .asMap()
                    .entries
                    .map(
                      (e) => BottomNavigationBarItem(
                        icon: Icon(e.value.icon),
                        activeIcon: Icon(e.value.activeIcon),
                        label: e.value.label,
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private tab item model
// ---------------------------------------------------------------------------

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// The GoRouter route to push when this tab is selected.
  /// `null` means the tab requires special handling (e.g. parental gate).
  final String? route;
}
