import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/wallpaper.dart';

class OfflineCache {
  static Future<File> _getFile() async {
    final dir = await getTemporaryDirectory();
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
    } catch (_) {}
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
    } catch (_) {
      return null;
    }
  }
}