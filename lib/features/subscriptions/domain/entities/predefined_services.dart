// lib/features/subscriptions/domain/entities/predefined_services.dart

/// Predefined subscription service with icon and color
class PredefinedService {

  const PredefinedService({
    required this.name,
    required this.color,
    this.iconName,
    this.iconText,
  });
  final String name;
  final String color;
  final String? iconName;
  final String? iconText;
}

/// Helper class with predefined subscription services
class PredefinedServices {
  PredefinedServices._();

  /// List of predefined subscription services
  static const List<PredefinedService> services = [
    PredefinedService(
      name: 'Netflix',
      color: '#E50914',
      iconText: 'N',
    ),
    PredefinedService(
      name: 'Spotify',
      color: '#1DB954',
      iconName: 'music_note',
    ),
    PredefinedService(
      name: 'HBO Max',
      color: '#8A2BE2',
      iconText: 'HBO',
    ),
    PredefinedService(
      name: 'Prime Video',
      color: '#00A8E1',
      iconText: 'P',
    ),
    PredefinedService(
      name: 'Amazon Prime',
      color: '#FF9900',
      iconName: 'shopping_bag',
    ),
    PredefinedService(
      name: 'Hulu',
      color: '#1CE783',
      iconText: 'hulu',
    ),
    PredefinedService(
      name: 'Crunchyroll',
      color: '#F47521',
      iconText: 'CR',
    ),
    PredefinedService(
      name: 'Custom',
      color: '#666666',
      iconName: 'add_circle_outline',
    ),
  ];

  /// Get service by name
  static PredefinedService? getServiceByName(String name) {
    try {
      return services.firstWhere(
        (service) => service.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get color for service name (returns default if not found)
  static String getColorForService(String name) {
    final service = getServiceByName(name);
    return service?.color ?? '#666666';
  }

  /// Check if service name is predefined
  static bool isPredefined(String name) {
    return getServiceByName(name) != null;
  }
}
