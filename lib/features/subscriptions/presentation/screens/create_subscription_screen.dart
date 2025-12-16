import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_subscription_form_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/billing_cycle_selector.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/color_picker_widget.dart';
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
  final _iconUrlController = TextEditingController();

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
    _iconUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createSubscriptionFormProvider);
    final formNotifier = ref.read(createSubscriptionFormProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Create Subscription',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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

                    // Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: 'Subscription Name',
                      hint: 'e.g., Netflix, Spotify',
                      icon: Icons.subscriptions,
                      onChanged: formNotifier.updateName,
                    ),
                    const SizedBox(height: 20),

                    // Cost Field
                    _buildTextField(
                      controller: _costController,
                      label: 'Cost',
                      hint: '0.00',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: formNotifier.updateCost,
                    ),
                    const SizedBox(height: 20),

                    // Billing Cycle Selector
                    BillingSycleSelector(
                      selectedCycle: formState.billingCycle,
                      onCycleSelected: formNotifier.updateBillingCycle,
                    ),
                    const SizedBox(height: 20),

                    // Due Date Picker
                    _buildDatePicker(
                      context: context,
                      label: 'Due Date',
                      selectedDate: formState.dueDate,
                      onDateSelected: formNotifier.updateDueDate,
                    ),
                    const SizedBox(height: 20),

                    // Color Picker
                    ColorPickerWidget(
                      selectedColor: formState.color,
                      onColorSelected: formNotifier.updateColor,
                    ),
                    const SizedBox(height: 20),

                    // Icon URL Field (Optional)
                    _buildTextField(
                      controller: _iconUrlController,
                      label: 'Icon URL (Optional)',
                      hint: 'https://example.com/icon.png',
                      icon: Icons.image,
                      onChanged: formNotifier.updateIconUrl,
                    ),
                    const SizedBox(height: 100), // Padding for FAB
                  ],
                ),
              ),
            ),
          ],
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
          formState.isLoading ? 'Saving...' : 'Save Subscription',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Build a text field with consistent styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
            filled: true,
            fillColor: const Color(0xFF2D2D44),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF3D3D54),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF6C63FF),
                width: 2,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Build a date picker field
  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime selectedDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
              initialDate: selectedDate,
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
              onDateSelected(pickedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D44),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3D3D54),
                width: 1,
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
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
