// lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/predefined_services.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member_input.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscription_detail_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'create_group_subscription_form_provider.g.dart';

/// Helper class for member split breakdown
class MemberSplit {
  final String name;
  final double amount;

  const MemberSplit({
    required this.name,
    required this.amount,
  });
}

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
    this.members = const [], // ✅ Empty list by default, no hardcoded members
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

  /// Total members (members list + owner)
  int get totalMembers => members.length + 1;

  /// Split amount per person
  double get splitAmount {
    if (totalMembers == 0 || totalPrice.isEmpty) return 0.0;
    final parsedPrice = double.tryParse(totalPrice) ?? 0.0;
    return parsedPrice / totalMembers;
  }

  /// Breakdown with proper rounding
  List<MemberSplit> get breakdown {
    if (totalPrice.isEmpty || members.isEmpty) return [];

    final parsedPrice = double.tryParse(totalPrice) ?? 0.0;
    if (parsedPrice == 0) return [];

    // Floor amount for each member
    final floorAmount = (splitAmount * 100).floor() / 100;

    // Calculate remainder for the owner
    final remainder = parsedPrice - (floorAmount * members.length);

    return [
      // Members get floor amount
      ...members.map((m) => MemberSplit(
        name: m.name,
        amount: floorAmount,
      )),
      // Owner gets the remainder
      MemberSplit(
        name: 'You',
        amount: remainder,
      ),
    ];
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

    // ✅ Validate members
    if (members.isEmpty) {
      return 'Add at least one member to create a group subscription';
    }

    // Validate each member has valid email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    for (final member in members) {
      if (!emailRegex.hasMatch(member.email)) {
        return 'Invalid email for member: ${member.name}';
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
  // Edit mode tracking fields
  Subscription? _originalSubscription;
  List<SubscriptionMember> _originalMembers = [];

  @override
  CreateGroupSubscriptionFormState build() {
    print('🏗️ [CreateGroupSubscriptionForm] Initializing with empty members list');
    return CreateGroupSubscriptionFormState(); // ✅ No hardcoded members
  }

  /// Update service name
  void updateServiceName(String name) {
    print('📝 [CreateGroupSubscriptionForm] Updating service name: $name');
    state = state.copyWith(serviceName: name, clearError: true);
  }

  /// Select a predefined service icon
  void selectServiceIcon(String serviceName) {
    print('🎨 [CreateGroupSubscriptionForm] Selecting service icon: $serviceName');
    state = state.copyWith(
      selectedServiceIcon: serviceName,
      serviceName: serviceName == 'Custom' ? '' : serviceName,
      clearError: true,
    );
  }

  /// Update total price
  void updateTotalPrice(String price) {
    print('💰 [CreateGroupSubscriptionForm] Updating price: \$$price');
    state = state.copyWith(totalPrice: price, clearError: true);

    // Log new split amount if members exist
    if (state.members.isNotEmpty) {
      print('   📊 New split: \$${state.splitAmount.toStringAsFixed(2)} per person');
    }
  }

  /// Update billing cycle
  void updateBillingCycle(BillingCycle cycle) {
    print('🔄 [CreateGroupSubscriptionForm] Updating billing cycle: $cycle');
    state = state.copyWith(billingCycle: cycle, clearError: true);
  }

  /// Update renewal date
  void updateRenewalDate(DateTime date) {
    print('📅 [CreateGroupSubscriptionForm] Updating renewal date: ${date.toIso8601String()}');
    state = state.copyWith(renewalDate: date, clearError: true);
  }

  /// Add a member to the subscription
  void addMember(SubscriptionMemberInput member) {
    print('➕ [CreateGroupSubscriptionForm] Adding member: ${member.name} (${member.email})');

    // ✅ Validate that email doesn't exist already
    final emailExists = state.members.any((m) => m.email == member.email);
    if (emailExists) {
      print('⚠️ [CreateGroupSubscriptionForm] Email already exists: ${member.email}');
      state = state.copyWith(errorMessage: 'This email is already in the group');
      return;
    }

    final updatedMembers = [...state.members, member];
    state = state.copyWith(
      members: updatedMembers,
      clearError: true,
    );

    print('✅ [CreateGroupSubscriptionForm] Member added. Total members: ${updatedMembers.length}');
    print('💰 [CreateGroupSubscriptionForm] New split: \$${state.splitAmount.toStringAsFixed(2)} per person');
  }

  /// Remove a member from the subscription
  void removeMember(String memberId) {
    print('➖ [CreateGroupSubscriptionForm] Removing member: $memberId');

    final updatedMembers = state.members
        .where((member) => member.id != memberId)
        .toList();

    state = state.copyWith(
      members: updatedMembers,
      clearError: true,
    );

    print('✅ [CreateGroupSubscriptionForm] Member removed. Total members: ${updatedMembers.length}');

    if (updatedMembers.isEmpty) {
      print('⚠️ [CreateGroupSubscriptionForm] No members left in group');
    } else {
      print('💰 [CreateGroupSubscriptionForm] New split: \$${state.splitAmount.toStringAsFixed(2)} per person');
    }
  }

  /// Update a member in the subscription
  void updateMember(String memberId, SubscriptionMemberInput updatedMember) {
    print('✏️ [CreateGroupSubscriptionForm] Updating member: $memberId');

    final updatedMembers = state.members.map((member) {
      return member.id == memberId ? updatedMember : member;
    }).toList();

    state = state.copyWith(members: updatedMembers, clearError: true);
    print('✅ [CreateGroupSubscriptionForm] Member updated');
  }

  /// Clear error message
  void clearError() {
    if (state.errorMessage != null) {
      print('🧹 [CreateGroupSubscriptionForm] Clearing error message');
      state = state.copyWith(clearError: true);
    }
  }

  /// Reset form to initial state
  void reset() {
    print('🔄 [CreateGroupSubscriptionForm] Resetting form to initial state');
    state = CreateGroupSubscriptionFormState();
  }

  /// Initialize form with existing subscription data (Edit Mode)
  void initializeWithSubscription(
    Subscription subscription,
    List<SubscriptionMember> members,
  ) {
    print('📝 [CreateGroupSubscriptionForm] Initializing with existing subscription');
    print('   ID: ${subscription.id}');
    print('   Name: ${subscription.name}');
    print('   Members: ${members.length}');

    _originalSubscription = subscription;
    _originalMembers = members;

    // Extract service icon from subscription (if matches predefined)
    String? selectedIcon;
    for (final service in PredefinedServices.services) {
      if (service.name.toLowerCase() == subscription.name.toLowerCase()) {
        selectedIcon = service.name;
        break;
      }
    }

    state = CreateGroupSubscriptionFormState(
      serviceName: subscription.name,
      selectedServiceIcon: selectedIcon,
      totalPrice: subscription.totalCost.toString(),
      billingCycle: subscription.billingCycle,
      renewalDate: subscription.dueDate,
      members: members.map((m) => SubscriptionMemberInput.fromMember(m)).toList(),
    );

    print('✅ [CreateGroupSubscriptionForm] Initialized with ${state.members.length} members');
  }

  /// Submit the form (create or update depending on subscriptionId)
  Future<void> submit([String? subscriptionId]) async {
    if (subscriptionId == null) {
      // CREATE mode
      await _createSubscription();
    } else {
      // EDIT mode
      await _updateSubscription(subscriptionId);
    }
  }

  /// Create new subscription (original logic)
  Future<void> _createSubscription() async {
    print('📤 [CreateGroupSubscriptionForm] Creating new subscription...');
    print('   Service: ${state.serviceName}');
    print('   Price: \$${state.totalPrice}');
    print('   Members: ${state.members.length}');

    // Validate form
    final validationError = state.validate();
    if (validationError != null) {
      print('❌ [CreateGroupSubscriptionForm] Validation failed: $validationError');
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    print('✅ [CreateGroupSubscriptionForm] Validation passed');

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
        print('❌ [CreateGroupSubscriptionForm] User not authenticated');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not authenticated',
        );
        return;
      }

      print('👤 [CreateGroupSubscriptionForm] Current user: ${currentUser.id}');

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

      print('🔨 [CreateGroupSubscriptionForm] Creating subscription...');

      // Call use case to create subscription
      final createSubscription = ref.read(createSubscriptionProvider);
      final result = await createSubscription(subscription);

      await result.fold(
        (failure) async {
          // Handle failure
          print('❌ [CreateGroupSubscriptionForm] Failed to create subscription: $failure');
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
          print('✅ [CreateGroupSubscriptionForm] Subscription created: ${createdSubscription.id}');
          print('👥 [CreateGroupSubscriptionForm] Adding ${state.members.length} members...');

          // Add members to the subscription
          final repository = ref.read(subscriptionRepositoryProvider);
          int successCount = 0;
          int failCount = 0;

          for (final memberInput in state.members) {
            print('   ➕ Adding member: ${memberInput.name} (${memberInput.email})');

            final result = await repository.addMemberToSubscription(
              subscriptionId: createdSubscription.id,
              userId: memberInput.id,
              userName: memberInput.name,
              userEmail: memberInput.email,
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

          print('📊 [CreateGroupSubscriptionForm] Members added: $successCount success, $failCount failed');

          // Success - invalidate providers to refresh data
          print('🔄 [CreateGroupSubscriptionForm] Invalidating providers...');
          ref.invalidate(monthlyStatsProvider);
          ref.invalidate(activeSubscriptionsProvider);

          state = state.copyWith(
            isLoading: false,
            isSuccess: true,
            clearError: true,
          );

          print('✅ [CreateGroupSubscriptionForm] Group subscription created successfully!');
          print('📊 [CreateGroupSubscriptionForm] Breakdown:');
          for (final split in state.breakdown) {
            print('   ${split.name}: \$${split.amount.toStringAsFixed(2)}');
          }
        },
      );
    } catch (e, stackTrace) {
      print('❌ [CreateGroupSubscriptionForm] Unexpected error: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Update existing subscription (Edit Mode)
  Future<void> _updateSubscription(String subscriptionId) async {
    print('📝 [CreateGroupSubscriptionForm] Updating subscription: $subscriptionId');

    // Validate form
    final validationError = state.validate();
    if (validationError != null) {
      print('❌ [CreateGroupSubscriptionForm] Validation failed: $validationError');
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    // Detect changes
    final priceChanged = _originalSubscription!.totalCost != double.parse(state.totalPrice);
    final membersChanges = _detectMembersChanges();
    final membersChanged = membersChanges.added || membersChanges.removed;

    print('   Price changed: $priceChanged');
    print('   Members changed: $membersChanged (added: ${membersChanges.added}, removed: ${membersChanges.removed})');

    // Check if there are any changes
    if (!_hasChanges()) {
      print('⚠️ [CreateGroupSubscriptionForm] No changes detected');
      state = state.copyWith(errorMessage: 'No changes detected');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Get current user
      final authState = ref.read(authProvider);
      final currentUser = authState.maybeWhen(
        authenticated: (user) => user,
        orElse: () => null,
      );

      if (currentUser == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'User not authenticated');
        return;
      }

      // Update subscription entity
      final updatedSubscription = _originalSubscription!.copyWith(
        name: state.serviceName.trim(),
        color: state.subscriptionColor,
        totalCost: double.parse(state.totalPrice),
        billingCycle: state.billingCycle,
        dueDate: state.renewalDate,
      );

      print('🔄 [CreateGroupSubscriptionForm] Updating subscription...');
      final updateSubscription = ref.read(updateSubscriptionProvider);
      final updateResult = await updateSubscription(updatedSubscription);

      await updateResult.fold(
        (failure) async {
          print('❌ [CreateGroupSubscriptionForm] Failed to update: $failure');
          final errorMsg = failure.maybeWhen(
            serverError: (message) => message,
            networkError: () => 'Network error. Please check your connection.',
            invalidData: (message) => message,
            orElse: () => 'An error occurred',
          );
          state = state.copyWith(isLoading: false, errorMessage: errorMsg);
        },
        (updated) async {
          print('✅ [CreateGroupSubscriptionForm] Subscription updated');

          // Handle members updates if price or members changed
          if (priceChanged || membersChanged) {
            await _handleMembersUpdate(
              subscriptionId: subscriptionId,
              priceChanged: priceChanged,
              membersChanged: membersChanged,
            );
          }

          // Invalidate providers to refresh data
          print('🔄 [CreateGroupSubscriptionForm] Invalidating providers...');
          ref.invalidate(subscriptionDetailProvider(subscriptionId));
          ref.invalidate(subscriptionMembersProvider(subscriptionId));
          ref.invalidate(monthlyStatsProvider);
          ref.invalidate(activeSubscriptionsProvider);

          state = state.copyWith(isLoading: false, isSuccess: true, clearError: true);
          print('✅ [CreateGroupSubscriptionForm] Update completed successfully!');
        },
      );
    } catch (e, stackTrace) {
      print('❌ [CreateGroupSubscriptionForm] Unexpected error: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Detect changes in members (added/removed)
  ({bool added, bool removed}) _detectMembersChanges() {
    final currentEmails = state.members.map((m) => m.email.toLowerCase()).toSet();
    final originalEmails = _originalMembers.map((m) => m.userEmail.toLowerCase()).toSet();

    return (
      added: currentEmails.difference(originalEmails).isNotEmpty,
      removed: originalEmails.difference(currentEmails).isNotEmpty,
    );
  }

  /// Check if there are any changes from original
  bool _hasChanges() {
    if (_originalSubscription == null) return true; // Create mode

    final metadataChanged =
        _originalSubscription!.name != state.serviceName ||
        _originalSubscription!.color != state.subscriptionColor ||
        _originalSubscription!.totalCost != double.tryParse(state.totalPrice) ||
        _originalSubscription!.billingCycle != state.billingCycle ||
        _originalSubscription!.dueDate != state.renewalDate;

    final membersChanges = _detectMembersChanges();
    return metadataChanged || membersChanges.added || membersChanges.removed;
  }

  /// Handle members update (add/remove/recalculate)
  Future<void> _handleMembersUpdate({
    required String subscriptionId,
    required bool priceChanged,
    required bool membersChanged,
  }) async {
    print('👥 [CreateGroupSubscriptionForm] Handling members update...');
    final repository = ref.read(subscriptionRepositoryProvider);

    // Calculate new split
    final totalPrice = double.parse(state.totalPrice);
    final totalMembers = state.members.length + 1; // +1 for owner
    final splitAmount = totalPrice / totalMembers;
    final floorAmount = (splitAmount * 100).floor() / 100;

    print('   New split: \$${floorAmount.toStringAsFixed(2)} per person');

    if (membersChanged) {
      print('   Members changed - recalculating all...');

      // Remove deleted members
      final removedMembers = _originalMembers.where(
        (om) => !state.members.any((sm) => sm.email.toLowerCase() == om.userEmail.toLowerCase()),
      );

      for (final member in removedMembers) {
        print('   ➖ Removing member: ${member.userName}');
        await repository.removeMemberFromSubscription(member.id);
      }

      // Add new members
      final addedMembers = state.members.where(
        (sm) => !_originalMembers.any((om) => om.userEmail.toLowerCase() == sm.email.toLowerCase()),
      );

      for (final member in addedMembers) {
        print('   ➕ Adding member: ${member.name}');
        await repository.addMemberToSubscription(
          subscriptionId: subscriptionId,
          userId: member.id,
          userName: member.name,
          userEmail: member.email,
          userAvatar: member.avatar,
        );
      }

      // Update existing members with new amount and reset payment
      final remainingMembers = _originalMembers.where(
        (om) => state.members.any((sm) => sm.email.toLowerCase() == om.userEmail.toLowerCase()),
      );

      for (final member in remainingMembers) {
        print('   🔄 Updating member: ${member.userName} (reset payment)');
        await repository.updateMemberAmount(
          memberId: member.id,
          newAmountToPay: floorAmount,
          resetPayment: true, // Reset has_paid to false
        );
      }
    } else if (priceChanged) {
      print('   Only price changed - updating amounts...');

      // Update all existing members with new amount (keep has_paid)
      for (final member in _originalMembers) {
        print('   🔄 Updating member: ${member.userName} (keep payment status)');
        await repository.updateMemberAmount(
          memberId: member.id,
          newAmountToPay: floorAmount,
          resetPayment: false, // Keep has_paid as is
        );
      }
    }

    print('✅ [CreateGroupSubscriptionForm] Members update completed');
  }
}
