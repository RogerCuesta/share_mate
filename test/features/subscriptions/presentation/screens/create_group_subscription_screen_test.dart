import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/service_template.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/service_template_repository.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/service_template_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/screens/create_group_subscription_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateGroupSubscriptionScreen', () {
    testWidgets(
      'catalog selection autofills name and preserves manual edits on reselection',
      (tester) async {
        final repository = _FakeServiceTemplateRepository(
          initialSnapshot: _snapshot(
            templates: [
              _template(name: 'Netflix', slug: 'netflix', color: '#E50914'),
              _template(name: 'Spotify', slug: 'spotify', color: '#1DB954'),
            ],
            isStale: false,
          ),
        );
        addTearDown(repository.dispose);

        final container = ProviderContainer(
          overrides: [
            serviceTemplateRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: CreateGroupSubscriptionScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Browse catalog templates'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Netflix'));
        await tester.pumpAndSettle();

        var formState = container.read(createGroupSubscriptionFormProvider);
        expect(formState.selectedTemplateSlug, 'netflix');
        expect(formState.serviceName, 'Netflix');

        await tester.enterText(find.byType(TextField).first, 'Netflix Family+');
        await tester.pumpAndSettle();

        formState = container.read(createGroupSubscriptionFormProvider);
        expect(formState.serviceName, 'Netflix Family+');
        expect(formState.isServiceNameManuallyEdited, isTrue);

        await tester.tap(find.text('Template: netflix'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spotify'));
        await tester.pumpAndSettle();

        formState = container.read(createGroupSubscriptionFormProvider);
        expect(formState.selectedTemplateSlug, 'spotify');
        expect(formState.selectedTemplateColor, '#1DB954');
        expect(formState.serviceName, 'Netflix Family+');
      },
    );
  });
}

ServiceTemplate _template({
  required String name,
  required String slug,
  required String color,
}) {
  return ServiceTemplate(
    id: '$slug-id',
    slug: slug,
    name: name,
    logoUrl: 'https://example.com/$slug.svg',
    brandColor: color,
    aliases: const [],
    searchTerms: const [],
    isActive: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

ServiceTemplateCatalogSnapshot _snapshot({
  required List<ServiceTemplate> templates,
  required bool isStale,
  String? errorMessage,
}) {
  return ServiceTemplateCatalogSnapshot(
    templates: templates,
    fetchedAt: DateTime.utc(2026, 3, 9),
    isStale: isStale,
    errorMessage: errorMessage,
  );
}

class _FakeServiceTemplateRepository implements ServiceTemplateRepository {
  _FakeServiceTemplateRepository({
    required ServiceTemplateCatalogSnapshot initialSnapshot,
  }) : _currentSnapshot = initialSnapshot;

  final StreamController<ServiceTemplateCatalogSnapshot> _controller =
      StreamController<ServiceTemplateCatalogSnapshot>.broadcast();
  ServiceTemplateCatalogSnapshot _currentSnapshot;
  ServiceTemplateCatalogSnapshot? nextRefreshSnapshot;

  @override
  Future<ServiceTemplateCatalogSnapshot> refreshCatalog() async {
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
