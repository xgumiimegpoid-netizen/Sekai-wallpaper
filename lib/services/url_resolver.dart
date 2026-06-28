import 'url_cache.dart';

class UrlResolver {
  static Future<String> resolve(String url) async {
    final trimmed = url.trim();

    final cached = await UrlCache.get(trimmed);
    if (cached != null) return cached;

    String? resolved;

    if (trimmed.contains('drive.google.com')) {
      final id = _extractDriveId(trimmed);
      if (id != null) {
        resolved = 'https://lh3.googleusercontent.com/d/$id=w1600';
      }
    }

    final result = resolved ?? trimmed;
    if (resolved != null) {
      await UrlCache.set(trimmed, result);
    }
    return result;
  }

  static String? _extractDriveId(String url) {
    final patterns = [
      RegExp(r'/file/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'[?&]id=([a-zA-Z0-9_-]+)'),
      RegExp(r'open\?id=([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }
}
