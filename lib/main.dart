// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/config/env_config.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/core/supabase/supabase_service.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/user_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/payment_history_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_member_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_model.dart';
import 'package:flutter_project_agents/routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables from .env file
  await EnvConfig.load();

  // 2. Initialize Supabase client
  await SupabaseService.init();

  // 3. Initialize Hive database (local storage)
  await HiveService.init();

  // 3.1 One-time migration: Clear subscription boxes to handle schema changes
  await _migrateSubscriptionBoxes();

  // 4. Initialize singleton data sources
  final userLocalDataSource = UserLocalDataSourceImpl();
  await userLocalDataSource.init();

  final authLocalDataSource = AuthLocalDataSourceImpl();

  // 5. Open Hive boxes for subscriptions with proper types
  await HiveService.openBox<SubscriptionModel>(
    SubscriptionLocalDataSourceImpl.subscriptionsBoxName,
  );
  await HiveService.openBox<SubscriptionMemberModel>(
    SubscriptionLocalDataSourceImpl.membersBoxName,
  );
  await HiveService.openBox<PaymentHistoryModel>(
    SubscriptionLocalDataSourceImpl.paymentHistoryBoxName,
  );

  final subscriptionLocalDataSource = SubscriptionLocalDataSourceImpl();

  // Run the app with Riverpod and provider overrides
  runApp(
    ProviderScope(
      overrides: [
        // Override singleton providers with initialized instances
        userLocalDataSourceProvider.overrideWithValue(userLocalDataSource),
        authLocalDataSourceProvider.overrideWithValue(authLocalDataSource),
        subscriptionLocalDataSourceProvider.overrideWithValue(subscriptionLocalDataSource),
      ],
      child: const MyApp(),
    ),
  );
}

/// One-time migration to clear subscription boxes after schema changes
///
/// This function clears the Hive boxes for subscriptions and members
/// to prevent deserialization errors when the schema has been updated
/// (e.g., adding the updatedAt field). The data will be re-fetched from
/// Supabase on next app usage.
Future<void> _migrateSubscriptionBoxes() async {
  try {
    print('🔄 [Migration] Checking if subscription boxes need migration...');

    // Delete the old boxes if they exist
    await HiveService.deleteBox(SubscriptionLocalDataSourceImpl.subscriptionsBoxName);
    await HiveService.deleteBox(SubscriptionLocalDataSourceImpl.membersBoxName);

    print('✅ [Migration] Subscription boxes cleared successfully');
  } catch (e) {
    print('⚠️ [Migration] Error during migration: $e');
    // Continue anyway - the app will work even if migration fails
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SubMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
