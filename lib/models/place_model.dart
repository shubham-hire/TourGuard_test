class Place {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final String distance;
  final double rating;
  final int userRatingsTotal;
  final double latitude;
  final double longitude;
  final bool isOpen;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.distance,
    required this.rating,
    this.userRatingsTotal = 0,
    required this.latitude,
    required this.longitude,
    this.isOpen = false,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    final geometry = (json['geometry']?['location']) ?? {};
    final photos = json['photos'] as List<dynamic>?;
    final types = (json['types'] as List<dynamic>?)
        ?.map((type) => type.toString())
        .toList();

    return Place(
      id: json['place_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown Place',
      description: json['vicinity'] ??
          json['formatted_address'] ??
          'No description provided',
      imageUrl: _resolveImageUrl(photos, json['name'] as String?),
      category: _deriveCategory(types),
      distance: '0 km', // Calculated after fetch
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      userRatingsTotal: (json['user_ratings_total'] as num?)?.toInt() ??
          (json['userRatingsTotal'] as num?)?.toInt() ??
          0,
      latitude: (geometry['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (geometry['lng'] as num?)?.toDouble() ?? 0.0,
      isOpen: (json['opening_hours']?['open_now'] as bool?) ??
          (json['openingHours']?['open_now'] as bool?) ??
          false,
    );
  }

  static String _resolveImageUrl(
    List<dynamic>? photos,
    String? placeName,
  ) {
    if (photos != null && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String && first.isNotEmpty) {
        return first;
      }
    }
    final fallback = placeName ?? 'Place';
    return 'https://placehold.co/400x200/png?text=${Uri.encodeComponent(fallback)}';
  }

  static String _deriveCategory(List<String>? types) {
    if (types == null || types.isEmpty) {
      return 'place';
    }
    const orderedTypes = [
      'tourist_attraction',
      'restaurant',
      'amusement_park',
      'park',
    ];
    for (final type in orderedTypes) {
      if (types.contains(type)) {
        return type;
      }
    }
    return types.first;
  }
}

class PlaceCategory {
  final String id;
  final String name;
  final bool isSelected;

  PlaceCategory({
    required this.id,
    required this.name,
    required this.isSelected,
  });

  PlaceCategory copyWith({bool? isSelected}) {
    return PlaceCategory(
      id: id,
      name: name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}