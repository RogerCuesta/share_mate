import 'dart:async';

import 'package:flutter_project_agents/features/subscriptions/data/datasources/service_template_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/service_template_remote_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/service_template_model.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/service_template_repository.dart';

class ServiceTemplateRepositoryImpl implements ServiceTemplateRepository {
  ServiceTemplateRepositoryImpl({
    required ServiceTemplateRemoteDataSource remoteDataSource,
    required ServiceTemplateLocalDataSource localDataSource,
    Duration cacheTtl = const Duration(hours: 24),
    DateTime Function()? now,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _cacheTtl = cacheTtl,
        _now = now ?? DateTime.now;

  final ServiceTemplateRemoteDataSource _remoteDataSource;
  final ServiceTemplateLocalDataSource _localDataSource;
  final Duration _cacheTtl;
  final DateTime Function() _now;

  Future<_RefreshResult>? _inFlightRefresh;

  @override
  Stream<ServiceTemplateCatalogSnapshot> watchCatalog({
    bool forceRefresh = false,
  }) async* {
    ServiceTemplateCacheEntry? cacheEntry;
    String? cacheReadError;

    try {
      cacheEntry = await _localDataSource.readCache();
    } on ServiceTemplateLocalException catch (error) {
      cacheReadError = error.message;
    }

    final cachedTemplates =
        cacheEntry?.templates ?? const <ServiceTemplateModel>[];
    final cachedFetchedAt = cacheEntry?.fetchedAt;
    final hasCache = cachedTemplates.isNotEmpty;
    final cacheIsStale = cachedFetchedAt == null || _isStale(cachedFetchedAt);
    final shouldRefresh = forceRefresh || !hasCache || cacheIsStale;

    if (hasCache) {
      yield _buildSnapshot(
        cachedTemplates,
        fetchedAt: cachedFetchedAt,
        isStale: cacheIsStale,
        isRefreshing: shouldRefresh,
      );
    }

    if (!shouldRefresh) {
      return;
    }

    try {
      final refreshed = await _refreshSingleFlight();
      yield _buildSnapshot(
        refreshed.models,
        fetchedAt: refreshed.fetchedAt,
        isStale: false,
      );
    } on ServiceTemplateRemoteException catch (error) {
      if (hasCache) {
        yield _buildSnapshot(
          cachedTemplates,
          fetchedAt: cachedFetchedAt,
          isStale: true,
          errorMessage: error.message,
        );
        return;
      }

      yield ServiceTemplateCatalogSnapshot(
        templates: const [],
        isStale: true,
        errorMessage: _mergeErrors(cacheReadError, error.message),
      );
    } on ServiceTemplateLocalException catch (error) {
      if (hasCache) {
        yield _buildSnapshot(
          cachedTemplates,
          fetchedAt: cachedFetchedAt,
          isStale: true,
          errorMessage: error.message,
        );
        return;
      }

      yield ServiceTemplateCatalogSnapshot(
        templates: const [],
        isStale: true,
        errorMessage: _mergeErrors(cacheReadError, error.message),
      );
    }
  }

  @override
  Future<ServiceTemplateCatalogSnapshot> refreshCatalog() async {
    ServiceTemplateCacheEntry? cacheEntry;
    String? cacheReadError;

    try {
      cacheEntry = await _localDataSource.readCache();
    } on ServiceTemplateLocalException catch (error) {
      cacheReadError = error.message;
    }
    final cachedTemplates =
        cacheEntry?.templates ?? const <ServiceTemplateModel>[];
    final cachedFetchedAt = cacheEntry?.fetchedAt;
    final hasCache = cachedTemplates.isNotEmpty;

    try {
      final refreshed = await _refreshSingleFlight();
      return _buildSnapshot(
        refreshed.models,
        fetchedAt: refreshed.fetchedAt,
        isStale: false,
      );
    } on ServiceTemplateRemoteException catch (error) {
      if (hasCache) {
        return _buildSnapshot(
          cachedTemplates,
          fetchedAt: cachedFetchedAt,
          isStale: true,
          errorMessage: error.message,
        );
      }

      return ServiceTemplateCatalogSnapshot(
        templates: const [],
        isStale: true,
        errorMessage: _mergeErrors(cacheReadError, error.message),
      );
    } on ServiceTemplateLocalException catch (error) {
      if (hasCache) {
        return _buildSnapshot(
          cachedTemplates,
          fetchedAt: cachedFetchedAt,
          isStale: true,
          errorMessage: error.message,
        );
      }

      return ServiceTemplateCatalogSnapshot(
        templates: const [],
        isStale: true,
        errorMessage: _mergeErrors(cacheReadError, error.message),
      );
    }
  }

  bool _isStale(DateTime fetchedAt) {
    final age = _now().toUtc().difference(fetchedAt.toUtc());
    return age >= _cacheTtl;
  }

  Future<_RefreshResult> _refreshSingleFlight() {
    final inFlight = _inFlightRefresh;
    if (inFlight != null) {
      return inFlight;
    }

    final operation = _refreshRemote();
    _inFlightRefresh = operation;
    return operation.whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<_RefreshResult> _refreshRemote() async {
    final models = await _remoteDataSource.fetchTemplates();
    final fetchedAt = _now().toUtc();
    await _localDataSource.saveCache(
      models,
      fetchedAt: fetchedAt,
    );
    return _RefreshResult(models: models, fetchedAt: fetchedAt);
  }

  ServiceTemplateCatalogSnapshot _buildSnapshot(
    List<ServiceTemplateModel> models, {
    required DateTime? fetchedAt,
    required bool isStale,
    bool isRefreshing = false,
    String? errorMessage,
  }) {
    final templates =
        models.map((model) => model.toEntity()).toList(growable: false);

    return ServiceTemplateCatalogSnapshot(
      templates: templates,
      fetchedAt: fetchedAt,
      isStale: isStale,
      isRefreshing: isRefreshing,
      errorMessage: errorMessage,
    );
  }

  String? _mergeErrors(String? left, String? right) {
    if (left == null || left.isEmpty) {
      return right;
    }
    if (right == null || right.isEmpty) {
      return left;
    }
    return '$left | $right';
  }
}

class _RefreshResult {
  const _RefreshResult({
    required this.models,
    required this.fetchedAt,
  });

  final List<ServiceTemplateModel> models;
  final DateTime fetchedAt;
}
