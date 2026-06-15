import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/wallpaper.dart';
import '../services/wallpaper_action.dart';
import '../services/favorites_service.dart';
import '../screens/preview_screen.dart';

WallpaperManagerService _service() => WallpaperManagerService();
final _favorites = FavoritesService();

Future<void> shareWallpaper(Wallpaper w) async {
  try {
    final path = await _service().downloadImageToCache(w.resolvedUrl);
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Mira este wallpaper: ${w.title}',
      subject: 'Wallpaper: ${w.title}',
    );
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e, stack) {
    debugPrint('shareWallpaper error: $e\n$stack');
  }
}

void showWallpaperActions(BuildContext ctx, Wallpaper w) {
  showModalBottomSheet(
    context: ctx,
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              w.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.open_in_full),
            title: const Text('Abrir'),
            onTap: () {
              Navigator.pop(sheetCtx);
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => PreviewScreen(wallpaper: w)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Compartir'),
            onTap: () {
              Navigator.pop(sheetCtx);
              shareWallpaper(w);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Añadir a Favoritos'),
            onTap: () {
              Navigator.pop(sheetCtx);
              _favorites.add(w);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Añadido a favoritos'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
