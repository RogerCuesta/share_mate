// lib/core/sync/friend_request_sync_queue.dart

import 'package:hive_ce/hive.dart';

import '../storage/hive_type_ids.dart';

part 'friend_request_sync_queue.g.dart';

/// Sync operation types for friend requests
enum FriendRequestOperationType {
  send,
  accept,
  reject,
  remove,
}

/// Represents a friend request operation to be synced
@HiveType(typeId: HiveTypeIds.friendRequestSyncOperation)
class FriendRequestSyncOperation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String operationType; // 'send', 'accept', 'reject', 'remove'

  @HiveField(2)
  final String? friendshipId; // null for 'send', required for others

  @HiveField(3)
  final String? friendEmail; // required for 'send', null for others

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final int retryCount;

  @HiveField(6)
  final String? lastError;

  FriendRequestSyncOperation({
    required this.id,
    required this.operationType,
    this.friendshipId,
    this.friendEmail,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  FriendRequestSyncOperation copyWith({
    String? id,
    String? operationType,
    String? friendshipId,
    String? friendEmail,
    DateTime? createdAt,
    int? retryCount,
    String? lastError,
  }) {
    return FriendRequestSyncOperation(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      friendshipId: friendshipId ?? this.friendshipId,
      friendEmail: friendEmail ?? this.friendEmail,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Service for managing the friend request sync queue
class FriendRequestSyncQueueService {
  static const String _boxName = 'friend_request_sync_queue';
  static const int _maxRetries = 3;
  Box<FriendRequestSyncOperation>? _box;

  /// Initialize the Hive box
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<FriendRequestSyncOperation>(_boxName);
    } else {
      _box = Hive.box<FriendRequestSyncOperation>(_boxName);
    }
  }

  /// Ensure box is initialized
  Box<FriendRequestSyncOperation> get _ensureBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('FriendRequestSyncQueueService not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Enqueue a friend request operation
  Future<void> enqueue(FriendRequestSyncOperation operation) async {
    await _ensureBox.put(operation.id, operation);
  }

  /// Get all pending operations
  List<FriendRequestSyncOperation> getPending() {
    return _ensureBox.values
        .where((op) => op.retryCount < _maxRetries)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Mark operation as synced (remove from queue)
  Future<void> markSynced(String operationId) async {
    await _ensureBox.delete(operationId);
  }

  /// Increment retry count for failed operation
  Future<void> incrementRetry(String operationId, String error) async {
    final operation = _ensureBox.get(operationId);
    if (operation != null) {
      final updated = operation.copyWith(
        retryCount: operation.retryCount + 1,
        lastError: error,
      );
      await _ensureBox.put(operationId, updated);
    }
  }

  /// Clear all operations (for testing/reset)
  Future<void> clearAll() async {
    await _ensureBox.clear();
  }

  /// Get count of pending operations
  int get pendingCount {
    return getPending().length;
  }

  /// Check if operation exists
  bool hasOperation(String operationId) {
    return _ensureBox.containsKey(operationId);
  }

  /// Get failed operations (exceeded max retries)
  List<FriendRequestSyncOperation> getFailed() {
    return _ensureBox.values
        .where((op) => op.retryCount >= _maxRetries)
        .toList();
  }

  /// Remove failed operations
  Future<void> clearFailed() async {
    final failed = getFailed();
    for (final op in failed) {
      await _ensureBox.delete(op.id);
    }
  }
}
