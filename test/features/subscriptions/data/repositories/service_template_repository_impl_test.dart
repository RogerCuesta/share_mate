import 'package:flutter_project_agents/features/subscriptions/data/datasources/service_template_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/service_template_remote_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/service_template_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/repositories/service_template_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceTemplateRepositoryImpl', () {
    late DateTime now;
    late FakeServiceTemplateRemoteDataSource remoteDataSource;
    late InMemoryServiceTemplateLocalDataSource localDataSource;
    late ServiceTemplateRepositoryImpl repository;

    setUp(() {
      now = DateTime.utc(2026, 3, 8, 12);
      remoteDataSource = FakeServiceTemplateRemoteDataSource();
      localDataSource = InMemoryServiceTemplateLocalDataSource();
      repository = ServiceTemplateRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        now: () => now,
      );
    });

    test('emits cached data first and refreshed data when cache is stale',
        () async {
      await localDataSource.saveCache(
        [buildTemplateModel(name: 'Cached Netflix')],
        fetchedAt: now.subtract(const Duration(hours: 25)),
      );
      remoteDataSource.nextResponse = [
        buildTemplateModel(name: 'Fresh Netflix')
      ];

      final emissions = await repository.watchCatalog().toList();

      expect(emissions, hasLength(2));
      expect(emissions[0].templates.single.name, 'Cached Netflix');
      expect(emissions[0].isStale, isTrue);
      expect(emissions[0].isRefreshing, isTrue);

      expect(emissions[1].templates.single.name, 'Fresh Netflix');
      expect(emissions[1].isStale, isFalse);
      expect(emissions[1].errorMessage, isNull);
      expect(remoteDataSource.fetchCount, 1);
      expect(
        localDataSource.cachedEntry?.fetchedAt,
        now,
      );
    });

    test('uses fresh cache without remote fetch', () async {
      await localDataSource.saveCache(
        [buildTemplateModel(name: 'Fresh Cache')],
        fetchedAt: now.subtract(const Duration(hours: 3)),
      );

      final emissions = await repository.watchCatalog().toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.templates.single.name, 'Fresh Cache');
      expect(emissions.single.isStale, isFalse);
      expect(emissions.single.isRefreshing, isFalse);
      expect(remoteDataSource.fetchCount, 0);
    });

    test('forceRefresh fetches remote even with fresh cache', () async {
      await localDataSource.saveCache(
        [buildTemplateModel(name: 'Fresh Cache')],
        fetchedAt: now.subtract(const Duration(hours: 1)),
      );
      remoteDataSource.nextResponse = [
        buildTemplateModel(name: 'Forced Refresh')
      ];

      final emissions =
          await repository.watchCatalog(forceRefresh: true).toList();

      expect(emissions, hasLength(2));
      expect(emissions[0].templates.single.name, 'Fresh Cache');
      expect(emissions[0].isRefreshing, isTrue);
      expect(emissions[1].templates.single.name, 'Forced Refresh');
      expect(emissions[1].isStale, isFalse);
      expect(remoteDataSource.fetchCount, 1);
    });

    test('keeps stale cache and surfaces error when background refresh fails',
        () async {
      await localDataSource.saveCache(
        [buildTemplateModel(name: 'Offline Cache')],
        fetchedAt: now.subtract(const Duration(hours: 26)),
      );
      remoteDataSource.throwOnFetch =
          ServiceTemplateRemoteException('network down');

      final emissions = await repository.watchCatalog().toList();

      expect(emissions, hasLength(2));
      expect(emissions[0].templates.single.name, 'Offline Cache');
      expect(emissions[1].templates.single.name, 'Offline Cache');
      expect(emissions[1].isStale, isTrue);
      expect(emissions[1].errorMessage, contains('network down'));
    });

    test(
        'refreshCatalog returns cached data with error when force refresh fails',
        () async {
      await localDataSource.saveCache(
        [buildTemplateModel(name: 'Cached Apple TV')],
        fetchedAt: now.subtract(const Duration(hours: 30)),
      );
      remoteDataSource.throwOnFetch = ServiceTemplateRemoteException('timeout');

      final snapshot = await repository.refreshCatalog();

      expect(snapshot.templates.single.name, 'Cached Apple TV');
      expect(snapshot.isStale, isTrue);
      expect(snapshot.errorMessage, contains('timeout'));
    });
  });
}

ServiceTemplateModel buildTemplateModel({
  required String name,
}) {
  return ServiceTemplateModel(
    id: '$name-id',
    slug: name.toLowerCase().replaceAll(' ', '-'),
    name: name,
    logoUrl: 'https://example.com/$name.svg',
    brandColor: '#6C63FF',
    aliases: const ['streaming'],
    searchTerms: const ['video'],
    isActive: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

class FakeServiceTemplateRemoteDataSource
    implements ServiceTemplateRemoteDataSource {
  List<ServiceTemplateModel> nextResponse = const [];
  ServiceTemplateRemoteException? throwOnFetch;
  int fetchCount = 0;

  @override
  Future<List<ServiceTemplateModel>> fetchTemplates() async {
    fetchCount += 1;
    final error = throwOnFetch;
    if (error != null) {
      throw error;
    }
    return nextResponse;
  }
}

class InMemoryServiceTemplateLocalDataSource
    implements ServiceTemplateLocalDataSource {
  ServiceTemplateCacheEntry? cachedEntry;

  @override
  Future<void> clearCache() async {
    cachedEntry = null;
  }

  @override
  Future<ServiceTemplateCacheEntry?> readCache() async => cachedEntry;

  @override
  Future<void> saveCache(
    List<ServiceTemplateModel> templates, {
    required DateTime fetchedAt,
  }) async {
    cachedEntry = ServiceTemplateCacheEntry(
      templates: templates,
      fetchedAt: fetchedAt,
    );
  }
}
