import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter_project_agents/features/contacts/presentation/screens/contacts_screen.dart';
import 'package:flutter_project_agents/features/home/presentation/screens/home_screen.dart';
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
/// - 4 main screens: Home, Contacts, Analytics, Settings
///
/// Screens:
/// - 0: Home (subscriptions overview)
/// - 1: Contacts (personal contact list)
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
          ContactsScreen(),
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
