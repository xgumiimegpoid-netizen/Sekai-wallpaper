import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_app/models/wallpaper.dart';
import 'package:wallpaper_app/widgets/wallpaper_image.dart';

class EmptyCache extends Fake implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(String url,
          {String? key,
          Map<String, String>? headers,
          bool withProgress = false}) =>
      const Stream.empty();
}

void main() {
  setUp(() {
    CachedNetworkImageProvider.defaultCacheManager = EmptyCache();
  });
  testWidgets('PFP stays square even inside a portrait favorites card',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: SizedBox(
      width: 180,
      height: 300,
      child: WallpaperImage(
          wallpaper: Wallpaper(
              id: 'pfp',
              title: 'Perfil',
              author: '',
              url: '',
              category: 'PFP')),
    ))));
    expect(
        tester.getSize(find.byType(CachedNetworkImage)), const Size(180, 180));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Portrait and landscape thumbnails retain source proportions',
      (tester) async {
    final wallpaper = Wallpaper(
        id: 'aspect', title: 'Test', author: '', url: '', category: 'Test');
    await tester.pumpWidget(MaterialApp(
        home: SizedBox(
      width: 180,
      height: 300,
      child: WallpaperImage(wallpaper: wallpaper),
    )));
    final image =
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    await tester.runAsync(() async {
      for (final size in [const Size(40, 100), const Size(100, 40)]) {
        final recorder = ui.PictureRecorder();
        Canvas(recorder)
            .drawRect(Offset.zero & size, Paint()..color = Colors.blue);
        final picture = recorder.endRecording();
        final source =
            await picture.toImage(size.width.toInt(), size.height.toInt());
        final png = (await source.toByteData(format: ui.ImageByteFormat.png))!;
        final codec = await ui.instantiateImageCodec(
          png.buffer.asUint8List(),
          targetWidth: image.memCacheWidth,
          targetHeight: image.memCacheHeight,
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width / frame.image.height,
            closeTo(size.aspectRatio, 0.001),
            reason:
                'Decoding must preserve proportions before fitting to a card');
        frame.image.dispose();
        codec.dispose();
        source.dispose();
        picture.dispose();
      }
    });
    expect(image.fit, BoxFit.cover);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
