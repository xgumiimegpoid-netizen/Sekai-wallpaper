import 'package:hive_flutter/hive_flutter.dart';
import '../models/wallpaper.dart';

class FavoritesServiceHive {
  static const _boxName = 'favorites';
  static late Box<Wallpaper> _box;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    Hive.registerAdapter(WallpaperAdapter());
    _box = await Hive.openBox<Wallpaper>(_boxName);
    _initialized = true;
  }

  static int get count => _box.length;

  static List<Wallpaper> getAll() {
    return _box.values.toList();
  }

  static bool isFavorite(String wallpaperId) {
    return _box.containsKey(wallpaperId);
  }

  static Future<void> add(Wallpaper wallpaper) async {
    if (isFavorite(wallpaper.id)) return;
    await _box.put(wallpaper.id, wallpaper);
  }

  static Future<void> remove(String wallpaperId) async {
    await _box.delete(wallpaperId);
  }

  static Future<void> toggle(Wallpaper wallpaper) async {
    if (isFavorite(wallpaper.id)) {
      await remove(wallpaper.id);
    } else {
      await add(wallpaper);
    }
  }

  static Future<void> clear() async {
    await _box.clear();
  }
}