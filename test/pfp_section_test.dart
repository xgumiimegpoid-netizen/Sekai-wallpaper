import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallpaper_app/models/wallpaper.dart';
import 'package:wallpaper_app/services/wallpaper_service.dart';
import 'package:wallpaper_app/theme/app_theme.dart';
import 'package:wallpaper_app/widgets/app_drawer.dart';
import 'package:wallpaper_app/widgets/category_grid.dart';

class EmptyCache extends Fake implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(String url,
          {String? key,
          Map<String, String>? headers,
          bool withProgress = false}) =>
      const Stream.empty();
}

void main() {
  late Directory directory;
  late ThemeSettings settings;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('pfp_test');
    Hive.init(directory.path);
    settings = ThemeSettings(await Hive.openBox<dynamic>('appearance'));
    CachedNetworkImageProvider.defaultCacheManager = EmptyCache();
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  testWidgets(
      'PFP grid is square in both themes and wallpaper grids stay portrait',
      (tester) async {
    for (final liquid in [false, true]) {
      await tester.runAsync(() => settings.setLiquid(liquid));
      for (final category in ['PFP', 'Anime']) {
        await tester.pumpWidget(ThemeScope(
            settings: settings,
            child: MaterialApp(
                home: CategoryGrid(
              categoryName: category,
              displayedList: [
                Wallpaper(
                    id: 'test',
                    title: 'Test',
                    author: '',
                    url: '',
                    category: category)
              ],
              totalCount: 1,
              hasMore: false,
              onLoadMore: () {},
              onRefresh: () async {},
            ))));
        final delegate = tester
            .widget<SliverGrid>(find.byType(SliverGrid))
            .gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.childAspectRatio, category == 'PFP' ? 1 : 0.6);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('All sections precede appearance and update controls',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AppDrawer(
                wallpapers: const {},
                onCategoryTap: (_) {},
                onCheckUpdates: () {}))));
    for (final category in CategoryData.categories) {
      expect(tester.getTopLeft(find.text(category.name)).dy,
          lessThan(tester.getTopLeft(find.text('Apariencia')).dy));
    }
    expect(tester.getTopLeft(find.text('Buscar actualizaciones')).dy,
        greaterThan(tester.getTopLeft(find.text('Apariencia')).dy));
    expect(CategoryData.categories.singleWhere((c) => c.name == 'PFP').url,
        endsWith('/pfp.json'));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
