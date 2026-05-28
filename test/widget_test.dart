import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_app/models/wallpaper.dart';

void main() {
  test('Wallpaper parses from JSON correctly', () {
    final json = {
      'id': 'test-1',
      'title': 'Test Title',
      'author': 'Test Author',
      'url': 'https://example.com/image.jpg',
    };
    final wp = Wallpaper.fromJson(json, 'Anime');
    expect(wp.id, 'test-1');
    expect(wp.title, 'Test Title');
    expect(wp.author, 'Test Author');
    expect(wp.url, 'https://example.com/image.jpg');
    expect(wp.category, 'Anime');
    expect(wp.resolvedUrl, wp.url);
  });

  test('Wallpaper handles missing optional fields', () {
    final json = {
      'id': 'test-2',
      'url': 'https://example.com/image.jpg',
    };
    final wp = Wallpaper.fromJson(json, 'Paisajes');
    expect(wp.id, 'test-2');
    expect(wp.title, 'Untitled');
    expect(wp.author, 'Unknown');
    expect(wp.category, 'Paisajes');
    expect(wp.resolvedUrl, wp.url);
  });
}
