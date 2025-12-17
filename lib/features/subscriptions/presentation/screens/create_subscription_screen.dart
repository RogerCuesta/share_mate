import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
}
