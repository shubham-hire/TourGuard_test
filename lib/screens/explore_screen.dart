import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../widgets/place_card.dart';
import '../widgets/filter_chip.dart';
import '../widgets/shimmer_place_card.dart';
import '../widgets/explore_map_view.dart';
import '../services/localization_service.dart';
import '../services/places_api_service.dart';
import '../services/location_service.dart';
import '../services/itinerary_service.dart';
import '../screens/safe_itinerary_screen.dart';
import 'package:tourguard/core/constants/app_colors.dart'; // Added theme import

enum ViewMode { list, map }

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
  String _currentAddress = 'Detecting location...';
  ViewMode _viewMode = ViewMode.list;

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
      
      // Fetch address
      if (_currentPosition != null) {
        _currentAddress = await LocationService.getAddressFromCoordinates(
          _currentPosition!.latitude, 
          _currentPosition!.longitude
        );
      }

      // Fetch places from API within 50 km radius
      final places = await PlacesApiService.fetchNearbyPlaces(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 50000, 
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
      backgroundColor: AppColors.surfaceWhite,
      body: RefreshIndicator(
        onRefresh: _fetchPlaces,
        color: AppColors.saffron,
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 50), // Top padding for status bar

                // Padding and Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                       _buildCreativeHeader('Explore', Icons.explore_rounded),
                       const SizedBox(height: 12), // Reduced from 20
                       _buildLocationBanner(),
                    ],
                  ),
                ),

                const SizedBox(height: 8), // Reduced from 16

                // Filter Chips
                Container(
                  height: 40, // Reduced from 50
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8), // Reduced from 10
                        child: FilterChip(
                          label: Text(category.name),
                          selected: category.isSelected,
                          onSelected: (_) => _onCategorySelected(category.id),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.saffron,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: category.isSelected ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12, // Slightly smaller font
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16), // Smaller radius
                            side: BorderSide(
                              color: category.isSelected ? Colors.transparent : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                          visualDensity: VisualDensity.compact,
                          elevation: category.isSelected ? 2 : 0,
                          shadowColor: AppColors.saffron.withOpacity(0.3),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 4), // Reduced from 8

                // View Mode & Places List/Map
                Expanded(
                  child: _viewMode == ViewMode.map
                      ? _buildMapView()
                      : _buildPlacesList(),
                ),
              ],
            ),
             // Floating View Toggle Button
             Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.navyBlue,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                         BoxShadow(color: AppColors.navyBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewModeButton(icon: Icons.list_rounded, mode: ViewMode.list, tooltip: 'List View'),
                        _buildViewModeButton(icon: Icons.map_rounded, mode: ViewMode.map, tooltip: 'Map View'),
                      ],
                    ),
                  ),
                ),
             ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60), // Add padding to avoid overlap with bottom nav
        child: _buildItineraryButton(),
      ),
    );
  }

  Widget _buildCreativeHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.saffron.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.saffron, size: 24),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.navyBlue,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
           onPressed: _fetchPlaces,
           icon: const Icon(Icons.refresh_rounded),
           color: AppColors.textGrey,
           style: IconButton.styleFrom(backgroundColor: Colors.white, highlightColor: AppColors.saffron.withOpacity(0.1)),
        ),
      ],
    );
  }

  Widget _buildLocationBanner() {
    final position = _currentPosition;
    final locationText = position != null
        ? _currentAddress
        : (_locationStatus ?? 'Detecting your location...');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.saffron, Colors.white, AppColors.indiaGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.0), // Border width
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.navyBlue.withOpacity(0.05),
              ),
              child: const Icon(Icons.my_location_rounded, color: AppColors.navyBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('current_location'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locationText,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required ViewMode mode,
    required String tooltip,
  }) {
    final isSelected = _viewMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _viewMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildItineraryButton() {
    final itineraryService = ItineraryService();
    final stopCount = itineraryService.stopCount;

    return FloatingActionButton.extended(
      onPressed: () async {
        // Initialize itinerary if needed
        if (itineraryService.currentItinerary == null && _currentPosition != null) {
          itineraryService.createItinerary(
            title: 'My Safe Trip',
            date: DateTime.now(),
            startLocation: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          );
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SafeItineraryScreen(),
          ),
        );
        setState(() {}); // Refresh to update badge
      },
      icon: Badge(
        label: Text('$stopCount'),
        isLabelVisible: stopCount > 0,
        backgroundColor: AppColors.saffron,
        child: const Icon(Icons.map_outlined),
      ),
      label: const Text('My Trip'),
      backgroundColor: AppColors.navyBlue,
      foregroundColor: Colors.white,
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
        return PlaceCard(
          place: place,
          onAddToItinerary: () => _addToItinerary(place),
        );
      },
    );
  }

  void _addToItinerary(Place place) {
    final itineraryService = ItineraryService();
    
    // Initialize itinerary if needed
    if (itineraryService.currentItinerary == null && _currentPosition != null) {
      itineraryService.createItinerary(
        title: 'My Safe Trip',
        date: DateTime.now(),
        startLocation: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
    }

    // Add place to itinerary
    itineraryService.addStop(
      name: place.name,
      location: LatLng(place.latitude, place.longitude),
      category: place.category,
      description: place.description,
    );

    setState(() {}); // Refresh to update button badge

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Added "${place.name}" to itinerary'),
        action: SnackBarAction(
          label: 'VIEW',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SafeItineraryScreen(),
              ),
            );
          },
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }



  Widget _buildMapView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
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
              'Error loading map',
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
            Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No places found nearby',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ExploreMapView(
      places: _places,
      currentPosition: _currentPosition,
      selectedCategory: _selectedCategoryId,
      onPlaceTap: (place) {
        // Show bottom sheet with place details
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PlaceDetailsBottomSheet(
            place: place,
            currentPosition: _currentPosition,
          ),
        );
      },
    );
  }
}