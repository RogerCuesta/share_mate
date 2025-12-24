// lib/core/storage/hive_type_ids.dart

/// Centralized TypeId management for Hive TypeAdapters
/// 
/// This class prevents typeId conflicts by maintaining a single source of truth
/// for all Hive model typeIds in the application.
/// 
/// **Rules:**
/// 1. Never reuse a typeId, even if a model is deleted
/// 2. Group related models with gaps (e.g., 0-9 for tasks, 10-19 for users)
/// 3. Document the feature each range belongs to
/// 4. Update this file BEFORE creating new Hive models
class HiveTypeIds {
  // Prevent instantiation
  HiveTypeIds._();
  
  // Feature: Tasks (0-9)
  static const int task = 0;
  static const int taskCategory = 1;
  static const int taskAttachment = 2;
  // Reserve 3-9 for future task-related models
  
  // Feature: Users & Auth (10-19)
  static const int user = 10;
  static const int userProfile = 11;
  static const int authToken = 12;
  // Reserve 13-19 for future user-related models
  
  // Feature: Settings (20-29)
  static const int appSettings = 20;
  static const int themeSettings = 21;
  static const int notificationSettings = 22;
  // Reserve 23-29 for future settings-related models
  
  // Feature: Subscriptions (30-39)
  static const int subscription = 30;
  static const int subscriptionMember = 31;
  static const int monthlyStats = 32;
  static const int paymentHistory = 33;
  static const int paymentSyncQueue = 34;
  // Reserve 35-39 for future subscription-related models

  // Add new feature ranges here (40-49, 50-59, etc.)
  // Example:
  // Feature: Analytics (40-49)
  // static const int analyticsEvent = 40;
  
  /// Validates that a typeId is not already in use
  /// This is a development-time helper, not used in production
  static bool isTypeIdAvailable(int typeId) {
    final usedIds = [
      task, taskCategory, taskAttachment,
      user, userProfile, authToken,
      appSettings, themeSettings, notificationSettings,
      subscription, subscriptionMember, monthlyStats, paymentHistory, paymentSyncQueue,
    ];

    return !usedIds.contains(typeId);
  }

  /// Returns a list of all used typeIds for documentation
  static List<int> get allUsedTypeIds => [
    task, taskCategory, taskAttachment,
    user, userProfile, authToken,
    appSettings, themeSettings, notificationSettings,
    subscription, subscriptionMember, monthlyStats, paymentHistory, paymentSyncQueue,
  ];
}
