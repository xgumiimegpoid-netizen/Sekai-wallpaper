import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wallpaper_app/services/image_sources.dart';
import 'package:wallpaper_app/services/wallpaper_action.dart';

void main() {
  const path =
      'wallpapers/cyberpunk/9fd54f94236b4d09eafe088e0e073a5e8ba4cf93a2ef432ee19238c6bd02bb2a.webp';
  const cdn =
      'https://cdn.jsdelivr.net/gh/xgumiimegpoid-netizen/Wallpapers@DATA/$path';
  const raw =
      'https://raw.githubusercontent.com/xgumiimegpoid-netizen/Wallpapers/DATA/$path';
  test(
      'Cyberpunk catalog URL gets direct GitHub source without changing its path',
      () {
    expect(imageSources(cdn), [raw, cdn]);
    expect(imageSources(raw), [raw]);
    expect(imageSources('https://example.com/image.jpg'),
        ['https://example.com/image.jpg']);
  });
  test('Downloads recover from direct source failure through the CDN',
      () async {
    final requests = <String>[];
    await http.runWithClient(() async {
      final bytes = await WallpaperManagerService().downloadImage(cdn);
      expect(bytes, [82, 73, 70, 70]);
      expect(requests, [raw, cdn]);
    },
        () => MockClient((request) async {
              requests.add(request.url.toString());
              return request.url.toString() == raw
                  ? http.Response('not found', 404)
                  : http.Response.bytes([82, 73, 70, 70], 200,
                      headers: {'content-type': 'image/webp'});
            }));
  });
}
