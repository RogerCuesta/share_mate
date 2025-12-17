// lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/predefined_services.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member_input.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'create_group_subscription_form_provider.g.dart';

/// Form state for creating a group subscription
class CreateGroupSubscriptionFormState {
  final String serviceName;
  final String? selectedServiceIcon; // Name of predefined service
  final String totalPrice;
  final BillingCycle billingCycle;
  final DateTime renewalDate;
  final List<SubscriptionMemberInput> members;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  CreateGroupSubscriptionFormState({
    this.serviceName = '',
    this.selectedServiceIcon,
    this.totalPrice = '',
    this.billingCycle = BillingCycle.monthly,
    DateTime? renewalDate,
    this.members = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  }) : renewalDate = renewalDate ?? DateTime.now().add(const Duration(days: 30));

  CreateGroupSubscriptionFormState copyWith({
    String? serviceName,
    String? selectedServiceIcon,
    String? totalPrice,
    BillingCycle? billingCycle,
    DateTime? renewalDate,
    List<SubscriptionMemberInput>? members,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return CreateGroupSubscriptionFormState(
      serviceName: serviceName ?? this.serviceName,
      selectedServiceIcon: selectedServiceIcon ?? this.selectedServiceIcon,
      totalPrice: totalPrice ?? this.totalPrice,
      billingCycle: billingCycle ?? this.billingCycle,
      renewalDate: renewalDate ?? this.renewalDate,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  /// Get color for the subscription (from predefined service or default)
  String get subscriptionColor {
    if (selectedServiceIcon != null) {
      return PredefinedServices.getColorForService(selectedServiceIcon!);
    }
    return '#6C63FF'; // Default purple
  }

  /// Validate form fields
  String? validate() {
    // Validate service name
    if (serviceName.trim().isEmpty) {
      return 'Service name is required';
    }

    if (serviceName.trim().length < 2) {
      return 'Service name must be at least 2 characters';
    }

    // Validate price
    if (totalPrice.trim().isEmpty) {
      return 'Total price is required';
    }

    final parsedPrice = double.tryParse(totalPrice);
    if (parsedPrice == null) {
      return 'Invalid price format';
    }

    if (parsedPrice <= 0) {
      return 'Price must be greater than zero';
    }

    // Validate renewal date
    if (renewalDate.isBefore(DateTime.now())) {
      return 'Renewal date must be in the future';
    }

    // Validate members
    if (members.isEmpty) {
      return 'Add at least one member to create a group';
    }

    // Validate each member
    for (final member in members) {
      final memberError = member.validate();
      if (memberError != null) {
        return 'Member ${member.name}: $memberError';
      }
    }

    return null;
  }

  /// Check if form is valid
  bool get isValid => validate() == null;
}

/// Provider for create group subscription form state
@riverpod
class CreateGroupSubscriptionForm extends _$CreateGroupSubscriptionForm {
  @override
  CreateGroupSubscriptionFormState build() {
    return CreateGroupSubscriptionFormState();
  }

  /// Update service name
  void updateServiceName(String name) {
    state = state.copyWith(serviceName: name, clearError: true);
  }

  /// Select a predefined service icon
  void selectServiceIcon(String serviceName) {
    state = state.copyWith(
      selectedServiceIcon: serviceName,
      serviceName: serviceName == 'Custom' ? '' : serviceName,
      clearError: true,
    );
  }

  /// Update total price
  void updateTotalPrice(String price) {
    state = state.copyWith(totalPrice: price, clearError: true);
  }

  /// Update billing cycle
  void updateBillingCycle(BillingCycle cycle) {
    state = state.copyWith(billingCycle: cycle, clearError: true);
  }

  /// Update renewal date
  void updateRenewalDate(DateTime date) {
    state = state.copyWith(renewalDate: date, clearError: true);
  }

  /// Add a member to the subscription
  void addMember(SubscriptionMemberInput member) {
    final updatedMembers = [...state.members, member];
    state = state.copyWith(members: updatedMembers, clearError: true);
  }

  /// Remove a member from the subscription
  void removeMember(String memberId) {
    final updatedMembers = state.members
        .where((member) => member.id != memberId)
        .toList();
    state = state.copyWith(members: updatedMembers, clearError: true);
  }

  /// Update a member in the subscription
  void updateMember(String memberId, SubscriptionMemberInput updatedMember) {
    final updatedMembers = state.members.map((member) {
      return member.id == memberId ? updatedMember : member;
    }).toList();
    state = state.copyWith(members: updatedMembers, clearError: true);
  }

  /// Reset form to initial state
  void reset() {
    state = CreateGroupSubscriptionFormState();
  }

  /// Submit the form and create the group subscription
  Future<void> submit() async {
    // Validate form
    final validationError = state.validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    // Set loading state
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Get current user from auth provider
      final authState = ref.read(authProvider);
      final currentUser = authState.maybeWhen(
        authenticated: (user) => user,
        orElse: () => null,
      );

      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not authenticated',
        );
        return;
      }

      // Parse total price
      final parsedPrice = double.parse(state.totalPrice);

      // Create subscription entity
      final subscription = Subscription(
        id: const Uuid().v4(),
        name: state.serviceName.trim(),
        iconUrl: null, // TODO: Handle icon URLs for predefined services
        color: state.subscriptionColor,
        totalCost: parsedPrice,
        billingCycle: state.billingCycle,
        dueDate: state.renewalDate,
        ownerId: currentUser.id,
        sharedWith: state.members.map((m) => m.id).toList(),
        status: SubscriptionStatus.active,
        createdAt: DateTime.now(),
      );

      // Call use case to create subscription
      final createSubscription = ref.read(createSubscriptionProvider);
      final result = await createSubscription(subscription);

      await result.fold(
        (failure) async {
          // Handle failure
          print('❌ [CreateGroupForm] Failed to create subscription: $failure');
          final errorMsg = failure.maybeWhen(
            serverError: (message) => message,
            networkError: () => 'Network error. Please check your connection.',
            cacheError: (message) => message,
            notFound: () => 'Subscription not found',
            invalidData: (message) => message,
            paymentError: (message) => message,
            memberError: (message) => message,
            orElse: () => 'An error occurred',
          );
          state = state.copyWith(
            isLoading: false,
            errorMessage: errorMsg,
          );
        },
        (createdSubscription) async {
          print('✅ [CreateGroupForm] Subscription created: ${createdSubscription.id}');
          print('👥 [CreateGroupForm] Adding ${state.members.length} members...');

          // Calculate split amount
          final totalMembers = state.members.length + 1; // +1 for owner
          final splitAmount = parsedPrice / totalMembers;
          final floorAmount = (splitAmount * 100).floor() / 100;

          // Add members to the subscription
          final repository = ref.read(subscriptionRepositoryProvider);
          int successCount = 0;
          int failCount = 0;

          for (final memberInput in state.members) {
            print('   ➕ Adding member: ${memberInput.name} (${memberInput.email})');

            final result = await repository.addMemberToSubscription(
              subscriptionId: createdSubscription.id,
              userId: memberInput.id, // Using local ID as placeholder
              userName: memberInput.name,
              userAvatar: memberInput.avatar,
            );

            result.fold(
              (failure) {
                print('   ❌ Failed to add ${memberInput.name}: $failure');
                failCount++;
              },
              (addedMember) {
                print('   ✅ Added member: ${addedMember.userName} (\$${addedMember.amountToPay.toStringAsFixed(2)})');
                successCount++;
              },
            );
          }

          print('📊 [CreateGroupForm] Members added: $successCount success, $failCount failed');

          // Success - invalidate providers to refresh data
          print('🔄 [CreateGroupForm] Invalidating providers...');
          ref.invalidate(monthlyStatsProvider);
          ref.invalidate(activeSubscriptionsProvider);

          state = state.copyWith(
            isLoading: false,
            isSuccess: true,
            clearError: true,
          );

          print('✅ [CreateGroupForm] Group subscription created successfully!');
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
