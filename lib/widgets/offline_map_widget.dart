import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide Marker;
import 'package:flutter_map/src/layer/marker_layer/marker_layer.dart' show Marker;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps_flutter;
import '../services/offline_map_service.dart';

/// Custom tile provider that uses cached tiles when available, falls back to network
class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final cachedTile = OfflineMapService.getCachedTile(
      coordinates.x.round(),
      coordinates.y.round(),
      coordinates.z.round(),
    );

    if (cachedTile != null && cachedTile.existsSync()) {
      // Use cached tile
      return FileImage(cachedTile);
    }

    // Fall back to network tile (OpenStreetMap)
    return NetworkImage(
      'https://tile.openstreetmap.org/${coordinates.z.round()}/${coordinates.x.round()}/${coordinates.y.round()}.png',
    );
  }
}

/// Offline-capable map widget using flutter_map
class OfflineMapWidget extends StatelessWidget {
  final latlong.LatLng center;
  final double zoom;
  final List<Marker>? markers;
  final List<CircleMarker>? circles;
  final MapController? mapController;
  final Function(TapPosition, latlong.LatLng)? onTap;
  final bool myLocationEnabled;
  final latlong.LatLng? currentLocation;

  const OfflineMapWidget({
    Key? key,
    required this.center,
    this.zoom = 14.0,
    this.markers,
    this.circles,
    this.mapController,
    this.onTap,
    this.myLocationEnabled = false,
    this.currentLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onTap: onTap != null
            ? (tapPosition, point) => onTap!(tapPosition, point)
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          tileProvider: CachedTileProvider(),
          maxZoom: 18,
          minZoom: 3,
          userAgentPackageName: 'com.tourguard.app',
        ),
        if (markers != null && markers!.isNotEmpty)
          MarkerLayer(markers: markers!),
        if (circles != null && circles!.isNotEmpty)
          CircleLayer(circles: circles!),
        // Current location marker - updates live with position changes
        if (myLocationEnabled && currentLocation != null)
          MarkerLayer(
            key: ValueKey('location_${currentLocation!.latitude}_${currentLocation!.longitude}'), // Force rebuild on position change
            markers: [
              Marker(
                point: currentLocation!,
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsing circle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    // Inner circle
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.4),
                      ),
                    ),
                    // Center dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Helper to convert Google Maps markers to flutter_map markers
class MapMarkerConverter {
  static List<Marker> convertGoogleMarkersToFlutterMap(
    Set<google_maps_flutter.Marker> googleMarkers,
  ) {
    return googleMarkers.map((gm) {
      return Marker(
        point: latlong.LatLng(gm.position.latitude, gm.position.longitude),
        width: 40,
        height: 40,
        child: Icon(
          Icons.location_on,
          color: Colors.red,
          size: 40,
        ),
      );
    }).toList();
  }
}

/// Helper to convert Google Maps circles to flutter_map circle markers
class MapCircleConverter {
  static List<CircleMarker> convertGoogleCirclesToFlutterMap(
    Set<google_maps_flutter.Circle> googleCircles,
  ) {
    return googleCircles.map((gc) {
      return CircleMarker(
        point: latlong.LatLng(gc.center.latitude, gc.center.longitude),
        radius: gc.radius,
        color: gc.fillColor,
        borderColor: gc.strokeColor,
        borderStrokeWidth: gc.strokeWidth.toDouble(),
        useRadiusInMeter: true,
      );
    }).toList();
  }
}

