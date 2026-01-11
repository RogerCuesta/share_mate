// lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscription_detail_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/billing_cycle_selector.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/members_list_section.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/service_icon_picker.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/split_bill_preview_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen for creating/editing a group subscription with split billing
class CreateGroupSubscriptionScreen extends ConsumerStatefulWidget {

  const CreateGroupSubscriptionScreen({
    this.subscriptionId,
    super.key,
  });
  /// Subscription ID - null for create mode, non-null for edit mode
  final String? subscriptionId;

  @override
  ConsumerState<CreateGroupSubscriptionScreen> createState() =>
      _CreateGroupSubscriptionScreenState();
}

class _CreateGroupSubscriptionScreenState
    extends ConsumerState<CreateGroupSubscriptionScreen> {
  final _serviceNameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load existing subscription in edit mode
    if (widget.subscriptionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingSubscription();
      });
    }

    // Listen for form state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(
        createGroupSubscriptionFormProvider,
        (previous, next) {
          debugPrint('📊 [CreateGroupSubscriptionScreen] State changed');
          debugPrint('   isSuccess: ${next.isSuccess}');
          debugPrint('   errorMessage: ${next.errorMessage}');

          final isEditMode = widget.subscriptionId != null;
          final successMessage = isEditMode
              ? 'Subscription updated successfully!'
              : 'Group subscription created successfully!';

          if (next.isSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            // Navigate back
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pop();
              }
            });
          } else if (next.errorMessage != null) {
            // Show error
            debugPrint('❌ [CreateGroupSubscriptionScreen] Showing error: ${next.errorMessage}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.errorMessage!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );
    });
  }

  /// Load existing subscription data for edit mode
  Future<void> _loadExistingSubscription() async {
    final subscriptionId = widget.subscriptionId!;

    try {
      debugPrint('📝 [CreateGroupSubscriptionScreen] Loading subscription: $subscriptionId');

      // Fetch subscription and members
      final subscription = await ref.read(subscriptionDetailProvider(subscriptionId).future);
      final members = await ref.read(subscriptionMembersProvider(subscriptionId).future);

      debugPrint('✅ [CreateGroupSubscriptionScreen] Loaded: ${subscription.name} with ${members.length} members');

      // Initialize form provider
      ref.read(createGroupSubscriptionFormProvider.notifier)
          .initializeWithSubscription(subscription, members);

      // Pre-fill text controllers
      _serviceNameController.text = subscription.name;
      _priceController.text = subscription.totalCost.toString();
    } catch (e) {
      debugPrint('❌ [CreateGroupSubscriptionScreen] Error loading subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    }
  }

  /// Show confirmation dialog before removing a member
  Future<void> _showRemoveMemberDialog(
    BuildContext context,
    String memberId,
    String memberName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Remove Member',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove $memberName from this subscription?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      debugPrint('🗑️ [CreateGroupSubscriptionScreen] Removing member: $memberName');
      ref.read(createGroupSubscriptionFormProvider.notifier).removeMember(memberId);
    }
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createGroupSubscriptionFormProvider);
    final formNotifier = ref.read(createGroupSubscriptionFormProvider.notifier);
    final isEditMode = widget.subscriptionId != null;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditMode ? 'Edit Subscription' : 'Add Subscription',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Icon Picker
              ServiceIconPicker(
                selectedService: formState.selectedServiceIcon,
                onServiceSelected: formNotifier.selectServiceIcon,
              ),
              const SizedBox(height: 24),

              // Service Name Field
              const Text(
                'Service Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _serviceNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter service name',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF2D2D44),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3D3D54),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C63FF),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: formNotifier.updateServiceName,
              ),
              const SizedBox(height: 24),

              // Total Price Field
              const Text(
                'Total Price',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: const TextStyle(color: Colors.white, fontSize: 24),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, top: 12),
                    child: Text(
                      r'$',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2D2D44),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3D3D54),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C63FF),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: formNotifier.updateTotalPrice,
              ),
              const SizedBox(height: 24),

              // Billing Cycle
              const Text(
                'Billing Cycle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              BillingSycleSelector(
                selectedCycle: formState.billingCycle,
                onCycleSelected: formNotifier.updateBillingCycle,
              ),
              const SizedBox(height: 24),

              // Renewal Date
              const Text(
                'Renewal Date',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: formState.renewalDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF6C63FF),
                            onPrimary: Colors.white,
                            surface: Color(0xFF2D2D44),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedDate != null) {
                    formNotifier.updateRenewalDate(pickedDate);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D44),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF3D3D54),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF6C63FF),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${formState.renewalDate.day}/${formState.renewalDate.month}/${formState.renewalDate.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Members Section - Connected to provider
              MembersListSection(
                members: formState.members,
                onMemberAdded: formNotifier.addMember,
                onMemberRemoved: (memberId) {
                  // Find member name for confirmation dialog
                  final member = formState.members.firstWhere(
                    (m) => m.id == memberId,
                    orElse: () => formState.members.first,
                  );
                  _showRemoveMemberDialog(context, memberId, member.name);
                },
              ),
              const SizedBox(height: 32),

              // Split Bill Preview - Reactive with provider breakdown
              if (formState.members.isNotEmpty && formState.totalPrice.isNotEmpty)
                SplitBillPreviewCard(
                  totalAmount: double.tryParse(formState.totalPrice) ?? 0,
                  totalMembers: formState.totalMembers,
                  splitAmount: formState.splitAmount,
                  breakdown: formState.breakdown,
                ),
              const SizedBox(height: 100), // Padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: formState.isLoading
            ? null
            : () async {
                await formNotifier.submit(widget.subscriptionId);
              },
        backgroundColor: const Color(0xFF6C63FF),
        icon: formState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                isEditMode ? Icons.save : Icons.check,
                color: Colors.white,
              ),
        label: Text(
          formState.isLoading
              ? (isEditMode ? 'Updating...' : 'Creating...')
              : (isEditMode ? 'Update Subscription' : 'Create Group'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
