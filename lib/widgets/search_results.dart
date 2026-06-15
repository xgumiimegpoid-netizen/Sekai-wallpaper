import 'package:flutter/material.dart';
import '../models/wallpaper.dart';
import 'wallpaper_image.dart';
import 'wallpaper_actions.dart';
import '../screens/preview_screen.dart';

class SearchResults extends StatelessWidget {
  final List<Wallpaper> results;
  final String query;

  const SearchResults({
    super.key,
    required this.results,
    required this.query,
  });



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
              return Semantics(
                label: '${w.title}${w.author.isNotEmpty ? " por ${w.author}" : ""} — ${w.category}',
                onTapHint: 'Abrir vista previa',
                onLongPressHint: 'Mostrar acciones',
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(builder: (_) => PreviewScreen(wallpaper: w)),
                  ),
                  onLongPress: () => showWallpaperActions(ctx, w),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}