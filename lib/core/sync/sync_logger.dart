import 'dart:convert';

import 'package:flutter/foundation.dart';

class SyncLogger {
  const SyncLogger({required this.scope});

  final String scope;

  void logSync({
    required String event,
    String? operationId,
    String? actionType,
    int? retryCount,
    String? errorClass,
    String? errorCode,
    DateTime? occurredAt,
    Map<String, Object?> metadata = const {},
  }) {
    _log(
      level: 'INFO',
      event: event,
      operationId: operationId,
      actionType: actionType,
      retryCount: retryCount,
      errorClass: errorClass,
      errorCode: errorCode,
      occurredAt: occurredAt,
      metadata: metadata,
    );
  }

  void logRetry({
    required String event,
    required String operationId,
    required int retryCount,
    DateTime? occurredAt,
    Map<String, Object?> metadata = const {},
  }) {
    _log(
      level: 'WARN',
      event: event,
      operationId: operationId,
      retryCount: retryCount,
      occurredAt: occurredAt,
      metadata: metadata,
    );
  }

  void logTerminal({
    required String event,
    required String operationId,
    required String terminalReason,
    int? retryCount,
    String? errorClass,
    String? errorCode,
    DateTime? occurredAt,
    Map<String, Object?> metadata = const {},
  }) {
    final enrichedMetadata = <String, Object?>{
      ...metadata,
      'terminal_reason': terminalReason,
    };
    _log(
      level: 'ERROR',
      event: event,
      operationId: operationId,
      retryCount: retryCount,
      errorClass: errorClass,
      errorCode: errorCode,
      occurredAt: occurredAt,
      metadata: enrichedMetadata,
    );
  }

  @visibleForTesting
  Map<String, Object?> buildPayload({
    required String level,
    required String event,
    String? operationId,
    String? actionType,
    int? retryCount,
    String? errorClass,
    String? errorCode,
    DateTime? occurredAt,
    Map<String, Object?> metadata = const {},
  }) {
    final payload = <String, Object?>{
      'level': level,
      'scope': scope,
      'event': event,
      'timestamp': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
    };

    final operationHash = _hashIdentifier(operationId);
    if (operationHash != null) {
      payload['operation_hash'] = operationHash;
    }
    if (actionType != null && actionType.isNotEmpty) {
      payload['action_type'] = actionType;
    }
    if (retryCount != null) {
      payload['retry_count'] = retryCount;
    }
    if (errorClass != null && errorClass.isNotEmpty) {
      payload['error_class'] = errorClass;
    }
    if (errorCode != null && errorCode.isNotEmpty) {
      payload['error_code'] = errorCode;
    }

    final sanitizedMetadata = _sanitizeMetadata(metadata);
    if (sanitizedMetadata.isNotEmpty) {
      payload['metadata'] = sanitizedMetadata;
    }

    return payload;
  }

  void _log({
    required String level,
    required String event,
    String? operationId,
    String? actionType,
    int? retryCount,
    String? errorClass,
    String? errorCode,
    DateTime? occurredAt,
    Map<String, Object?> metadata = const {},
  }) {
    if (!kDebugMode) {
      return;
    }
    final payload = buildPayload(
      level: level,
      event: event,
      operationId: operationId,
      actionType: actionType,
      retryCount: retryCount,
      errorClass: errorClass,
      errorCode: errorCode,
      occurredAt: occurredAt,
      metadata: metadata,
    );
    debugPrint('[SyncLogger] ${jsonEncode(payload)}');
  }

  Map<String, Object?> _sanitizeMetadata(Map<String, Object?> metadata) {
    if (metadata.isEmpty) {
      return const {};
    }

    final sanitized = <String, Object?>{};
    for (final entry in metadata.entries) {
      if (!_isAllowedMetadataKey(entry.key)) {
        continue;
      }
      final value = _sanitizeValue(entry.value);
      if (value != null) {
        sanitized[entry.key] = value;
      }
    }
    return sanitized;
  }

  bool _isAllowedMetadataKey(String key) {
    const sensitiveHints = <String>[
      'amount',
      'note',
      'member',
      'email',
      'phone',
      'name',
      'payload',
      'raw',
      'body',
      'pii',
      'id',
    ];
    final normalizedKey = key.toLowerCase();
    for (final sensitiveHint in sensitiveHints) {
      if (normalizedKey.contains(sensitiveHint) &&
          normalizedKey != 'operation_id') {
        return false;
      }
    }
    return true;
  }

  Object? _sanitizeValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num || value is bool) {
      return value;
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is String) {
      return value.length > 120 ? value.substring(0, 120) : value;
    }
    return value.toString();
  }

  String? _hashIdentifier(String? input) {
    if (input == null || input.isEmpty) {
      return null;
    }

    const fnvOffset = 0xcbf29ce484222325;
    const fnvPrime = 0x100000001b3;
    const mask = 0xffffffffffffffff;

    var hash = fnvOffset;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
