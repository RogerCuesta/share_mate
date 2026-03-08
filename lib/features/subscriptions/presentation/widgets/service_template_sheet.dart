import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/service_template.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/service_template_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServiceTemplateSheet extends ConsumerStatefulWidget {
  const ServiceTemplateSheet({
    super.key,
  });

  @override
  ConsumerState<ServiceTemplateSheet> createState() =>
      _ServiceTemplateSheetState();
}

class _ServiceTemplateSheetState extends ConsumerState<ServiceTemplateSheet> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final catalogState = ref.watch(serviceTemplateCatalogProvider);
    final templates = ref.watch(filteredServiceTemplatesProvider);
    final isStale = ref.watch(serviceTemplateIsStaleProvider);
    final refreshError = ref.watch(serviceTemplateRefreshErrorProvider);
    final snapshot = catalogState.valueOrNull;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select from catalog',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh catalog',
                  onPressed: () {
                    ref.read(serviceTemplateCatalogProvider.notifier).refresh();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _queryController,
              onChanged: (value) {
                ref.read(serviceTemplateQueryProvider.notifier).setQuery(value);
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search services',
              ),
            ),
            const SizedBox(height: 12),
            if (snapshot != null && (isStale || snapshot.isRefreshing))
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    snapshot.isRefreshing
                        ? 'Cached results · refreshing'
                        : 'Showing cached results',
                  ),
                ),
              ),
            if (refreshError != null && templates.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            refreshError,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Flexible(
              child: Builder(
                builder: (context) {
                  if (catalogState.isLoading && snapshot == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (templates.isEmpty) {
                    if (refreshError != null) {
                      return _EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: 'Unable to load catalog',
                        description: refreshError,
                        actionLabel: 'Retry',
                        onActionPressed: () {
                          ref
                              .read(serviceTemplateCatalogProvider.notifier)
                              .refresh();
                        },
                      );
                    }

                    return const _EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No services found',
                      description: 'Try a different name or clear the search.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: templates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return _ServiceTemplateTile(
                        template: template,
                        onTap: () => Navigator.of(context).pop(template),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTemplateTile extends StatelessWidget {
  const _ServiceTemplateTile({
    required this.template,
    required this.onTap,
  });

  final ServiceTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseTemplateColor(template.brandColor) ??
        theme.colorScheme.primary.withValues(alpha: 0.2);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.25),
                foregroundColor: color,
                child: Text(
                  template.name.isEmpty ? '?' : template.name[0].toUpperCase(),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.slug,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (template.logoUrl != null && template.logoUrl!.isNotEmpty)
                Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 38,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Color? _parseTemplateColor(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final normalized = value.replaceAll('#', '');
  if (normalized.length != 6 && normalized.length != 8) {
    return null;
  }

  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) {
    return null;
  }

  return Color(parsed);
}
