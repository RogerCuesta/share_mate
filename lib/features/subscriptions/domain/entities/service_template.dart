/// Canonical catalog template sourced from Supabase service_templates.
class ServiceTemplate {
  const ServiceTemplate({
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
}
