import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/wallpaper.dart';
import '../services/wallpaper_action.dart';
import '../services/favorites_service.dart';
import '../widgets/wallpaper_image.dart';
import '../screens/preview_screen.dart';

class CategoryGrid extends StatefulWidget {
  final String categoryName;
  final List<Wallpaper> displayedList;
  final int totalCount;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  const CategoryGrid({
    super.key,
    required this.categoryName,
    required this.displayedList,
    required this.totalCount,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
  });

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  final _scrollController = ScrollController();
  final _favoritesService = FavoritesService();
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(CategoryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayedList.length > oldWidget.displayedList.length) {
      _loadingMore = false;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || _loadingMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 300) {
      _loadingMore = true;
      widget.onLoadMore();
    }
  }

  Future<void> _shareWallpaper(Wallpaper w) async {
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
                _shareWallpaper(w);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Añadir a Favoritos'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _favoritesService.add(w);
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
    if (widget.displayedList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text('No wallpapers en ${widget.categoryName}'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.6,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final w = widget.displayedList[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => PreviewScreen(wallpaper: w)),
                    ),
                    onLongPress: () => _showQuickActions(ctx, w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: WallpaperImage(wallpaper: w),
                    ),
                  );
                },
                childCount: widget.displayedList.length,
              ),
            ),
          ),
          if (widget.hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          if (!widget.hasMore && widget.displayedList.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Mostrando los ${widget.totalCount} wallpapers de ${widget.categoryName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}