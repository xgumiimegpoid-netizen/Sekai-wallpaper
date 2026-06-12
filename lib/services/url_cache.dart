import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UrlCache {
  static Map<String, String>? _cache;
  static bool _dirty = false;

  static Future<Map<String, String>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/url_cache.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        _cache = decoded.map((k, v) => MapEntry(k, v as String));
      } else {
        _cache = {};
      }
    } catch (_) {
      _cache = {};
    }
    return _cache!;
  }

  static Future<void> _save() async {
    if (!_dirty || _cache == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/url_cache.json');
      await file.writeAsString(jsonEncode(_cache));
      _dirty = false;
    } catch (_) {}
  }

  static Future<String?> get(String originalUrl) async {
    final cache = await _load();
    return cache[originalUrl];
  }

  static Future<void> set(String originalUrl, String resolvedUrl) async {
    final cache = await _load();
    cache[originalUrl] = resolvedUrl;
    _dirty = true;
    _save();
  }
}