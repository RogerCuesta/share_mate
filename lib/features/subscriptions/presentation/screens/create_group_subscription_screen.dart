// lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/billing_cycle_selector.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/members_list_section.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/service_icon_picker.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/split_bill_preview_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen for creating a group subscription with split billing
class CreateGroupSubscriptionScreen extends ConsumerStatefulWidget {
  const CreateGroupSubscriptionScreen({super.key});

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

    // Listen for form state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(
        createGroupSubscriptionFormProvider,
        (previous, next) {
          if (next.isSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Group subscription created successfully!'),
                backgroundColor: Colors.green,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    });
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

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add Subscription',
          style: TextStyle(
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
                      '\$',
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
                            onSurface: Colors.white,
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

              // Members Section
              MembersListSection(
                members: formState.members,
                onMemberAdded: formNotifier.addMember,
                onMemberRemoved: formNotifier.removeMember,
              ),
              const SizedBox(height: 32),

              // Split Bill Preview
              SplitBillPreviewCard(
                totalAmount: double.tryParse(formState.totalPrice) ?? 0,
                totalMembers: formState.totalMembers,
                breakdown: formState.paymentBreakdown,
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
                await formNotifier.submit();
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
            : const Icon(Icons.check, color: Colors.white),
        label: Text(
          formState.isLoading ? 'Creating...' : 'Create Group',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
