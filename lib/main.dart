// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/config/env_config.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/core/storage/local_migrations/local_migration.dart';
import 'package:flutter_project_agents/core/storage/local_migrations/local_migration_runner.dart';
import 'package:flutter_project_agents/core/supabase/supabase_service.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_queue.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/user_local_datasource.dart';
import 'package:flutter_project_agents/features/settings/data/datasources/profile_local_datasource.dart';
import 'package:flutter_project_agents/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flutter_project_agents/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_project_agents/features/settings/presentation/providers/theme_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/payment_history_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_member_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_model.dart';
import 'package:flutter_project_agents/routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrapResult = await _initializeBootstrap();
  if (bootstrapResult.safeMode) {
    runApp(const KeyFailureSafeModeApp());
    return;
  }

  final dependencies = bootstrapResult.dependencies;
  if (dependencies == null) {
    runApp(const KeyFailureSafeModeApp());
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        userLocalDataSourceProvider.overrideWithValue(
          dependencies.userLocalDataSource,
        ),
        authLocalDataSourceProvider.overrideWithValue(
          dependencies.authLocalDataSource,
        ),
        subscriptionLocalDataSourceProvider.overrideWithValue(
          dependencies.subscriptionLocalDataSource,
        ),
        profileLocalDataSourceProvider.overrideWithValue(
          dependencies.profileLocalDataSource,
        ),
        settingsLocalDataSourceProvider.overrideWithValue(
          dependencies.settingsLocalDataSource,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

Future<_BootstrapResult> _initializeBootstrap() async {
  try {
    await EnvConfig.load();
    await SupabaseService.init();
    await HiveService.init();

    // Startup order: init Hive -> run migrations -> open sensitive boxes.
    final migrationRunner = LocalMigrationRunner(
      migrations: _buildLocalMigrations(),
    );
    await migrationRunner.runPendingMigrations();

    await HiveService.openBox<SubscriptionModel>(
      SubscriptionLocalDataSourceImpl.subscriptionsBoxName,
      encrypted: true,
    );
    await HiveService.openBox<SubscriptionMemberModel>(
      SubscriptionLocalDataSourceImpl.membersBoxName,
      encrypted: true,
    );
    await HiveService.openBox<PaymentHistoryModel>(
      SubscriptionLocalDataSourceImpl.paymentHistoryBoxName,
      encrypted: true,
    );
    final paymentSyncQueueService = PaymentSyncQueueService();
    await paymentSyncQueueService.init();

    final userLocalDataSource = UserLocalDataSourceImpl();
    await userLocalDataSource.init();

    final authLocalDataSource = AuthLocalDataSourceImpl();
    final subscriptionLocalDataSource = SubscriptionLocalDataSourceImpl();

    final profileLocalDataSource = ProfileLocalDataSourceImpl();
    await profileLocalDataSource.init();

    final settingsLocalDataSource = SettingsLocalDataSourceImpl();
    await settingsLocalDataSource.init();

    return _BootstrapResult.ready(
      _BootstrapDependencies(
        userLocalDataSource: userLocalDataSource,
        authLocalDataSource: authLocalDataSource,
        subscriptionLocalDataSource: subscriptionLocalDataSource,
        profileLocalDataSource: profileLocalDataSource,
        settingsLocalDataSource: settingsLocalDataSource,
      ),
    );
  } on HiveKeyFailureException catch (e) {
    debugPrint('❌ [Bootstrap] Encryption key failure: $e');
    HiveService.activateKeyFailureSafeMode(e);
    return _BootstrapResult.safeMode();
  } on HiveWriteBlockedException catch (e) {
    debugPrint('❌ [Bootstrap] Safe mode write block: $e');
    return _BootstrapResult.safeMode();
  } catch (e) {
    debugPrint('❌ [Bootstrap] Unhandled startup error: $e');
    return _BootstrapResult.safeMode();
  }
}

List<LocalMigration> _buildLocalMigrations() {
  return const <LocalMigration>[];
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentTheme = ref.watch(themeProvider);

    final themeMode = switch (currentTheme) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'SubMate',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

class KeyFailureSafeModeApp extends StatelessWidget {
  const KeyFailureSafeModeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SubMate Recovery',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Storage Protection Active',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The app entered key-failure safe mode. '
                  'Writes are blocked while guided recovery is required. '
                  'No plaintext fallback is allowed.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  HiveService.safeModeRecoveryMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Recovery reason: ${HiveService.keyFailureReason ?? 'Unknown key retrieval error'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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

class _BootstrapResult {
  const _BootstrapResult._({
    required this.safeMode,
    required this.dependencies,
  });

  factory _BootstrapResult.ready(_BootstrapDependencies dependencies) =>
      _BootstrapResult._(safeMode: false, dependencies: dependencies);

  factory _BootstrapResult.safeMode() =>
      const _BootstrapResult._(safeMode: true, dependencies: null);

  final bool safeMode;
  final _BootstrapDependencies? dependencies;
}

class _BootstrapDependencies {
  const _BootstrapDependencies({
    required this.userLocalDataSource,
    required this.authLocalDataSource,
    required this.subscriptionLocalDataSource,
    required this.profileLocalDataSource,
    required this.settingsLocalDataSource,
  });

  final UserLocalDataSourceImpl userLocalDataSource;
  final AuthLocalDataSourceImpl authLocalDataSource;
  final SubscriptionLocalDataSourceImpl subscriptionLocalDataSource;
  final ProfileLocalDataSourceImpl profileLocalDataSource;
  final SettingsLocalDataSourceImpl settingsLocalDataSource;
}
