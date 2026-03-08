import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/service_template.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/service_template_repository.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/service_template_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/service_template_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceTemplateSheet', () {
    testWidgets('renders catalog results and filters by query', (tester) async {
      final repository = FakeServiceTemplateRepository(
        initialSnapshot: snapshot(
          templates: [
            template(name: 'Netflix', slug: 'netflix'),
            template(name: 'Spotify', slug: 'spotify'),
          ],
          isStale: true,
        ),
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            serviceTemplateRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ServiceTemplateSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Spotify'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'spot');
      await tester.pumpAndSettle();

      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('Netflix'), findsNothing);
    });

    testWidgets('returns selected template when item is tapped',
        (tester) async {
      final repository = FakeServiceTemplateRepository(
        initialSnapshot: snapshot(
          templates: [
            template(name: 'Netflix', slug: 'netflix'),
          ],
          isStale: false,
        ),
      );
      addTearDown(repository.dispose);

      ServiceTemplate? selectedTemplate;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            serviceTemplateRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      selectedTemplate =
                          await showModalBottomSheet<ServiceTemplate>(
                        context: context,
                        builder: (_) => const ServiceTemplateSheet(),
                      );
                    },
                    child: const Text('Open sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Netflix'));
      await tester.pumpAndSettle();

      expect(selectedTemplate?.name, 'Netflix');
      expect(selectedTemplate?.slug, 'netflix');
    });

    testWidgets('shows retry state when empty catalog has refresh error',
        (tester) async {
      final repository = FakeServiceTemplateRepository(
        initialSnapshot: snapshot(
          templates: const [],
          isStale: true,
          errorMessage: 'network down',
        ),
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            serviceTemplateRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ServiceTemplateSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load catalog'), findsOneWidget);
      expect(find.text('network down'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repository.refreshCount, 1);
    });
  });
}

ServiceTemplate template({
  required String name,
  required String slug,
}) {
  return ServiceTemplate(
    id: '$slug-id',
    slug: slug,
    name: name,
    logoUrl: 'https://example.com/$slug.svg',
    brandColor: '#6C63FF',
    aliases: const [],
    searchTerms: const [],
    isActive: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

ServiceTemplateCatalogSnapshot snapshot({
  required List<ServiceTemplate> templates,
  required bool isStale,
  String? errorMessage,
}) {
  return ServiceTemplateCatalogSnapshot(
    templates: templates,
    fetchedAt: DateTime.utc(2026, 3, 8),
    isStale: isStale,
    errorMessage: errorMessage,
  );
}

class FakeServiceTemplateRepository implements ServiceTemplateRepository {
  FakeServiceTemplateRepository({
    required ServiceTemplateCatalogSnapshot initialSnapshot,
  }) : _currentSnapshot = initialSnapshot;

  final StreamController<ServiceTemplateCatalogSnapshot> _controller =
      StreamController<ServiceTemplateCatalogSnapshot>.broadcast();
  ServiceTemplateCatalogSnapshot _currentSnapshot;
  ServiceTemplateCatalogSnapshot? nextRefreshSnapshot;
  int refreshCount = 0;

  @override
  Future<ServiceTemplateCatalogSnapshot> refreshCatalog() async {
    refreshCount += 1;
    final refreshed = nextRefreshSnapshot ?? _currentSnapshot;
    _currentSnapshot = refreshed;
    _controller.add(refreshed);
    return refreshed;
  }

  @override
  Stream<ServiceTemplateCatalogSnapshot> watchCatalog({
    bool forceRefresh = false,
  }) {
    return Stream<ServiceTemplateCatalogSnapshot>.multi((multi) {
      multi.add(_currentSnapshot);
      final sub = _controller.stream.listen(
        multi.add,
        onError: multi.addError,
      );
      multi.onCancel = sub.cancel;
    });
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
