import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/wallpaper.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._();
  factory FavoritesService() => _instance;
  FavoritesService._();

  List<Wallpaper> _favorites = [];
  bool _loaded = false;

  List<Wallpaper> get favorites => List.unmodifiable(_favorites);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await _load();
    notifyListeners();
  }

  Future<void> _load() async {
    _loaded = true;
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _favorites = list
            .map((e) => Wallpaper.fromJson(e as Map<String, dynamic>, e['category'] as String? ?? ''))
            .toList();
      }
    } catch (e, stack) {
      debugPrint('FavoritesService._load error: $e\n$stack');
    }
  }

  Future<void> _save() async {
    try {
      final file = await _getFile();
      final data = _favorites
          .map((w) => {
                'id': w.id,
                'title': w.title,
                'author': w.author,
                'url': w.url,
                'category': w.category,
              })
          .toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e, stack) {
      debugPrint('FavoritesService._save error: $e\n$stack');
    }
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/favorites.json');
  }

  Future<bool> isFavorite(String wallpaperId) async {
    await ensureLoaded();
    return _favorites.any((w) => w.id == wallpaperId);
  }

  Future<void> toggle(Wallpaper wallpaper) async {
    await ensureLoaded();
    final index = _favorites.indexWhere((w) => w.id == wallpaper.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(wallpaper);
    }
    await _save();
    notifyListeners();
  }

  Future<void> add(Wallpaper wallpaper) async {
    await ensureLoaded();
    if (_favorites.any((w) => w.id == wallpaper.id)) return;
    _favorites.add(wallpaper);
    await _save();
    notifyListeners();
  }

  Future<void> remove(String wallpaperId) async {
    await ensureLoaded();
    _favorites.removeWhere((w) => w.id == wallpaperId);
    await _save();
    notifyListeners();
  }
}