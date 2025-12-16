import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/create_subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:uuid/uuid.dart';

part 'create_subscription_form_provider.g.dart';

/// Form state for creating a subscription
class CreateSubscriptionFormState {
  final String name;
  final String cost;
  final BillingCycle billingCycle;
  final DateTime dueDate;
  final String color;
  final String iconUrl;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  CreateSubscriptionFormState({
    this.name = '',
    this.cost = '',
    this.billingCycle = BillingCycle.monthly,
    DateTime? dueDate,
    this.color = '#6C63FF',
    this.iconUrl = '',
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  }) : dueDate = dueDate ?? DateTime.now().add(const Duration(days: 30));

  CreateSubscriptionFormState copyWith({
    String? name,
    String? cost,
    BillingCycle? billingCycle,
    DateTime? dueDate,
    String? color,
    String? iconUrl,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return CreateSubscriptionFormState(
      name: name ?? this.name,
      cost: cost ?? this.cost,
      billingCycle: billingCycle ?? this.billingCycle,
      dueDate: dueDate ?? this.dueDate,
      color: color ?? this.color,
      iconUrl: iconUrl ?? this.iconUrl,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  /// Validate form fields
  String? validate() {
    if (name.trim().isEmpty) {
      return 'Subscription name is required';
    }

    if (name.trim().length < 2) {
      return 'Subscription name must be at least 2 characters';
    }

    if (cost.trim().isEmpty) {
      return 'Cost is required';
    }

    final parsedCost = double.tryParse(cost);
    if (parsedCost == null) {
      return 'Invalid cost format';
    }

    if (parsedCost <= 0) {
      return 'Cost must be greater than zero';
    }

    if (dueDate.isBefore(DateTime.now())) {
      return 'Due date cannot be in the past';
    }

    // Validate hex color format
    final colorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (!colorRegex.hasMatch(color)) {
      return 'Invalid color format';
    }

    return null;
  }

  /// Check if form is valid
  bool get isValid => validate() == null;
}

/// Provider for create subscription form state
@riverpod
class CreateSubscriptionForm extends _$CreateSubscriptionForm {
  @override
  CreateSubscriptionFormState build() {
    return CreateSubscriptionFormState();
  }

  /// Update name field
  void updateName(String name) {
    state = state.copyWith(name: name, errorMessage: null);
  }

  /// Update cost field
  void updateCost(String cost) {
    state = state.copyWith(cost: cost, errorMessage: null);
  }

  /// Update billing cycle
  void updateBillingCycle(BillingCycle cycle) {
    state = state.copyWith(billingCycle: cycle, errorMessage: null);
  }

  /// Update due date
  void updateDueDate(DateTime date) {
    state = state.copyWith(dueDate: date, errorMessage: null);
  }

  /// Update color
  void updateColor(String color) {
    state = state.copyWith(color: color, errorMessage: null);
  }

  /// Update icon URL
  void updateIconUrl(String url) {
    state = state.copyWith(iconUrl: url, errorMessage: null);
  }

  /// Reset form to initial state
  void reset() {
    state = CreateSubscriptionFormState();
  }

  /// Submit the form
  Future<void> submit() async {
    // Validate form
    final validationError = state.validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    // Set loading state
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Get current user ID from auth provider
      final authState = ref.read(authProvider);
      final userId = authState.maybeWhen(
        authenticated: (user) => user.id,
        orElse: () => null,
      );

      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not authenticated',
        );
        return;
      }

      // Parse cost
      final parsedCost = double.parse(state.cost);

      // Create subscription entity
      final subscription = Subscription(
        id: const Uuid().v4(), // Generate UUID
        name: state.name.trim(),
        iconUrl: state.iconUrl.trim().isEmpty ? null : state.iconUrl.trim(),
        color: state.color,
        totalCost: parsedCost,
        billingCycle: state.billingCycle,
        dueDate: state.dueDate,
        ownerId: userId,
        sharedWith: const [], // No members initially
        status: SubscriptionStatus.active,
        createdAt: DateTime.now(),
      );

      // Call use case
      final createSubscription = ref.read(createSubscriptionProvider);
      final result = await createSubscription(subscription);

      result.fold(
        (failure) {
          // Handle failure
          final errorMsg = failure.maybeWhen(
            serverError: (message) => message ?? 'Server error occurred',
            networkError: () => 'Network error. Please check your connection.',
            cacheError: (message) => message ?? 'Cache error occurred',
            notFound: () => 'Subscription not found',
            invalidData: (message) => message ?? 'Invalid data',
            paymentError: (message) => message ?? 'Payment error',
            memberError: (message) => message ?? 'Member error',
            orElse: () => 'An error occurred',
          );
          state = state.copyWith(
            isLoading: false,
            errorMessage: errorMsg,
          );
        },
        (createdSubscription) {
          // Success - invalidate providers to refresh data
          ref.invalidate(monthlyStatsProvider);
          ref.invalidate(activeSubscriptionsProvider);

          state = state.copyWith(
            isLoading: false,
            isSuccess: true,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: ${e.toString()}',
      );
    }
  }
}

// Note: Removed allSubscriptionsProvider - not needed
// The activeSubscriptionsProvider handles updates
