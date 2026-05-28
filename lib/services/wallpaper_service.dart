import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/wallpaper.dart';
import 'url_resolver.dart';

class CategoryData {
  final String name;
  final String url;
  final IconData icon;

  const CategoryData({required this.name, required this.url, required this.icon});

  static const baseUrl = 'https://raw.githubusercontent.com/xgumiimegpoid-netizen/Wallpapers/DATA';

  static const categories = [
    CategoryData(name: 'Anime', url: '$baseUrl/anime.json', icon: Icons.auto_awesome),
    CategoryData(name: 'Paisajes', url: '$baseUrl/paisajes.json', icon: Icons.landscape),
    CategoryData(name: 'Cyberpunk', url: '$baseUrl/cyberpunk.json', icon: Icons.electric_bolt),
    CategoryData(name: 'Fantasy/Sci-Fi', url: '$baseUrl/fantasy_scifi.json', icon: Icons.auto_awesome),
    CategoryData(name: 'Pokemon', url: '$baseUrl/pokemon.json', icon: Icons.catching_pokemon),
    CategoryData(name: 'Juegos', url: '$baseUrl/juegos.json', icon: Icons.sports_esports),
    CategoryData(name: 'Comunidad', url: '$baseUrl/community.json', icon: Icons.groups),
  ];
}

class WallpaperService {
  static final _cacheManager = CacheManager(
    Config(
      'wallpaper_jsons',
      stalePeriod: const Duration(hours: 1),
      maxNrOfCacheObjects: 50,
    ),
  );

  Future<Map<String, List<Wallpaper>>> loadAll() async {
    final futures = CategoryData.categories.map((cat) => _loadSingleCategory(cat));
    final results = await Future.wait(futures);

    final map = <String, List<Wallpaper>>{};
    for (final result in results) {
      map[result.$1] = result.$2;
    }
    return map;
  }

  Future<Wallpaper> _resolveUrl(Wallpaper wp) async {
    try {
      final resolved = await UrlResolver.resolve(wp.url);
      return Wallpaper(
        id: wp.id,
        title: wp.title,
        author: wp.author,
        url: wp.url,
        category: wp.category,
        resolvedUrl: resolved,
      );
    } catch (_) {
      return Wallpaper(
        id: wp.id,
        title: wp.title,
        author: wp.author,
        url: wp.url,
        category: wp.category,
        resolvedUrl: wp.url,
      );
    }
  }

  Future<(String, List<Wallpaper>)> _loadSingleCategory(CategoryData cat) async {
    try {
      final file = await _cacheManager.getSingleFile(
        cat.url,
        key: cat.name,
      ).timeout(const Duration(seconds: 15));

      final jsonString = await file.readAsString();
      final list = jsonDecode(jsonString) as List<dynamic>;
      final wallpapers = <Wallpaper>[];
      final urlResolveFutures = <Future<Wallpaper>>[];

      for (final e in list) {
        try {
          final wp = Wallpaper.fromJson(e as Map<String, dynamic>, cat.name);
          urlResolveFutures.add(_resolveUrl(wp));
        } catch (e) {
          debugPrint('Error parsing wallpaper in ${cat.name}: $e');
        }
      }

      final resolvedResults = await Future.wait(urlResolveFutures);
      wallpapers.addAll(resolvedResults.whereType<Wallpaper>());

      return (cat.name, wallpapers.reversed.toList());
    } catch (e) {
      debugPrint('Error loading category ${cat.name}: $e');
      return (cat.name, <Wallpaper>[]);
    }
  }
}
