import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place_model.dart';
import '../widgets/place_card.dart';
import '../widgets/filter_chip.dart';
import '../widgets/shimmer_place_card.dart';
import '../services/localization_service.dart';
import '../services/places_api_service.dart';
import '../services/location_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedCategoryId = 'all';
  List<Place> _places = [];
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  String? _locationStatus;

  List<PlaceCategory> get _categories => [
        PlaceCategory(
            id: 'all',
            name: tr('all'),
            isSelected: _selectedCategoryId == 'all'),
        PlaceCategory(
            id: 'tourist_attraction',
            name: tr('famous'),
            isSelected: _selectedCategoryId == 'tourist_attraction'),
        PlaceCategory(
            id: 'restaurant',
            name: tr('food'),
            isSelected: _selectedCategoryId == 'restaurant'),
        PlaceCategory(
            id: 'amusement_park',
            name: tr('adventure'),
            isSelected: _selectedCategoryId == 'amusement_park'),
        PlaceCategory(
            id: 'park',
            name: tr('hidden_gems'), // Mapping 'park' to hidden gems for demo
            isSelected: _selectedCategoryId == 'park'),
      ];

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _locationStatus = null;
    });

    try {
      // Get current location via helper (handles permissions & services)
      _currentPosition = await LocationService.getCurrentLocation();

      // Fetch places from API within 50 km radius
      final places = await PlacesApiService.fetchNearbyPlaces(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 50000, // 50 km radius for dynamic suggestions
        type: _selectedCategoryId,
      );

      if (mounted) {
        setState(() {
          _places = places;
          _isLoading = false;
        });
      }
    } on LocationServiceException catch (e) {
      if (mounted) {
        setState(() {
          _locationStatus = e.message;
          _errorMessage = e.message;
          _isLoading = false;
          _places = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _fetchPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, language, _) {
        return _buildExplore();
      },
    );
  }

  Widget _buildExplore() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _fetchPlaces,
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 24), // Top padding
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('explore_nashik'), // Consider making this dynamic too
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _fetchPlaces(),
                        icon: Icon(Icons.refresh, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),

                _buildLocationBanner(),

                // Filter Chips
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChipWidget(
                          category: category,
                          onSelected: _onCategorySelected,
                        ),
                      );
                    },
                  ),
                ),

                // Places List
                Expanded(
                  child: _buildPlacesList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesList() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const PlaceCardShimmer(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading places',
              style: TextStyle(fontSize: 18, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPlaces,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.place_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No places found nearby',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PlaceCard(place: place),
        );
      },
    );
  }

  Widget _buildLocationBanner() {
    final position = _currentPosition;
    final locationText = position != null
        ? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'
        : (_locationStatus ?? 'Detecting your location...');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[50],
            ),
            child: Icon(Icons.my_location, color: Colors.blue[800]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('current_location'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locationText,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                if (_locationStatus != null && position == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _locationStatus!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : () => _fetchPlaces(),
            icon: Icon(Icons.refresh, color: Colors.blue[800]),
            tooltip: 'Refresh location',
          ),
        ],
      ),
    );
  }
}