import 'dart:async';

import 'package:flutter_project_agents/features/subscriptions/domain/entities/service_template.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/service_template_repository.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/service_template_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('service template providers', () {
    test('filters query results on cached and refreshed snapshots', () async {
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

      final container = ProviderContainer(
        overrides: [
          serviceTemplateRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final catalogSub = container.listen(
        serviceTemplateCatalogProvider,
        (_, __) {},
      );
      addTearDown(catalogSub.close);

      await container.read(serviceTemplateCatalogProvider.future);

      container.read(serviceTemplateQueryProvider.notifier).setQuery('spot');
      expect(
        container.read(filteredServiceTemplatesProvider).single.name,
        'Spotify',
      );

      repository.emit(
        snapshot(
          templates: [
            template(name: 'Disney+', slug: 'disney-plus'),
            template(name: 'Prime Video', slug: 'prime-video'),
          ],
          isStale: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      container.read(serviceTemplateQueryProvider.notifier).setQuery('disney');
      expect(
        container.read(filteredServiceTemplatesProvider).single.name,
        'Disney+',
      );
    });

    test('refresh exposes errors while preserving existing cached data',
        () async {
      final cachedTemplate = template(name: 'Netflix', slug: 'netflix');
      final repository = FakeServiceTemplateRepository(
        initialSnapshot: snapshot(
          templates: [cachedTemplate],
          isStale: true,
        ),
      )..nextRefreshSnapshot = snapshot(
          templates: [cachedTemplate],
          isStale: true,
          errorMessage: 'network down',
        );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          serviceTemplateRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final catalogSub = container.listen(
        serviceTemplateCatalogProvider,
        (_, __) {},
      );
      addTearDown(catalogSub.close);

      await container.read(serviceTemplateCatalogProvider.future);
      await container.read(serviceTemplateCatalogProvider.notifier).refresh();

      final snapshotValue =
          container.read(serviceTemplateCatalogProvider).value;
      expect(snapshotValue, isNotNull);
      expect(snapshotValue!.templates.single.name, 'Netflix');
      expect(snapshotValue.errorMessage, 'network down');
      expect(
        container.read(serviceTemplateRefreshErrorProvider),
        'network down',
      );
      expect(repository.refreshCount, 1);
    });

    test('refresh updates stale flag and list when remote refresh succeeds',
        () async {
      final repository = FakeServiceTemplateRepository(
        initialSnapshot: snapshot(
          templates: [template(name: 'Old Cache', slug: 'old-cache')],
          isStale: true,
        ),
      )..nextRefreshSnapshot = snapshot(
          templates: [template(name: 'Fresh Cache', slug: 'fresh-cache')],
          isStale: false,
        );
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          serviceTemplateRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final catalogSub = container.listen(
        serviceTemplateCatalogProvider,
        (_, __) {},
      );
      addTearDown(catalogSub.close);

      await container.read(serviceTemplateCatalogProvider.future);
      expect(container.read(serviceTemplateIsStaleProvider), isTrue);

      await container.read(serviceTemplateCatalogProvider.notifier).refresh();

      final refreshed = container.read(serviceTemplateCatalogProvider).value!;
      expect(refreshed.templates.single.name, 'Fresh Cache');
      expect(refreshed.isStale, isFalse);
      expect(container.read(serviceTemplateIsStaleProvider), isFalse);
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

  void emit(ServiceTemplateCatalogSnapshot snapshot) {
    _currentSnapshot = snapshot;
    _controller.add(snapshot);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
