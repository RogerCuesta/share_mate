import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter_project_agents/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_project_agents/features/friends/presentation/screens/friends_screen.dart';
import 'package:flutter_project_agents/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/screens/analytics_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main app shell with bottom navigation and centered FAB
///
/// Manages navigation between main screens using IndexedStack
/// to preserve state across tab switches.
///
/// Features:
/// - Notched bottom navigation bar
/// - Centered FAB for creating subscriptions
/// - 4 main screens: Home, Friends, Analytics, Settings
///
/// Screens:
/// - 0: Home (subscriptions overview)
/// - 1: Friends (shared subscriptions)
/// - 2: Analytics (spending insights)
/// - 3: Settings (user preferences)
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedBottomNavIndexProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          HomeScreen(),
          FriendsScreen(),
          AnalyticsScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-subscription'),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 8,
        child: const Icon(
          Icons.add,
          size: 32,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PLACEHOLDER SCREENS
// ═══════════════════════════════════════════════════════════════════════════

/// Friends screen placeholder
///
/// TODO: Implement friends/shared subscriptions management
class _FriendsScreen extends StatelessWidget {
  const _FriendsScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A3E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Friends',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Manage shared subscriptions with friends',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Coming soon badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Analytics screen placeholder
///
/// TODO: Implement spending analytics and insights
class _AnalyticsScreen extends StatelessWidget {
  const _AnalyticsScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A3E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Analytics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Track your spending and subscription trends',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Coming soon badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
