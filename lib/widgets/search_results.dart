import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/wallpaper.dart';
import '../services/wallpaper_action.dart';
import '../services/favorites_service.dart';
import 'wallpaper_image.dart';
import '../screens/preview_screen.dart';

class SearchResults extends StatelessWidget {
  final List<Wallpaper> results;
  final String query;

  const SearchResults({
    super.key,
    required this.results,
    required this.query,
  });

  Future<void> _shareWallpaper(BuildContext ctx, Wallpaper w) async {
    try {
      final service = WallpaperManagerService();
      final path = await service.downloadImageToCache(w.resolvedUrl);
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Mira este wallpaper: ${w.title}',
        subject: 'Wallpaper: ${w.title}',
      );
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  void _showQuickActions(BuildContext ctx, Wallpaper w) {
    final favoritesService = FavoritesService();
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
                _shareWallpaper(ctx, w);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Añadir a Favoritos'),
              onTap: () {
                Navigator.pop(sheetCtx);
                favoritesService.add(w);
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

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              query.isEmpty
                  ? 'Escribe para buscar'
                  : 'No se encontraron resultados para "$query"',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              'Busca por título, autor o categoría',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              Icon(Icons.search, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${results.length} resultado${results.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.6,
            ),
            itemCount: results.length,
            itemBuilder: (ctx, i) {
              final w = results[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => PreviewScreen(wallpaper: w)),
                ),
                onLongPress: () => _showQuickActions(ctx, w),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: WallpaperImage(wallpaper: w),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          w.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}