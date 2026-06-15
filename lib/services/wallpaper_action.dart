import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class WallpaperManagerService {
  static const MethodChannel _channel = MethodChannel('com.wallpaper.app/wallpaper');

  static const int locationHome = 1;
  static const int locationLock = 2;
  static const int locationBoth = 3;

  final Map<String, Uint8List> _memoryCache = {};
  static const int _maxCacheEntries = 20;

  static Future<bool> isPlatformSupported() async => Platform.isAndroid;

  static Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    final photosStatus = await Permission.photos.status;
    if (photosStatus.isGranted) return true;

    final photosResult = await Permission.photos.request();
    if (photosResult.isGranted) return true;

    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;

    final storageResult = await Permission.storage.request();
    return storageResult.isGranted;
  }

  Future<Uint8List> downloadImage(String url, {bool useCache = true}) async {
    if (useCache && _memoryCache.containsKey(url)) {
      return _memoryCache[url]!;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to download image (${response.statusCode})');
    }

    final bytes = response.bodyBytes;
    if (useCache) {
      if (_memoryCache.length >= _maxCacheEntries) {
        _memoryCache.remove(_memoryCache.keys.first);
      }
      _memoryCache[url] = bytes;
    }
    return bytes;
  }

  Future<String> downloadImageToCache(String url) async {
    final bytes = await downloadImage(url);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/wp_temp_$timestamp.jpg');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<bool> saveToGallery(String url, {String? name}) async {
    final hasPermission = await requestStoragePermissions();
    if (!hasPermission) return false;

    final bytes = await downloadImage(url);
    final fileName = name ?? 'wallpaper_${DateTime.now().millisecondsSinceEpoch}';

    final result = await ImageGallerySaverPlus.saveImage(
      bytes,
      quality: 95,
      name: fileName,
    );

    return result['isSuccess'] == true;
  }

  Future<(bool, String?)> setWallpaperFromUrl(
    String url, {
    required int location,
  }) async {
    final path = await downloadImageToCache(url);
    return setWallpaperFromPath(path, location: location);
  }

  Future<(bool, String?)> setWallpaperFromPath(
    String path, {
    required int location,
  }) async {
    if (!Platform.isAndroid) {
      return (false, 'Esta función solo está disponible en Android');
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'setWallpaper',
        {'path': path, 'location': location},
      );

      if (result == null) {
        return (false, 'Error desconocido');
      }

      final success = result['success'] as bool? ?? false;
      final error = result['error'] as String?;
      return (success, error);
    } on PlatformException catch (e) {
      return (false, e.message ?? 'Error de plataforma');
    } catch (e) {
      return (false, e.toString());
    }
  }

  void clearCache() {
    _memoryCache.clear();
  }
}
