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
  test('Offline serialization preserves resolved Drive URLs', () {
    final wallpaper = Wallpaper(
      id: 'drive-1',
      title: 'Drive',
      author: 'Author',
      url: 'https://drive.google.com/file/d/example/view',
      category: 'Anime',
      resolvedUrl: 'https://lh3.googleusercontent.com/d/example=w1600',
    );
    final restored = Wallpaper.fromJson(wallpaper.toJson(), wallpaper.category);
    expect(restored.resolvedUrl, wallpaper.resolvedUrl);
    expect(restored.url, wallpaper.url);
  });

  test('Wallpaper rejects missing required fields', () {
    expect(() => Wallpaper.fromJson({'id': 'missing-url'}, 'Anime'),
        throwsFormatException);
  });
}
