import 'package:flutter_project_agents/features/subscriptions/domain/entities/service_template.dart';

class ServiceTemplateModel {
  const ServiceTemplateModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.logoUrl,
    this.brandColor,
    this.aliases = const [],
    this.searchTerms = const [],
    this.isActive = true,
  });

  factory ServiceTemplateModel.fromEntity(ServiceTemplate entity) {
    return ServiceTemplateModel(
      id: entity.id,
      slug: entity.slug,
      name: entity.name,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      logoUrl: entity.logoUrl,
      brandColor: entity.brandColor,
      aliases: entity.aliases,
      searchTerms: entity.searchTerms,
      isActive: entity.isActive,
    );
  }

  factory ServiceTemplateModel.fromJson(Map<String, dynamic> json) {
    return ServiceTemplateModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      logoUrl: json['logo_url'] as String?,
      brandColor: json['brand_color'] as String?,
      aliases: (json['aliases'] as List<dynamic>? ?? const <dynamic>[])
          .map((entry) => entry as String)
          .toList(growable: false),
      searchTerms: (json['search_terms'] as List<dynamic>? ?? const <dynamic>[])
          .map((entry) => entry as String)
          .toList(growable: false),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String slug;
  final String name;
  final String? logoUrl;
  final String? brandColor;
  final List<String> aliases;
  final List<String> searchTerms;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceTemplate toEntity() {
    return ServiceTemplate(
      id: id,
      slug: slug,
      name: name,
      logoUrl: logoUrl,
      brandColor: brandColor,
      aliases: aliases,
      searchTerms: searchTerms,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'logo_url': logoUrl,
      'brand_color': brandColor,
      'aliases': aliases,
      'search_terms': searchTerms,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
