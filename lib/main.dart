// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/config/env_config.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/core/supabase/supabase_service.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/user_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_local_datasource.dart';
import 'package:flutter_project_agents/routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables from .env file
  await EnvConfig.load();

  // 2. Initialize Supabase client
  await SupabaseService.init();

  // 3. Initialize Hive database (local storage)
  await HiveService.init();

  //await HiveService.clearAuthData();

  // 4. Initialize singleton data sources
  final userLocalDataSource = UserLocalDataSourceImpl();
  await userLocalDataSource.init();

  final authLocalDataSource = AuthLocalDataSourceImpl();

  // 5. Open Hive boxes for subscriptions
  await Hive.openBox(SubscriptionLocalDataSourceImpl.subscriptionsBoxName);
  await Hive.openBox(SubscriptionLocalDataSourceImpl.membersBoxName);

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
