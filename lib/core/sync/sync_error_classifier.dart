import 'dart:async';
import 'dart:io';

import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_remote_datasource.dart';

enum SyncFailureDisposition { retryable, terminal }

class SyncErrorClassification {
  const SyncErrorClassification({
    required this.disposition,
    required this.errorClass,
    required this.terminalReason,
    this.errorCode,
  });

  final SyncFailureDisposition disposition;
  final String errorClass;
  final String terminalReason;
  final String? errorCode;

  bool get isRetryable => disposition == SyncFailureDisposition.retryable;
}

class SyncErrorClassifier {
  const SyncErrorClassifier();

  SyncErrorClassification classify(
    Object error, {
    StackTrace? stackTrace,
  }) {
    if (error is TimeoutException) {
      return const SyncErrorClassification(
        disposition: SyncFailureDisposition.retryable,
        errorClass: 'network',
        errorCode: 'timeout',
        terminalReason: 'timeout',
      );
    }

    if (error is SocketException || error is HttpException) {
      return const SyncErrorClassification(
        disposition: SyncFailureDisposition.retryable,
        errorClass: 'network',
        errorCode: 'connectivity',
        terminalReason: 'connectivity',
      );
    }

    if (error is SubscriptionRemoteException) {
      final normalizedMessage = error.message.toLowerCase();
      final extractedCode = _extractErrorCode(normalizedMessage);

      if (_isRetryableRemoteMessage(normalizedMessage)) {
        return SyncErrorClassification(
          disposition: SyncFailureDisposition.retryable,
          errorClass: 'remote_transient',
          errorCode: extractedCode,
          terminalReason: 'transient_remote_failure',
        );
      }

      return SyncErrorClassification(
        disposition: SyncFailureDisposition.terminal,
        errorClass: 'remote_terminal',
        errorCode: extractedCode,
        terminalReason: 'non_retryable_remote_failure',
      );
    }

    final fallbackCode = _extractErrorCode(error.toString().toLowerCase());
    return SyncErrorClassification(
      disposition: SyncFailureDisposition.terminal,
      errorClass: 'unknown',
      errorCode: fallbackCode,
      terminalReason: 'unexpected_error',
    );
  }

  bool _isRetryableRemoteMessage(String message) {
    final statusMatches = RegExp(r'\b([45]\d{2})\b')
        .allMatches(message)
        .map((match) => match.group(1))
        .whereType<String>()
        .toSet();
    const retryableStatuses = <String>{
      '408',
      '429',
      '500',
      '502',
      '503',
      '504'
    };
    if (statusMatches.any(retryableStatuses.contains)) {
      return true;
    }

    const retryableFragments = <String>[
      'timeout',
      'timed out',
      'network',
      'connection',
      'temporarily',
      '5xx',
      'unavailable',
      'too many requests',
      'retry',
    ];

    for (final fragment in retryableFragments) {
      if (message.contains(fragment)) {
        return true;
      }
    }
    return false;
  }

  String? _extractErrorCode(String message) {
    final codeMatch = RegExp(r'code[:=\s]+([a-z0-9_]+)').firstMatch(message);
    if (codeMatch != null) {
      return codeMatch.group(1);
    }

    final statusMatch = RegExp(r'\b([45]\d{2})\b').firstMatch(message);
    if (statusMatch != null) {
      return statusMatch.group(1);
    }

    return null;
  }
}
