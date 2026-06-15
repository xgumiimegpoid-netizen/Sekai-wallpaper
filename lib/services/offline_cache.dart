import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/wallpaper.dart';

class OfflineCache {
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/offline_wallpapers.json');
  }

  static Future<void> save(Map<String, List<Wallpaper>> wallpapers) async {
    try {
      final file = await _getFile();
      final data = wallpapers.map((category, list) => MapEntry(
        category,
        list.map((w) => {
          'id': w.id,
          'title': w.title,
          'author': w.author,
          'url': w.url,
          'category': w.category,
        }).toList(),
      ));
      await file.writeAsString(jsonEncode(data));
    } catch (e, stack) {
      debugPrint('OfflineCache.save error: $e\n$stack');
    }
  }

  static Future<Map<String, List<Wallpaper>>?> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      return decoded.map((category, list) => MapEntry(
        category,
        (list as List<dynamic>)
            .map((e) => Wallpaper.fromJson(e as Map<String, dynamic>, category))
            .toList(),
      ));
    } catch (e, stack) {
      debugPrint('OfflineCache.load error: $e\n$stack');
      return null;
    }
  }
}