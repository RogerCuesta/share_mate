// lib/features/settings/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_project_agents/features/settings/presentation/providers/account_actions_provider.dart';
import 'package:flutter_project_agents/features/settings/presentation/providers/profile_provider.dart';
import 'package:flutter_project_agents/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_project_agents/features/settings/presentation/providers/theme_provider.dart' hide Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings Screen
///
/// Comprehensive settings page with:
/// - Profile header (avatar, name, email)
/// - App preferences (theme, language, currency, date format)
/// - Privacy settings (discoverable toggle)
/// - Notifications (placeholders)
/// - Account management (password, email, delete account)
/// - About/Help section
/// - Logout button
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = theme.custom;
    final profileState = ref.watch(currentUserProfileProvider);
    final settingsState = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(context, profileState),

              SizedBox(height: customTheme.spacingLarge),

              // App Preferences Section
              _buildSection(
                context,
                title: 'App Preferences',
                children: [
                  _buildThemeModeTile(context, themeMode),
                  _buildTileWithBadge(
                    context,
                    title: 'Language',
                    subtitle: 'English',
                    icon: Icons.language,
                    badge: 'Coming soon',
                  ),
                  _buildTileWithBadge(
                    context,
                    title: 'Currency',
                    subtitle: settingsState.when(
                      data: (settings) => settings.currency,
                      loading: () => 'USD',
                      error: (_, __) => 'USD',
                    ),
                    icon: Icons.attach_money,
                    badge: 'Coming soon',
                  ),
                  _buildTileWithBadge(
                    context,
                    title: 'Date Format',
                    subtitle: settingsState.when(
                      data: (settings) => settings.dateFormat.displayName,
                      loading: () => 'DD/MM/YYYY',
                      error: (_, __) => 'DD/MM/YYYY',
                    ),
                    icon: Icons.calendar_today,
                    badge: 'Coming soon',
                  ),
                ],
              ),

              // Privacy Section
              _buildSection(
                context,
                title: 'Privacy',
                children: [
                  _buildDiscoverableTile(context, profileState),
                ],
              ),

              // Notifications Section (Placeholders)
              _buildSection(
                context,
                title: 'Notifications',
                badge: 'Coming soon',
                children: [
                  _buildTileWithBadge(
                    context,
                    title: 'Payment Reminders',
                    subtitle: 'Get notified before payments are due',
                    icon: Icons.notifications,
                    badge: 'Coming soon',
                  ),
                  _buildTileWithBadge(
                    context,
                    title: 'Subscription Changes',
                    subtitle: 'Updates to your subscriptions',
                    icon: Icons.update,
                    badge: 'Coming soon',
                  ),
                  _buildTileWithBadge(
                    context,
                    title: 'Friend Requests',
                    subtitle: 'New friend requests',
                    icon: Icons.person_add,
                    badge: 'Coming soon',
                  ),
                ],
              ),

              // Account Management Section
              _buildSection(
                context,
                title: 'Account',
                children: [
                  _buildTile(
                    context,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    icon: Icons.lock,
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  _buildTile(
                    context,
                    title: 'Email Verification',
                    subtitle: 'Verify your email address',
                    icon: Icons.email,
                    onTap: () => _showEmailVerificationDialog(context),
                  ),
                  _buildTile(
                    context,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    icon: Icons.delete_forever,
                    iconColor: theme.colorScheme.error,
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ],
              ),

              // About/Help Section
              _buildSection(
                context,
                title: 'About & Help',
                children: [
                  _buildTile(
                    context,
                    title: 'App Version',
                    subtitle: _appVersion.isEmpty ? 'Loading...' : _appVersion,
                    icon: Icons.info,
                  ),
                  _buildTile(
                    context,
                    title: 'Terms of Service',
                    subtitle: 'Read our terms',
                    icon: Icons.description,
                    onTap: () => _launchURL('https://submate.app/terms'),
                  ),
                  _buildTile(
                    context,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    icon: Icons.privacy_tip,
                    onTap: () => _launchURL('https://submate.app/privacy'),
                  ),
                  _buildTile(
                    context,
                    title: 'Contact Support',
                    subtitle: 'Get help with SubMate',
                    icon: Icons.support_agent,
                    onTap: () => _launchURL('mailto:support@submate.app'),
                  ),
                  _buildTile(
                    context,
                    title: 'Rate App',
                    subtitle: 'Leave a review',
                    icon: Icons.star,
                    onTap: () => _launchURL('https://submate.app/rate'),
                  ),
                ],
              ),

              SizedBox(height: customTheme.spacingLarge),

              // Logout Button
              _buildLogoutButton(context),

              SizedBox(height: customTheme.spacingXLarge),
            ],
          ),
        ),
      ),
    );
  }

  /// Build profile header section
  Widget _buildProfileHeader(BuildContext context, AsyncValue profileState) {
    final theme = Theme.of(context);
    final customTheme = theme.custom;

    return Container(
      padding: EdgeInsets.all(customTheme.spacingLarge),
      child: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile data'));
          }

          return Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  profile.initials,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              SizedBox(width: customTheme.spacingMedium),
              // Profile info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: theme.textTheme.titleLarge,
                    ),
                    SizedBox(height: customTheme.spacingXSmall),
                    Text(
                      profile.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Navigate to ProfileEditScreen
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  /// Build a settings section
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children, String? badge,
  }) {
    final theme = Theme.of(context);
    final customTheme = theme.custom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: customTheme.spacingMedium,
            vertical: customTheme.spacingSmall,
          ),
          child: Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (badge != null) ...[
                SizedBox(width: customTheme.spacingSmall),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: customTheme.spacingSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(customTheme.borderRadiusSmall),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  /// Build a generic settings tile
  Widget _buildTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  /// Build a tile with a badge
  Widget _buildTileWithBadge(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
  }) {
    final theme = Theme.of(context);
    final customTheme = theme.custom;

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: EdgeInsets.symmetric(
          horizontal: customTheme.spacingSmall,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(customTheme.borderRadiusSmall),
        ),
        child: Text(
          badge,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// Build theme mode selector tile
  Widget _buildThemeModeTile(BuildContext context, AppThemeMode currentMode) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(Icons.brightness_6, color: theme.colorScheme.primary),
      title: const Text('Theme'),
      subtitle: Text(currentMode.displayName),
      trailing: SegmentedButton<AppThemeMode>(
        segments: const [
          ButtonSegment(
            value: AppThemeMode.light,
            icon: Icon(Icons.light_mode, size: 16),
          ),
          ButtonSegment(
            value: AppThemeMode.dark,
            icon: Icon(Icons.dark_mode, size: 16),
          ),
          ButtonSegment(
            value: AppThemeMode.system,
            icon: Icon(Icons.brightness_auto, size: 16),
          ),
        ],
        selected: {currentMode},
        onSelectionChanged: (Set<AppThemeMode> newSelection) {
          ref.read(themeProvider.notifier).setTheme(newSelection.first);
        },
      ),
    );
  }

  /// Build discoverable toggle tile
  Widget _buildDiscoverableTile(BuildContext context, AsyncValue profileState) {
    final theme = Theme.of(context);

    return profileState.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        return SwitchListTile(
          secondary: Icon(Icons.search, color: theme.colorScheme.primary),
          title: const Text('Discoverable'),
          subtitle: const Text('Allow others to find you by email'),
          value: profile.isDiscoverable,
          onChanged: (bool value) async {
            final updatedProfile = profile.copyWith(isDiscoverable: value);
            await ref.read(currentUserProfileProvider.notifier).updateProfile(updatedProfile);
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Build logout button
  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = theme.custom;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: customTheme.spacingMedium),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            padding: EdgeInsets.all(customTheme.spacingMedium),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // DIALOG METHODS
  // ============================================================================

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter new password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(accountActionsProvider.notifier)
          .changePassword(passwordController.text);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Password changed successfully' : 'Failed to change password'),
          ),
        );
      }
    }

    passwordController.dispose();
    confirmController.dispose();
  }

  Future<void> _showEmailVerificationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification'),
        content: const Text('Send a verification email to your registered email address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(accountActionsProvider.notifier)
          .sendEmailVerification();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Verification email sent. Please check your inbox.'
                : 'Failed to send verification email'),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Type DELETE to confirm:'),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != 'DELETE') {
                    return 'Please type DELETE to confirm';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authState = ref.read(authProvider);
      final userId = authState.maybeWhen(
        authenticated: (user) => user.id,
        orElse: () => null,
      );

      if (userId != null) {
        final success = await ref
            .read(accountActionsProvider.notifier)
            .deleteAccount(userId);

        if (success && context.mounted) {
          await ref.read(authProvider.notifier).logout();
        }
      }
    }

    controller.dispose();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
