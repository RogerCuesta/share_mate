import 'dart:convert';

import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/service_template_model.dart';
import 'package:hive_ce/hive.dart';

class ServiceTemplateLocalException implements Exception {
  ServiceTemplateLocalException(this.message);

  final String message;

  @override
  String toString() => 'ServiceTemplateLocalException: $message';
}

class ServiceTemplateCacheEntry {
  const ServiceTemplateCacheEntry({
    required this.templates,
    required this.fetchedAt,
  });

  final List<ServiceTemplateModel> templates;
  final DateTime fetchedAt;
}

abstract class ServiceTemplateLocalDataSource {
  Future<ServiceTemplateCacheEntry?> readCache();

  Future<void> saveCache(
    List<ServiceTemplateModel> templates, {
    required DateTime fetchedAt,
  });

  Future<void> clearCache();
}

class ServiceTemplateLocalDataSourceImpl
    implements ServiceTemplateLocalDataSource {
  ServiceTemplateLocalDataSourceImpl({
    Future<Box<dynamic>> Function()? boxOpener,
  }) : _boxOpener = boxOpener ??
            (() => HiveService.openBox<dynamic>(
                  boxName,
                  encrypted: true,
                ));

  static const String boxName = 'service_templates_cache';
  static const String _templatesKey = 'templates_json';
  static const String _fetchedAtKey = 'fetched_at_epoch_ms';

  final Future<Box<dynamic>> Function() _boxOpener;

  @override
  Future<ServiceTemplateCacheEntry?> readCache() async {
    try {
      final box = await _boxOpener();
      final rawTemplates = box.get(_templatesKey);
      final rawFetchedAt = box.get(_fetchedAtKey);

      if (rawTemplates is! String || rawFetchedAt is! int) {
        return null;
      }

      final decoded = jsonDecode(rawTemplates);
      if (decoded is! List<dynamic>) {
        return null;
      }

      final models = decoded
          .map(
            (entry) => ServiceTemplateModel.fromJson(
              (entry as Map).cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);

      return ServiceTemplateCacheEntry(
        templates: models,
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(
          rawFetchedAt,
          isUtc: true,
        ),
      );
    } catch (error) {
      throw ServiceTemplateLocalException(
        'Failed to read template cache: $error',
      );
    }
  }

  @override
  Future<void> saveCache(
    List<ServiceTemplateModel> templates, {
    required DateTime fetchedAt,
  }) async {
    try {
      final box = await _boxOpener();
      final payload = templates.map((template) => template.toJson()).toList();

      await box.put(_templatesKey, jsonEncode(payload));
      await box.put(_fetchedAtKey, fetchedAt.toUtc().millisecondsSinceEpoch);
    } catch (error) {
      throw ServiceTemplateLocalException(
        'Failed to write template cache: $error',
      );
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await _boxOpener();
      await box.delete(_templatesKey);
      await box.delete(_fetchedAtKey);
    } catch (error) {
      throw ServiceTemplateLocalException(
        'Failed to clear template cache: $error',
      );
    }
  }
}
