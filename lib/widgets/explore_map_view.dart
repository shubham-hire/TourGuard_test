import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:url_launcher/url_launcher.dart';
import '../models/place_model.dart';
import '../widgets/offline_map_widget.dart';
import 'package:geolocator/geolocator.dart';

/// Map view widget for the explore screen that displays places on an interactive map
class ExploreMapView extends StatelessWidget {
  final List<Place> places;
  final Position? currentPosition;
  final Function(Place)? onPlaceTap;
  final String selectedCategory;

  const ExploreMapView({
    Key? key,
    required this.places,
    this.currentPosition,
    this.onPlaceTap,
    this.selectedCategory = 'all',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentPosition == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final center = latlong.LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    // Create markers for places
    final placeMarkers = places.map((place) {
      return Marker(
        point: latlong.LatLng(place.latitude, place.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => onPlaceTap?.call(place),
          child: _buildPlaceMarker(place),
        ),
      );
    }).toList();

    // Create accuracy circle for user location
    final accuracyCircle = currentPosition!.accuracy > 0
        ? CircleMarker(
            point: center,
            radius: currentPosition!.accuracy,
            color: Colors.blue.withOpacity(0.2),
            borderColor: Colors.blue.withOpacity(0.5),
            borderStrokeWidth: 2,
            useRadiusInMeter: true,
          )
        : null;

    return Stack(
      children: [
        OfflineMapWidget(
          center: center,
          zoom: 14.0,
          markers: placeMarkers,
          circles: accuracyCircle != null ? [accuracyCircle] : null,
          myLocationEnabled: true,
          currentLocation: center,
        ),
        // Floating action button to center on user location
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            mini: true,
            onPressed: () {
              // The map will automatically center on currentLocation when it changes
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceMarker(Place place) {
    // Different colors for different categories
    Color markerColor;
    IconData iconData;

    switch (place.category) {
      case 'tourist_attraction':
        markerColor = Colors.purple;
        iconData = Icons.camera_alt;
        break;
      case 'restaurant':
        markerColor = Colors.orange;
        iconData = Icons.restaurant;
        break;
      case 'amusement_park':
        markerColor = Colors.green;
        iconData = Icons.attractions;
        break;
      case 'park':
        markerColor = Colors.teal;
        iconData = Icons.park;
        break;
      default:
        markerColor = Colors.red;
        iconData = Icons.place;
    }

    return Container(
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: markerColor.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

/// Bottom sheet that shows place details when a marker is tapped
class PlaceDetailsBottomSheet extends StatelessWidget {
  final Place place;
  final Position? currentPosition;

  const PlaceDetailsBottomSheet({
    Key? key,
    required this.place,
    this.currentPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String distanceText = place.distance;
    if (currentPosition != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        place.latitude,
        place.longitude,
      );
      distanceText = '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Place name
          Text(
            place.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Category and distance
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  place.category.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                distanceText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            place.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          if (place.rating > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  place.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (place.userRatingsTotal > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${place.userRatingsTotal} reviews)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 20),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

