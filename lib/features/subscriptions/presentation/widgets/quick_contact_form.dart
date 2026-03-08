import 'package:flutter/material.dart';

class QuickContactDraft {
  const QuickContactDraft({
    required this.name,
    required this.color,
    this.email,
  });

  final String name;
  final String? email;
  final String color;
}

class QuickContactForm extends StatefulWidget {
  const QuickContactForm({
    required this.onSubmit,
    this.isSubmitting = false,
    super.key,
  });

  final Future<void> Function(QuickContactDraft draft) onSubmit;
  final bool isSubmitting;

  static const List<String> palette = <String>[
    '#6C63FF',
    '#00B894',
    '#E17055',
    '#0984E3',
    '#E84393',
    '#FDCB6E',
  ];

  @override
  State<QuickContactForm> createState() => _QuickContactFormState();
}

class _QuickContactFormState extends State<QuickContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedColor = QuickContactForm.palette.first;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final normalizedEmail = _normalizeOptionalEmail(_emailController.text);
    final draft = QuickContactDraft(
      name: _nameController.text.trim(),
      email: normalizedEmail,
      color: _selectedColor,
    );

    await widget.onSubmit(draft);
  }

  String? _normalizeOptionalEmail(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String? _validateName(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Name is required';
    }
    if (normalized.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(normalized)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: const Key('quick-contact-name-field'),
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Alex',
            ),
            validator: _validateName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('quick-contact-email-field'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              hintText: 'alex@example.com',
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          const Text(
            'Avatar Color',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: QuickContactForm.palette.map((hex) {
              final color = _parseColor(hex);
              final selected = hex == _selectedColor;
              return GestureDetector(
                key: Key('quick-contact-color-$hex'),
                onTap: () => setState(() => _selectedColor = hex),
                child: CircleAvatar(
                  radius: selected ? 16 : 14,
                  backgroundColor: color,
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('quick-contact-submit-button'),
              onPressed: widget.isSubmitting ? null : _handleSubmit,
              icon: widget.isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label:
                  Text(widget.isSubmitting ? 'Creating...' : 'Create Contact'),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final normalized = hex.replaceAll('#', '');
    final value = int.parse('FF$normalized', radix: 16);
    return Color(value);
  }
}
