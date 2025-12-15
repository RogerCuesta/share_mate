import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_failure.freezed.dart';

/// Failures that can occur in the subscriptions domain
@freezed
class SubscriptionFailure with _$SubscriptionFailure {
  /// Server error occurred
  const factory SubscriptionFailure.serverError(String message) = _ServerError;

  /// Network connection error
  const factory SubscriptionFailure.networkError() = _NetworkError;

  /// Storage/cache error
  const factory SubscriptionFailure.cacheError(String message) = _CacheError;

  /// Subscription not found
  const factory SubscriptionFailure.notFound() = _NotFound;

  /// User is not authorized to perform this action
  const factory SubscriptionFailure.unauthorized() = _Unauthorized;

  /// Invalid data provided
  const factory SubscriptionFailure.invalidData(String message) = _InvalidData;

  /// Subscription already exists
  const factory SubscriptionFailure.alreadyExists(String message) =
      _AlreadyExists;

  /// Payment operation failed
  const factory SubscriptionFailure.paymentError(String message) =
      _PaymentError;

  /// Member-related error
  const factory SubscriptionFailure.memberError(String message) = _MemberError;
}
