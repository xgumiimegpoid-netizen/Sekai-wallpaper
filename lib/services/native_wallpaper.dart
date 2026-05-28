import 'dart:io';
import 'package:flutter/services.dart';

class NativeWallpaper {
  static const MethodChannel _channel = MethodChannel('com.wallpaper.app/wallpaper');

  static const int homeScreen = 1;
  static const int lockScreen = 2;
  static const int bothScreens = 3;

  static Future<bool> isPlatformSupported() async {
    return Platform.isAndroid;
  }

  static Future<(bool, String?)> setWallpaperFromPath(String path, int location) async {
    if (!Platform.isAndroid) {
      return (false, 'Setting wallpaper directly is only supported on Android');
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'setWallpaper',
        {'path': path, 'location': location},
      );

      if (result == null) {
        return (false, 'Unknown error');
      }

      final success = result['success'] as bool? ?? false;
      final error = result['error'] as String?;
      return (success, error);
    } on PlatformException catch (e) {
      return (false, e.message ?? 'Platform error');
    } catch (e) {
      return (false, e.toString());
    }
  }

  static Future<(bool, String?)> setWallpaperHomeScreen(String path) {
    return setWallpaperFromPath(path, homeScreen);
  }

  static Future<(bool, String?)> setWallpaperLockScreen(String path) {
    return setWallpaperFromPath(path, lockScreen);
  }

  static Future<(bool, String?)> setWallpaperBoth(String path) {
    return setWallpaperFromPath(path, bothScreens);
  }
}
