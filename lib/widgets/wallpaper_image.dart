import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/wallpaper.dart';
import '../services/image_sources.dart';

class WallpaperImage extends StatefulWidget {
  final Wallpaper wallpaper;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool thumbnail;

  const WallpaperImage({
    super.key,
    required this.wallpaper,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.thumbnail = true,
  });

  @override
  State<WallpaperImage> createState() => _WallpaperImageState();
}

class _WallpaperImageState extends State<WallpaperImage> {
  late List<String> _urlsToTry;
  int _currentIndex = 0;
  bool _hasTriedNext = false;

  @override
  void initState() {
    super.initState();
    _urlsToTry = _buildUrlList();
  }

  @override
  void didUpdateWidget(covariant WallpaperImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallpaper.url != widget.wallpaper.url ||
        oldWidget.wallpaper.resolvedUrl != widget.wallpaper.resolvedUrl ||
        oldWidget.thumbnail != widget.thumbnail) {
      _urlsToTry = _buildUrlList();
      _currentIndex = 0;
      _hasTriedNext = false;
    }
  }

  List<String> _buildUrlList() {
    final urls = <String>[];
    final resolved = widget.wallpaper.resolvedUrl;
    final original = widget.wallpaper.url;

    if (widget.thumbnail) {
      if (resolved.isNotEmpty && !urls.contains(resolved)) urls.add(resolved);
      if (original.isNotEmpty && !urls.contains(original)) urls.add(original);

      if (original.contains('drive.google.com')) {
        final id = _extractDriveId(original);
        if (id != null) {
          final thumbUrl = 'https://drive.google.com/thumbnail?id=$id&sz=w1024';
          if (!urls.contains(thumbUrl)) urls.add(thumbUrl);
          final largeThumbUrl =
              'https://drive.google.com/thumbnail?id=$id&sz=w1600';
          if (!urls.contains(largeThumbUrl)) urls.add(largeThumbUrl);
          final ucUrl = 'https://drive.google.com/uc?export=view&id=$id';
          if (!urls.contains(ucUrl)) urls.add(ucUrl);
        }
      }
    } else {
      if (resolved.isNotEmpty && !urls.contains(resolved)) urls.add(resolved);
      if (original.isNotEmpty && !urls.contains(original)) urls.add(original);

      if (original.contains('drive.google.com')) {
        final id = _extractDriveId(original);
        if (id != null) {
          final ucUrl = 'https://drive.google.com/uc?export=view&id=$id';
          if (!urls.contains(ucUrl)) urls.add(ucUrl);
          final thumbUrl = 'https://drive.google.com/thumbnail?id=$id&sz=w2048';
          if (!urls.contains(thumbUrl)) urls.add(thumbUrl);
          final largerThumbUrl =
              'https://drive.google.com/thumbnail?id=$id&sz=w4096';
          if (!urls.contains(largerThumbUrl)) urls.add(largerThumbUrl);
        }
      }
    }
    return urls.isEmpty ? [''] : urls.expand(imageSources).toSet().toList();
  }

  String? _extractDriveId(String url) {
    final patterns = [
      RegExp(r'/file/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'[?&]id=([a-zA-Z0-9_-]+)'),
      RegExp(r'open\?id=([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  void _tryNextUrl() {
    if (_hasTriedNext) return;
    if (_currentIndex >= _urlsToTry.length - 1) return;

    _hasTriedNext = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _hasTriedNext = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = widget.thumbnail
        ? ((screenWidth / 2) * dpr * 1.5).round().clamp(600, 1600)
        : null;

    final image = CachedNetworkImage(
      imageUrl: _urlsToTry[_currentIndex],
      key: ValueKey('${widget.wallpaper.id}-$_currentIndex'),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      memCacheWidth: cacheWidth,
      // Decode with one dimension so Flutter preserves the source aspect ratio.
      // BoxFit.cover crops the decoded image to the card without stretching it.
      progressIndicatorBuilder: (_, __, progress) {
        if (progress.progress == null) {
          return Container(
            color: Colors.grey[900],
            child:
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return Container(
          color: Colors.grey[900],
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.progress,
              ),
            ),
          ),
        );
      },
      errorWidget: (_, __, ___) {
        _tryNextUrl();
        return Container(
          color: Colors.grey[900],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white54, size: 40),
              SizedBox(height: 4),
              Text('Error',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        );
      },
    );
    if (widget.thumbnail && widget.wallpaper.category == 'PFP') {
      return Align(
        alignment: Alignment.topCenter,
        child: AspectRatio(
          aspectRatio: 1,
          child:
              ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
        ),
      );
    }
    return image;
  }
}
