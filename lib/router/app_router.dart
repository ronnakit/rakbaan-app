import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../models/job.dart';
import '../screens/home_screen.dart';
import '../screens/model_setup_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/report_job_screen.dart';
import '../screens/report_job_confirm_screen.dart';
import '../screens/report_job_details_screen.dart';
import '../screens/tracking_screen.dart';

/// 5-tab bottom nav (rakbaan_md/02-app-features-ui.md §2), each tab its own
/// GoRouter branch so state (e.g. scroll position, the report-job flow's
/// step) survives switching tabs. Deep links (e.g. from a push notification)
/// can target any route below directly.
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/report',
              builder: (_, _) => const ReportJobScreen(),
              routes: [
                GoRoute(
                  path: 'details',
                  builder: (_, state) => ReportJobDetailsScreen(
                    category: state.extra as ServiceCategory?,
                  ),
                ),
                GoRoute(
                  path: 'confirm',
                  builder: (_, state) => ReportJobConfirmScreen(
                    draft: state.extra as ReportJobDraft?,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tracking',
              builder: (_, _) => const TrackingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/chat', builder: (_, _) => const ModelSetupScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _MainShell extends StatelessWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'หน้าหลัก'),
    (icon: Icons.build_outlined, selectedIcon: Icons.build, label: 'แจ้งซ่อม'),
    (
      icon: Icons.location_on_outlined,
      selectedIcon: Icons.location_on,
      label: 'ติดตามงาน',
    ),
    (icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: 'แชทมะลิ'),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'โปรไฟล์'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
      backgroundColor: AppColors.warmWhite,
    );
  }
}
