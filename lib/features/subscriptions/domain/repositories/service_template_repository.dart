import 'package:flutter_project_agents/features/subscriptions/domain/entities/service_template.dart';

class ServiceTemplateCatalogSnapshot {
  const ServiceTemplateCatalogSnapshot({
    required this.templates,
    required this.isStale,
    this.fetchedAt,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final List<ServiceTemplate> templates;
  final DateTime? fetchedAt;
  final bool isStale;
  final bool isRefreshing;
  final String? errorMessage;

  bool get hasData => templates.isNotEmpty;
}

abstract class ServiceTemplateRepository {
  Stream<ServiceTemplateCatalogSnapshot> watchCatalog({
    bool forceRefresh = false,
  });

  Future<ServiceTemplateCatalogSnapshot> refreshCatalog();
}
