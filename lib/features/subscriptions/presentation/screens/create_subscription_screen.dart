import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member_input.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_subscription_form_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/billing_cycle_selector.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/service_icon_picker.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/subscription_preview_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen for creating a new subscription
///
/// Provides a form with validation for all subscription fields:
/// - Name (required, min 2 chars)
/// - Cost (required, > 0)
/// - Billing cycle (monthly/yearly)
/// - Due date (must be future date)
/// - Color (hex format validation)
/// - Icon URL (optional)
class CreateSubscriptionScreen extends ConsumerStatefulWidget {
  const CreateSubscriptionScreen({super.key});

  @override
  ConsumerState<CreateSubscriptionScreen> createState() =>
      _CreateSubscriptionScreenState();
}

class _CreateSubscriptionScreenState
    extends ConsumerState<CreateSubscriptionScreen> {
  final _nameController = TextEditingController();
  final _costController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Listen to form state changes for success
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(
        createSubscriptionFormProvider,
        (previous, next) {
          if (next.isSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription created successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Navigate back to home
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.pop();
              }
            });
          } else if (next.errorMessage != null) {
            // Show error message
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

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createSubscriptionFormProvider);
    final formNotifier = ref.read(createSubscriptionFormProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview Card
                    SubscriptionPreviewCard(
                      name: formState.name,
                      totalCost: double.tryParse(formState.cost) ?? 0,
                      billingCycle: formState.billingCycle,
                      dueDate: formState.dueDate,
                      color: formState.color,
                      iconUrl: formState.iconUrl.isEmpty ? null : formState.iconUrl,
                    ),
                    const SizedBox(height: 32),

                    // Service Name Section
                    _buildSectionCard(
                      title: 'Service Name',
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'e.g., Netflix, Spotify',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: const Icon(
                                Icons.subscriptions,
                                color: Color(0xFF6C63FF),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF2A2A3E),
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
                            onChanged: formNotifier.updateName,
                          ),
                          const SizedBox(height: 16),
                          ServiceIconPicker(
                            selectedService: formState.iconUrl,
                            onServiceSelected: formNotifier.updateIconUrl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total Price Section
                    _buildSectionCard(
                      title: 'Total Price',
                      child: TextField(
                        controller: _costController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: const Icon(
                            Icons.attach_money,
                            color: Color(0xFF6C63FF),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2A2A3E),
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
                        onChanged: formNotifier.updateCost,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Billing Cycle Section
                    _buildSectionCard(
                      title: 'Billing Cycle',
                      child: BillingSycleSelector(
                        selectedCycle: formState.billingCycle,
                        onCycleSelected: formNotifier.updateBillingCycle,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Renewal Date Section
                    _buildSectionCard(
                      title: 'Renewal Date',
                      child: InkWell(
                        onTap: () => _selectDate(context, formNotifier),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A3E),
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
                                '${formState.dueDate.day}/${formState.dueDate.month}/${formState.dueDate.year}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Members Section
                    _buildSectionCard(
                      title: 'Members',
                      child: Column(
                        children: [
                          // Add Member Button
                          InkWell(
                            onTap: () => _showAddMemberDialog(context, formNotifier),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B4FBB).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF6B4FBB),
                                  width: 1.5,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFF6B4FBB),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Color(0xFF6B4FBB),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Members List
                          if (formState.members.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ...formState.members.map((member) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A3E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Avatar placeholder
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3D3D54),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          member.name.isNotEmpty
                                              ? member.name[0].toUpperCase()
                                              : 'M',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Member info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            member.email,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Remove button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () => formNotifier.removeMember(member.id),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),

                    // Split Bill Preview (only show if there are members)
                    if (formState.isGroupSubscription) ...[
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Split Bill Preview',
                        child: Column(
                          children: [
                            // Total Amount Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '\$${formState.cost.isEmpty ? "0.00" : double.tryParse(formState.cost)?.toStringAsFixed(2) ?? "0.00"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Total Members Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Members',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${formState.members.length + 1} people',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Each Person Pays
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B4FBB).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Each Person Pays',
                                    style: TextStyle(
                                      color: Color(0xFF6B4FBB),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '\$${formState.splitAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF6B4FBB),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.people_outline,
                                        color: Color(0xFF6B4FBB),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFF3D3D54)),
                            const SizedBox(height: 12),
                            // Breakdown label
                            const Row(
                              children: [
                                Text(
                                  'Breakdown',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Member breakdowns
                            ...formState.members.map((member) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '\$${formState.splitAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            // You (owner) row
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'You',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '\$${_calculateOwnerAmount(formState).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF6B4FBB),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Create Subscription Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: formState.isLoading
                            ? null
                            : () async {
                                await formNotifier.submit();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B4FBB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: formState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Subscription',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a section card wrapper with title
  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Show date picker dialog
  Future<void> _selectDate(
    BuildContext context,
    CreateSubscriptionForm formNotifier,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6B4FBB),
              surface: Color(0xFF2A2A3E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      formNotifier.updateDueDate(date);
    }
  }

  /// Calculate owner's amount (handles remainder from division)
  double _calculateOwnerAmount(CreateSubscriptionFormState state) {
    if (state.members.isEmpty) return 0.0;
    final totalCost = double.tryParse(state.cost) ?? 0.0;
    final totalMembers = state.members.length;
    final memberTotal = state.splitAmount * totalMembers;
    return totalCost - memberTotal; // Owner gets the remainder
  }

  /// Show dialog to add a hardcoded member
  void _showAddMemberDialog(
    BuildContext context,
    CreateSubscriptionForm formNotifier,
  ) {
    // Hardcoded members list for now (using fixed UUIDs for consistency)
    final availableMembers = [
      const SubscriptionMemberInput(
        id: '00000000-0000-0000-0000-000000000001', // Placeholder UUID for Sarah
        name: 'Sarah Jenkins',
        email: 'sarah@email.com',
        avatar: null,
      ),
      const SubscriptionMemberInput(
        id: '00000000-0000-0000-0000-000000000002', // Placeholder UUID for Mike
        name: 'Mike Thompson',
        email: 'mike@email.com',
        avatar: null,
      ),
      const SubscriptionMemberInput(
        id: '00000000-0000-0000-0000-000000000003', // Placeholder UUID for Emma
        name: 'Emma Wilson',
        email: 'emma@email.com',
        avatar: null,
      ),
    ];

    // Filter out already added members
    final state = ref.read(createSubscriptionFormProvider);
    final addedIds = state.members.map((m) => m.id).toSet();
    final availableToAdd = availableMembers
        .where((m) => !addedIds.contains(m.id))
        .toList();

    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All available members have been added'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2D),
        title: const Text(
          'Add Member',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableToAdd.length,
            itemBuilder: (context, index) {
              final member = availableToAdd[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6B4FBB),
                  child: Text(
                    member.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  member.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  member.email,
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  formNotifier.addMember(member);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
