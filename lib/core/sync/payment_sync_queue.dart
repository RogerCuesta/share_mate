import 'package:flutter/foundation.dart';
import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/core/storage/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'payment_sync_queue.g.dart';

const String paymentSyncStatusPending = 'pending';
const String paymentSyncStatusProcessing = 'processing';
const String paymentSyncStatusTerminal = 'terminal';

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
    required this.createdAt,
    this.notes,
    this.retryCount = 0,
    this.status = paymentSyncStatusPending,
    DateTime? nextAttemptAt,
    this.lastAttemptAt,
    this.lastErrorClass,
    this.lastErrorCode,
    this.terminalReason,
    this.terminalAt,
    DateTime? cycleDueDate,
    String? idempotencyKey,
  })  : nextAttemptAt = nextAttemptAt ?? createdAt,
        cycleDueDate = cycleDueDate ?? createdAt,
        idempotencyKey = idempotencyKey ?? id;

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

  @HiveField(9)
  final String status;

  @HiveField(10)
  final DateTime nextAttemptAt;

  @HiveField(11)
  final DateTime? lastAttemptAt;

  @HiveField(12)
  final String? lastErrorClass;

  @HiveField(13)
  final String? lastErrorCode;

  @HiveField(14)
  final String? terminalReason;

  @HiveField(15)
  final DateTime? terminalAt;

  @HiveField(16)
  final DateTime cycleDueDate;

  @HiveField(17)
  final String idempotencyKey;

  bool get isPending => status == paymentSyncStatusPending;
  bool get isProcessing => status == paymentSyncStatusProcessing;
  bool get isTerminal => status == paymentSyncStatusTerminal;

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
    String? status,
    DateTime? nextAttemptAt,
    DateTime? lastAttemptAt,
    String? lastErrorClass,
    String? lastErrorCode,
    String? terminalReason,
    DateTime? terminalAt,
    DateTime? cycleDueDate,
    String? idempotencyKey,
    bool clearErrorMetadata = false,
    bool clearTerminalMetadata = false,
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
      status: status ?? this.status,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastErrorClass:
          clearErrorMetadata ? null : (lastErrorClass ?? this.lastErrorClass),
      lastErrorCode:
          clearErrorMetadata ? null : (lastErrorCode ?? this.lastErrorCode),
      terminalReason: clearTerminalMetadata
          ? null
          : (terminalReason ?? this.terminalReason),
      terminalAt:
          clearTerminalMetadata ? null : (terminalAt ?? this.terminalAt),
      cycleDueDate: cycleDueDate ?? this.cycleDueDate,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }
}

/// Service for managing payment sync queue with Hive
class PaymentSyncQueueService {
  static const String _boxName = 'payment_sync_queue';

  Box<PaymentSyncOperation> get _box =>
      Hive.box<PaymentSyncOperation>(_boxName);

  /// Initialize the sync queue service
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await HiveService.openBox<PaymentSyncOperation>(
        _boxName,
        encrypted: true,
      );
    }
    debugPrint('🔄 [PaymentSyncQueue] Service initialized');
  }

  /// Enqueue a payment operation for sync
  Future<void> enqueue(PaymentSyncOperation operation) async {
    try {
      HiveService.ensureWritesAllowed('Payment sync queue enqueue');
      final queuedOperation = operation.copyWith(
        status: paymentSyncStatusPending,
        nextAttemptAt: operation.nextAttemptAt,
        clearTerminalMetadata: true,
      );
      await _box.put(queuedOperation.id, queuedOperation);
      debugPrint(
        '➕ [PaymentSyncQueue] Enqueued operation: ${queuedOperation.id} (action: ${queuedOperation.action})',
      );
      debugPrint('   📊 Queue size: ${_box.length}');
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to enqueue operation: $e');
      rethrow;
    }
  }

  /// Get pending operations ordered by creation time and filtered by schedule.
  Future<List<PaymentSyncOperation>> getPendingOrdered({
    DateTime? asOf,
  }) async {
    try {
      final now = asOf ?? DateTime.now();
      final operations = _box.values
          .where(
            (operation) =>
                operation.isPending && !operation.nextAttemptAt.isAfter(now),
          )
          .toList()
        ..sort((a, b) {
          final createdAtComparison = a.createdAt.compareTo(b.createdAt);
          if (createdAtComparison != 0) {
            return createdAtComparison;
          }
          return a.id.compareTo(b.id);
        });
      debugPrint(
        '🔍 [PaymentSyncQueue] Retrieved ${operations.length} pending operations',
      );
      return operations;
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to get pending operations: $e');
      return [];
    }
  }

  /// Backward-compatible alias for pending reads.
  Future<List<PaymentSyncOperation>> getPending() async {
    return getPendingOrdered();
  }

  /// Get all terminal operations ordered by creation time.
  Future<List<PaymentSyncOperation>> getTerminal() async {
    try {
      final terminalOperations =
          _box.values.where((operation) => operation.isTerminal).toList()
            ..sort((a, b) {
              final createdAtComparison = a.createdAt.compareTo(b.createdAt);
              if (createdAtComparison != 0) {
                return createdAtComparison;
              }
              return a.id.compareTo(b.id);
            });
      return terminalOperations;
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to get terminal operations: $e');
      return [];
    }
  }

  /// Mark operation as currently being processed.
  Future<void> markProcessing(
    String operationId, {
    DateTime? attemptedAt,
  }) async {
    try {
      HiveService.ensureWritesAllowed('Payment sync queue mark processing');
      final operation = _box.get(operationId);
      if (operation == null) {
        return;
      }

      final now = attemptedAt ?? DateTime.now();
      final updated = operation.copyWith(
        status: paymentSyncStatusProcessing,
        lastAttemptAt: now,
        clearTerminalMetadata: true,
      );
      await _box.put(operationId, updated);
    } catch (e) {
      debugPrint(
          '❌ [PaymentSyncQueue] Failed to mark operation processing: $e');
      rethrow;
    }
  }

  /// Mark an operation as synced (remove from queue)
  Future<void> markSynced(String operationId) async {
    try {
      HiveService.ensureWritesAllowed('Payment sync queue mark synced');
      await _box.delete(operationId);
      debugPrint(
          '✅ [PaymentSyncQueue] Operation marked as synced: $operationId');
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
      if (operation == null) {
        return;
      }

      await scheduleRetry(
        operationId,
        retryCount: operation.retryCount + 1,
        nextAttemptAt: DateTime.now(),
        lastAttemptAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to increment retry count: $e');
      rethrow;
    }
  }

  /// Schedule an operation for a new retry attempt.
  Future<void> scheduleRetry(
    String operationId, {
    required int retryCount,
    required DateTime nextAttemptAt,
    DateTime? lastAttemptAt,
    String? lastErrorClass,
    String? lastErrorCode,
  }) async {
    try {
      HiveService.ensureWritesAllowed('Payment sync queue schedule retry');
      final operation = _box.get(operationId);
      if (operation == null) {
        return;
      }

      final updated = operation.copyWith(
        status: paymentSyncStatusPending,
        retryCount: retryCount,
        nextAttemptAt: nextAttemptAt,
        lastAttemptAt: lastAttemptAt,
        lastErrorClass: lastErrorClass,
        lastErrorCode: lastErrorCode,
        clearTerminalMetadata: true,
      );
      await _box.put(operationId, updated);
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to schedule retry: $e');
      rethrow;
    }
  }

  /// Mark operation as terminal and keep it available for manual recovery.
  Future<void> markTerminal(
    String operationId, {
    required int retryCount,
    required String terminalReason,
    DateTime? terminalAt,
    DateTime? lastAttemptAt,
    String? lastErrorClass,
    String? lastErrorCode,
  }) async {
    try {
      HiveService.ensureWritesAllowed('Payment sync queue mark terminal');
      final operation = _box.get(operationId);
      if (operation == null) {
        return;
      }

      final updated = operation.copyWith(
        status: paymentSyncStatusTerminal,
        retryCount: retryCount,
        terminalReason: terminalReason,
        terminalAt: terminalAt ?? DateTime.now(),
        lastAttemptAt: lastAttemptAt ?? DateTime.now(),
        lastErrorClass: lastErrorClass,
        lastErrorCode: lastErrorCode,
      );
      await _box.put(operationId, updated);
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to mark operation terminal: $e');
      rethrow;
    }
  }

  /// Move terminal operations back to pending state for manual retry actions.
  Future<int> retryTerminal({DateTime? retryAt}) async {
    try {
      HiveService.ensureWritesAllowed('Payment sync queue retry terminal');
      final nextAttemptAt = retryAt ?? DateTime.now();
      final terminalOperations =
          _box.values.where((operation) => operation.isTerminal).toList();

      for (final operation in terminalOperations) {
        final updated = operation.copyWith(
          status: paymentSyncStatusPending,
          retryCount: 0,
          nextAttemptAt: nextAttemptAt,
          clearErrorMetadata: true,
          clearTerminalMetadata: true,
        );
        await _box.put(operation.id, updated);
      }

      return terminalOperations.length;
    } catch (e) {
      debugPrint(
          '❌ [PaymentSyncQueue] Failed to retry terminal operations: $e');
      rethrow;
    }
  }

  /// Clear only terminal operations while preserving active pending/processing.
  Future<int> clearTerminalOnly() async {
    try {
      HiveService.ensureWritesAllowed('Payment sync queue clear terminal only');
      final terminalKeys = _box.values
          .where((operation) => operation.isTerminal)
          .map((operation) => operation.id)
          .toList();
      await _box.deleteAll(terminalKeys);
      return terminalKeys.length;
    } catch (e) {
      debugPrint(
          '❌ [PaymentSyncQueue] Failed to clear terminal operations: $e');
      rethrow;
    }
  }

  /// Clear all pending operations (use with caution!)
  Future<void> clearAll() async {
    try {
      HiveService.ensureWritesAllowed('Payment sync queue clear');
      final count = _box.length;
      await _box.clear();
      debugPrint(
          '🗑️ [PaymentSyncQueue] Cleared all operations (removed $count)');
    } catch (e) {
      debugPrint('❌ [PaymentSyncQueue] Failed to clear queue: $e');
      rethrow;
    }
  }

  /// Check if there are pending operations
  bool get hasPending => _box.values
      .any((operation) => operation.status == paymentSyncStatusPending);

  /// Get count of pending operations
  int get pendingCount => _box.values
      .where((operation) => operation.status == paymentSyncStatusPending)
      .length;

  /// Get count of terminal operations
  int get terminalCount => _box.values
      .where((operation) => operation.status == paymentSyncStatusTerminal)
      .length;
}
