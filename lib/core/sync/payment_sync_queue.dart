import 'package:flutter_project_agents/core/storage/hive_type_ids.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

part 'payment_sync_queue.g.dart';

/// Payment sync operation for queued offline operations
@HiveType(typeId: HiveTypeIds.paymentSyncQueue)
class PaymentSyncOperation extends HiveObject {

  PaymentSyncOperation({
    required this.id,
    required this.memberId,
    required this.subscriptionId,
    required this.amount,
    required this.markedBy,
    required this.action,
    required this.createdAt, this.notes,
    this.retryCount = 0,
  });
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String memberId;

  @HiveField(2)
  final String subscriptionId;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String markedBy;

  @HiveField(5)
  final String action; // 'paid' or 'unpaid'

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final int retryCount;

  /// Create a copy with updated retry count
  PaymentSyncOperation copyWith({
    String? id,
    String? memberId,
    String? subscriptionId,
    double? amount,
    String? markedBy,
    String? action,
    String? notes,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return PaymentSyncOperation(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      amount: amount ?? this.amount,
      markedBy: markedBy ?? this.markedBy,
      action: action ?? this.action,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Service for managing payment sync queue with Hive
class PaymentSyncQueueService {
  static const String _boxName = 'payment_sync_queue';

  Box<PaymentSyncOperation> get _box => Hive.box<PaymentSyncOperation>(_boxName);

  /// Initialize the sync queue service
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<PaymentSyncOperation>(_boxName);
    }
    debugPrint('🔄 [PaymentSyncQueue] Service initialized');
  }

  /// Enqueue a payment operation for sync
  Future<void> enqueue(PaymentSyncOperation operation) async {
    try {
      await _box.put(operation.id, operation);
      debugPrint('➕ [PaymentSyncQueue] Enqueued operation: ${operation.id} (action: ${operation.action})');
      debugPrint('   📊 Queue size: ${_box.length}');
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to enqueue operation: $e');
      rethrow;
    }
  }

  /// Get all pending sync operations
  Future<List<PaymentSyncOperation>> getPending() async {
    try {
      final operations = _box.values.toList();
      debugPrint('🔍 [PaymentSyncQueue] Retrieved ${operations.length} pending operations');
      return operations;
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to get pending operations: $e');
      return [];
    }
  }

  /// Mark an operation as synced (remove from queue)
  Future<void> markSynced(String operationId) async {
    try {
      await _box.delete(operationId);
      debugPrint('✅ [PaymentSyncQueue] Operation marked as synced: $operationId');
      debugPrint('   📊 Remaining in queue: ${_box.length}');
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to mark operation as synced: $e');
      rethrow;
    }
  }

  /// Increment retry count for an operation
  Future<void> incrementRetry(String operationId) async {
    try {
      final operation = _box.get(operationId);
      if (operation != null) {
        final updated = operation.copyWith(retryCount: operation.retryCount + 1);
        await _box.put(operationId, updated);
        debugPrint('⚠️ [PaymentSyncQueue] Incremented retry count for $operationId: ${updated.retryCount}');
      }
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to increment retry count: $e');
      rethrow;
    }
  }

  /// Clear all pending operations (use with caution!)
  Future<void> clearAll() async {
    try {
      final count = _box.length;
      await _box.clear();
      debugPrint('🗑️ [PaymentSyncQueue] Cleared all operations (removed $count)');
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to clear queue: $e');
      rethrow;
    }
  }

  /// Check if there are pending operations
  bool get hasPending => _box.isNotEmpty;

  /// Get count of pending operations
  int get pendingCount => _box.length;
}
