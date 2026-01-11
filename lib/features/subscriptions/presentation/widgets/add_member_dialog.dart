// lib/features/subscriptions/presentation/widgets/add_member_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member_input.dart';
import 'package:uuid/uuid.dart';

/// Dialog for adding a new member to a group subscription
///
/// Displays a Material 3 form to collect member name and email with robust validation.
/// Returns a [SubscriptionMemberInput] when the user taps "Add Member",
/// or null if canceled.
///
/// Features:
/// - Email validation with strict regex
/// - Name validation (min 2 chars, no numbers-only)
/// - UUID v4 generation for member ID
/// - Email normalization (lowercase)
/// - Dark theme consistent with app design
/// - Comprehensive logging for debugging
class AddMemberDialog extends StatefulWidget {
  const AddMemberDialog({super.key});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Handles the "Add Member" button press
  void _handleAdd() {
    debugPrint('📝 [AddMemberDialog] Attempting to add member...');

    if (_formKey.currentState?.validate() ?? false) {
      final member = SubscriptionMemberInput(
        id: const Uuid().v4(), // ✅ Generate UUID v4
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(), // ✅ Normalize email
      );

      debugPrint('✅ [AddMemberDialog] Member created successfully:');
      debugPrint('   Name: ${member.name}');
      debugPrint('   Email: ${member.email}');
      debugPrint('   ID: ${member.id}');

      Navigator.of(context).pop(member);
    } else {
      debugPrint('❌ [AddMemberDialog] Validation failed');
    }
  }

  /// Validates the name field
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      debugPrint('⚠️ [AddMemberDialog] Name validation: empty');
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      debugPrint('⚠️ [AddMemberDialog] Name validation: too short (${value.trim().length} chars)');
      return 'Name must be at least 2 characters';
    }

    // Prevent names that are only numbers
    if (RegExp(r'^\d+$').hasMatch(value.trim())) {
      debugPrint('⚠️ [AddMemberDialog] Name validation: numbers only');
      return 'Name cannot be only numbers';
    }

    debugPrint('✅ [AddMemberDialog] Name validation: passed');
    return null;
  }

  /// Validates the email field with strict regex
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      debugPrint('⚠️ [AddMemberDialog] Email validation: empty');
      return 'Email is required';
    }

    // Strict email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      debugPrint('⚠️ [AddMemberDialog] Email validation: invalid format');
      return 'Please enter a valid email address';
    }

    debugPrint('✅ [AddMemberDialog] Email validation: passed');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2D), // ✅ Consistent dark theme
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Member',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[400]),
                      onPressed: () {
                        debugPrint('❌ [AddMemberDialog] Cancelled by user');
                        Navigator.of(context).pop();
                      },
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name field
                const Text(
                  'Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'John Doe',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.person, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF2A2A3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[800]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6B4FBB),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 20),

                // Email field
                const Text(
                  'Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'john@example.com',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.email, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF2A2A3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[800]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6B4FBB),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        debugPrint('❌ [AddMemberDialog] Cancelled by user');
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _handleAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4FBB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
