import 'dart:async';

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/service_template_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/service_template_remote_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/repositories/service_template_repository_impl.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/service_template.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/service_template_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceTemplateRemoteDataSourceProvider =
    Provider<ServiceTemplateRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ServiceTemplateRemoteDataSourceImpl(client: client);
});

final serviceTemplateLocalDataSourceProvider =
    Provider<ServiceTemplateLocalDataSource>((ref) {
  return ServiceTemplateLocalDataSourceImpl();
});

final serviceTemplateRepositoryProvider = Provider<ServiceTemplateRepository>((
  ref,
) {
  return ServiceTemplateRepositoryImpl(
    remoteDataSource: ref.watch(serviceTemplateRemoteDataSourceProvider),
    localDataSource: ref.watch(serviceTemplateLocalDataSourceProvider),
  );
});

class ServiceTemplateQueryController extends AutoDisposeNotifier<String> {
  @override
  String build() => '';

  // ignore: use_setters_to_change_properties
  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final serviceTemplateQueryProvider =
    AutoDisposeNotifierProvider<ServiceTemplateQueryController, String>(
  ServiceTemplateQueryController.new,
);

class ServiceTemplateCatalogController
    extends AutoDisposeAsyncNotifier<ServiceTemplateCatalogSnapshot> {
  StreamSubscription<ServiceTemplateCatalogSnapshot>? _subscription;

  @override
  Future<ServiceTemplateCatalogSnapshot> build() async {
    ref.onDispose(() async {
      await _subscription?.cancel();
    });

    return _watchCatalog();
  }

  Future<void> refresh() async {
    final repository = ref.read(serviceTemplateRepositoryProvider);
    final current = state.valueOrNull;

    if (current != null) {
      state = AsyncData(
        ServiceTemplateCatalogSnapshot(
          templates: current.templates,
          fetchedAt: current.fetchedAt,
          isStale: current.isStale,
          isRefreshing: true,
          errorMessage: current.errorMessage,
        ),
      );
    }

    final refreshed = await repository.refreshCatalog();
    state = AsyncData(refreshed);
  }

  Future<ServiceTemplateCatalogSnapshot> _watchCatalog() async {
    await _subscription?.cancel();

    final completer = Completer<ServiceTemplateCatalogSnapshot>();
    final stream = ref.read(serviceTemplateRepositoryProvider).watchCatalog();

    _subscription = stream.listen(
      (snapshot) {
        if (!completer.isCompleted) {
          completer.complete(snapshot);
        }
        state = AsyncData(snapshot);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        state = AsyncError(error, stackTrace);
      },
    );

    return completer.future;
  }
}

final serviceTemplateCatalogProvider = AutoDisposeAsyncNotifierProvider<
    ServiceTemplateCatalogController, ServiceTemplateCatalogSnapshot>(
  ServiceTemplateCatalogController.new,
);

final filteredServiceTemplatesProvider =
    Provider.autoDispose<List<ServiceTemplate>>((ref) {
  final snapshot = ref.watch(serviceTemplateCatalogProvider).valueOrNull;
  final query = ref.watch(serviceTemplateQueryProvider).trim().toLowerCase();
  final templates = snapshot?.templates ?? const <ServiceTemplate>[];

  if (query.isEmpty) {
    return templates;
  }

  return templates
      .where((template) => _templateMatchesQuery(template, query))
      .toList(growable: false);
});

final serviceTemplateIsStaleProvider = Provider.autoDispose<bool>((ref) {
  final snapshot = ref.watch(serviceTemplateCatalogProvider).valueOrNull;
  return snapshot?.isStale ?? false;
});

final serviceTemplateRefreshErrorProvider =
    Provider.autoDispose<String?>((ref) {
  final snapshot = ref.watch(serviceTemplateCatalogProvider).valueOrNull;
  return snapshot?.errorMessage;
});

bool _templateMatchesQuery(ServiceTemplate template, String query) {
  final haystacks = <String>[
    template.name,
    template.slug,
    ...template.aliases,
    ...template.searchTerms,
  ];

  return haystacks.any((value) => value.toLowerCase().contains(query));
}
