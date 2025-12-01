import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to handle offline map tile caching and pre-downloading
class OfflineMapService {
  static const String _tileCacheDir = 'map_tiles';
  static const int _maxZoomLevel = 18;
  static const int _minZoomLevel = 10;
  
  static Directory? _cacheDirectory;
  static final Connectivity _connectivity = Connectivity();

  /// Initialize the cache directory
  static Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory(path.join(appDir.path, _tileCacheDir));
    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
  }

  /// Get the cache directory
  static Directory get cacheDirectory {
    if (_cacheDirectory == null) {
      throw Exception('OfflineMapService not initialized. Call initialize() first.');
    }
    return _cacheDirectory!;
  }

  /// Check if device is online
  static Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Get tile file path for a given tile coordinate
  static String _getTilePath(int x, int y, int z) {
    return path.join(cacheDirectory.path, '$z', '$x', '$y.png');
  }

  /// Download and cache a single tile
  static Future<bool> _downloadTile(int x, int y, int z) async {
    try {
      // OpenStreetMap tile URL
      final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final tileFile = File(_getTilePath(x, y, z));
        final tileDir = tileFile.parent;
        
        if (!await tileDir.exists()) {
          await tileDir.create(recursive: true);
        }

        await tileFile.writeAsBytes(response.bodyBytes);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading tile $z/$x/$y: $e');
      }
      return false;
    }
  }

  /// Check if a tile exists in cache
  static bool tileExists(int x, int y, int z) {
    final tileFile = File(_getTilePath(x, y, z));
    return tileFile.existsSync();
  }

  /// Get tile file if it exists in cache
  static File? getCachedTile(int x, int y, int z) {
    final tileFile = File(_getTilePath(x, y, z));
    if (tileFile.existsSync()) {
      return tileFile;
    }
    return null;
  }

  /// Convert lat/lng to tile coordinates
  static Map<String, int> latLngToTile(double lat, double lng, int zoom) {
    final n = math.pow(2, zoom).toInt();
    final x = ((lng + 180) / 360 * n).floor();
    final latRad = lat * math.pi / 180;
    final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n).floor();
    return {'x': x, 'y': y, 'z': zoom};
  }

  /// Get all tiles for a bounding box
  static List<Map<String, int>> _getTilesForBounds(
    double minLat,
    double minLng,
    double maxLat,
    double maxLng,
    int zoom,
  ) {
    final minTile = latLngToTile(maxLat, minLng, zoom);
    final maxTile = latLngToTile(minLat, maxLng, zoom);

    final tiles = <Map<String, int>>[];
    for (int x = minTile['x']!; x <= maxTile['x']!; x++) {
      for (int y = minTile['y']!; y <= maxTile['y']!; y++) {
        tiles.add({'x': x, 'y': y, 'z': zoom});
      }
    }
    return tiles;
  }

  /// Pre-download map tiles for a region
  /// [center] - Center point of the region
  /// [radiusKm] - Radius in kilometers to download
  /// [zoomLevels] - List of zoom levels to download (default: 10-16)
  /// [onProgress] - Callback with progress (downloaded/total)
  static Future<void> preDownloadRegion({
    required LatLng center,
    required double radiusKm,
    List<int>? zoomLevels,
    Function(int downloaded, int total)? onProgress,
  }) async {
    if (!await isOnline()) {
      throw Exception('Cannot download tiles: device is offline');
    }

    zoomLevels ??= List.generate(_maxZoomLevel - _minZoomLevel + 1, (i) => i + _minZoomLevel);

    // Calculate bounding box (approximate)
    // 1 degree latitude ≈ 111 km
    // 1 degree longitude ≈ 111 km * cos(latitude)
    final latOffset = radiusKm / 111.0;
    final lngOffset = radiusKm / (111.0 * math.cos(center.latitude * math.pi / 180));
    
    final minLat = center.latitude - latOffset;
    final maxLat = center.latitude + latOffset;
    final minLng = center.longitude - lngOffset;
    final maxLng = center.longitude + lngOffset;

    // Collect all tiles to download
    final allTiles = <Map<String, int>>[];
    for (final zoom in zoomLevels) {
      final tiles = _getTilesForBounds(minLat, minLng, maxLat, maxLng, zoom);
      allTiles.addAll(tiles);
    }

    // Remove tiles that already exist
    final tilesToDownload = allTiles.where((tile) {
      return !tileExists(tile['x']!, tile['y']!, tile['z']!);
    }).toList();

    if (kDebugMode) {
      print('Downloading ${tilesToDownload.length} tiles (${allTiles.length} total, ${allTiles.length - tilesToDownload.length} cached)');
    }

    // Download tiles with progress tracking
    int downloaded = 0;
    for (final tile in tilesToDownload) {
      final success = await _downloadTile(tile['x']!, tile['y']!, tile['z']!);
      if (success) {
        downloaded++;
      }
      
      if (onProgress != null) {
        onProgress(downloaded, tilesToDownload.length);
      }

      // Small delay to avoid overwhelming the server
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (kDebugMode) {
      print('Downloaded $downloaded/${tilesToDownload.length} tiles');
    }
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    if (_cacheDirectory == null || !await _cacheDirectory!.exists()) {
      return 0;
    }

    int totalSize = 0;
    await for (final entity in _cacheDirectory!.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  /// Clear all cached tiles
  static Future<void> clearCache() async {
    if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
      await for (final entity in _cacheDirectory!.list(recursive: true)) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }

  /// Get number of cached tiles
  static Future<int> getCachedTileCount() async {
    if (_cacheDirectory == null || !await _cacheDirectory!.exists()) {
      return 0;
    }

    int count = 0;
    await for (final entity in _cacheDirectory!.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.png')) {
        count++;
      }
    }
    return count;
  }
}

