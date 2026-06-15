import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
    } else if (trimmed.contains('pinterest.com') || trimmed.contains('pin.it')) {
      resolved = await _resolvePinterest(trimmed);
    }

    final result = resolved ?? trimmed;
    if (resolved != null) {
      await UrlCache.set(trimmed, result);
    }
    return result;
  }

  static Future<String?> _resolvePinterest(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = response.body;
        final regex = RegExp(
          r'<meta\s+[^>]*content="([^"]+)"[^>]*property="og:image"',
          caseSensitive: false,
        );
        var match = regex.firstMatch(body);
        if (match != null) return match.group(1)!;
        final regex2 = RegExp(
          r'<meta\s+[^>]*property="og:image"[^>]*content="([^"]+)"',
          caseSensitive: false,
        );
        match = regex2.firstMatch(body);
        if (match != null) return match.group(1)!;
      }
    } catch (e, stack) {
      debugPrint('UrlResolver._resolvePinterest error: $e\n$stack');
      return null;
    }
    return null;
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