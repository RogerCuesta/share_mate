// lib/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/presentation/app_shell.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_project_agents/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/screens/create_subscription_screen.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/screens/create_group_subscription_screen.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/screens/subscription_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Route paths
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const app = '/app';
  static const createSubscription = '/create-subscription';
  static const createGroupSubscription = '/create-group-subscription';
}

/// Provider for GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final currentPath = state.uri.path;

      // Check auth state using when/maybeWhen pattern
      return authState.when(
        initial: () {
          // Still loading, stay on splash
          if (currentPath != AppRoutes.splash) {
            return AppRoutes.splash;
          }
          return null;
        },
        loading: () {
          // Still loading, stay on splash
          if (currentPath != AppRoutes.splash) {
            return AppRoutes.splash;
          }
          return null;
        },
        authenticated: (user) {
          // User is authenticated
          // Redirect to app if trying to access auth screens or splash
          if (currentPath == AppRoutes.login ||
              currentPath == AppRoutes.register ||
              currentPath == AppRoutes.splash) {
            return AppRoutes.app;
          }
          return null;
        },
        unauthenticated: () {
          // User is not authenticated
          // Redirect to login if trying to access protected routes
          if (currentPath == AppRoutes.app || currentPath == AppRoutes.splash) {
            return AppRoutes.login;
          }
          return null;
        },
        error: (message) {
          // On error, redirect to login if not already there
          if (currentPath == AppRoutes.app || currentPath == AppRoutes.splash) {
            return AppRoutes.login;
          }
          return null;
        },
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.app,
        name: 'app',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: AppRoutes.createSubscription,
        name: 'create-subscription',
        builder: (context, state) => const CreateSubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.createGroupSubscription,
        name: 'create-group-subscription',
        builder: (context, state) => const CreateGroupSubscriptionScreen(),
      ),
      GoRoute(
        path: '/subscription/:id',
        name: 'subscription-detail',
        builder: (context, state) {
          final subscriptionId = state.pathParameters['id']!;
          return SubscriptionDetailScreen(subscriptionId: subscriptionId);
        },
      ),
      GoRoute(
        path: '/subscription/:id/edit',
        name: 'edit-subscription',
        builder: (context, state) {
          final subscriptionId = state.pathParameters['id']!;
          return CreateGroupSubscriptionScreen(subscriptionId: subscriptionId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(state.uri.path),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Splash Screen - Shown while checking authentication status
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Check authentication status on splash screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuth();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo with Hero
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.subscriptions,
                        size: 80,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // App Name
                Text(
                  'SubMate',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Manage your subscriptions with ease',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 64),

                // Loading or Error State
                authState.maybeWhen(
                  error: (message) => Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error checking authentication',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            ref.read(authProvider.notifier).checkAuth();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                          ),
                        ),
                      ],
                    ),
                  ),
                  orElse: () => Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
