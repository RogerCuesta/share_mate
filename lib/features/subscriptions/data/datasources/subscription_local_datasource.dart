import 'package:hive/hive.dart';

import '../models/subscription_member_model.dart';
import '../models/subscription_model.dart';

/// Exception thrown when subscription local operations fail
class SubscriptionLocalException implements Exception {
  final String message;
  SubscriptionLocalException(this.message);

  @override
  String toString() => 'SubscriptionLocalException: $message';
}

/// Local data source for subscription operations using Hive
abstract class SubscriptionLocalDataSource {
  /// Get all cached subscriptions
  Future<List<SubscriptionModel>> getAllSubscriptions();

  /// Get subscription by ID
  Future<SubscriptionModel?> getSubscriptionById(String subscriptionId);

  /// Get subscriptions for a specific user
  Future<List<SubscriptionModel>> getSubscriptionsByOwnerId(String ownerId);

  /// Cache a subscription
  Future<void> cacheSubscription(SubscriptionModel subscription);

  /// Cache multiple subscriptions
  Future<void> cacheSubscriptions(List<SubscriptionModel> subscriptions);

  /// Update a cached subscription
  Future<void> updateSubscription(SubscriptionModel subscription);

  /// Delete a cached subscription
  Future<void> deleteSubscription(String subscriptionId);

  /// Clear all cached subscriptions
  Future<void> clearSubscriptions();

  /// Get all cached members
  Future<List<SubscriptionMemberModel>> getAllMembers();

  /// Get member by ID
  Future<SubscriptionMemberModel?> getMemberById(String memberId);

  /// Get members for a specific subscription
  Future<List<SubscriptionMemberModel>> getMembersBySubscriptionId(
    String subscriptionId,
  );

  /// Get members for subscriptions owned by user
  Future<List<SubscriptionMemberModel>> getMembersByOwnerId(String ownerId);

  /// Cache a member
  Future<void> cacheMember(SubscriptionMemberModel member);

  /// Cache multiple members
  Future<void> cacheMembers(List<SubscriptionMemberModel> members);

  /// Update a cached member
  Future<void> updateMember(SubscriptionMemberModel member);

  /// Delete a cached member
  Future<void> deleteMember(String memberId);

  /// Delete all members for a subscription
  Future<void> deleteMembersBySubscriptionId(String subscriptionId);

  /// Clear all cached members
  Future<void> clearMembers();
}

/// Implementation of SubscriptionLocalDataSource using Hive
class SubscriptionLocalDataSourceImpl implements SubscriptionLocalDataSource {
  static const String subscriptionsBoxName = 'subscriptions';
  static const String membersBoxName = 'subscription_members';

  Box<SubscriptionModel> get _subscriptionsBox =>
      Hive.box<SubscriptionModel>(subscriptionsBoxName);

  Box<SubscriptionMemberModel> get _membersBox =>
      Hive.box<SubscriptionMemberModel>(membersBoxName);

  // ========== Subscriptions ==========

  @override
  Future<List<SubscriptionModel>> getAllSubscriptions() async {
    try {
      return _subscriptionsBox.values.toList();
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to get all subscriptions: ${e.toString()}',
      );
    }
  }

  @override
  Future<SubscriptionModel?> getSubscriptionById(String subscriptionId) async {
    try {
      return _subscriptionsBox.get(subscriptionId);
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to get subscription by ID: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptionsByOwnerId(
    String ownerId,
  ) async {
    try {
      return _subscriptionsBox.values
          .where((subscription) => subscription.ownerId == ownerId)
          .toList();
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to get subscriptions by owner ID: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheSubscription(SubscriptionModel subscription) async {
    try {
      await _subscriptionsBox.put(subscription.id, subscription);
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to cache subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheSubscriptions(List<SubscriptionModel> subscriptions) async {
    try {
      final Map<String, SubscriptionModel> entries = {
        for (var subscription in subscriptions) subscription.id: subscription,
      };
      await _subscriptionsBox.putAll(entries);
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to cache subscriptions: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateSubscription(SubscriptionModel subscription) async {
    try {
      await _subscriptionsBox.put(subscription.id, subscription);
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to update subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteSubscription(String subscriptionId) async {
    try {
      await _subscriptionsBox.delete(subscriptionId);
      // Also delete associated members
      await deleteMembersBySubscriptionId(subscriptionId);
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to delete subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearSubscriptions() async {
    try {
      await _subscriptionsBox.clear();
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to clear subscriptions: ${e.toString()}',
      );
    }
  }

  // ========== Members ==========

  @override
  Future<List<SubscriptionMemberModel>> getAllMembers() async {
    try {
      return _membersBox.values.toList();
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to get all members: ${e.toString()}',
      );
    }
  }

  @override
  Future<SubscriptionMemberModel?> getMemberById(String memberId) async {
    try {
      return _membersBox.get(memberId);
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to get member by ID: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SubscriptionMemberModel>> getMembersBySubscriptionId(
    String subscriptionId,
  ) async {
    try {
      return _membersBox.values
          .where((member) => member.subscriptionId == subscriptionId)
          .toList();
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to get members by subscription ID: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SubscriptionMemberModel>> getMembersByOwnerId(
    String ownerId,
  ) async {
    try {
      // First, get all subscriptions owned by the user
      final subscriptions = await getSubscriptionsByOwnerId(ownerId);
      final subscriptionIds = subscriptions.map((s) => s.id).toSet();

      // Then, get all members for those subscriptions
      return _membersBox.values
          .where((member) => subscriptionIds.contains(member.subscriptionId))
          .toList();
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to get members by owner ID: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheMember(SubscriptionMemberModel member) async {
    try {
      await _membersBox.put(member.id, member);
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to cache member: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> cacheMembers(List<SubscriptionMemberModel> members) async {
    try {
      final Map<String, SubscriptionMemberModel> entries = {
        for (var member in members) member.id: member,
      };
      await _membersBox.putAll(entries);
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to cache members: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateMember(SubscriptionMemberModel member) async {
    try {
      await _membersBox.put(member.id, member);
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to update member: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteMember(String memberId) async {
    try {
      await _membersBox.delete(memberId);
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to delete member: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteMembersBySubscriptionId(String subscriptionId) async {
    try {
      final membersToDelete = await getMembersBySubscriptionId(subscriptionId);
      for (final member in membersToDelete) {
        await _membersBox.delete(member.id);
      }
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to delete members by subscription ID: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> clearMembers() async {
    try {
      await _membersBox.clear();
    } catch (e) {
      throw SubscriptionLocalException(
        'Failed to clear members: ${e.toString()}',
      );
    }
  }
}
