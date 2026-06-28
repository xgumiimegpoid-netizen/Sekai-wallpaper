import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/wallpaper.dart';

class WallpaperImage extends StatefulWidget {
  final Wallpaper wallpaper;
  final BoxFit fit;
  final double? width;
  final double? height;

  const WallpaperImage({
    super.key,
    required this.wallpaper,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
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

  List<String> _buildUrlList() {
    final urls = <String>[widget.wallpaper.resolvedUrl];
    final original = widget.wallpaper.url;
    if (!urls.contains(original)) urls.add(original);

    if (original.contains('drive.google.com')) {
      final id = _extractDriveId(original);
      if (id != null) {
        final thumbUrl = 'https://drive.google.com/thumbnail?id=$id&sz=w800';
        if (!urls.contains(thumbUrl)) urls.add(thumbUrl);
        final ucUrl = 'https://drive.google.com/uc?export=view&id=$id';
        if (!urls.contains(ucUrl)) urls.add(ucUrl);
      }
    }
    return urls;
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
    final cacheWidth = (screenWidth / 2).round();
    return CachedNetworkImage(
      imageUrl: _urlsToTry[_currentIndex],
      key: ValueKey('${widget.wallpaper.id}-$_currentIndex'),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      memCacheWidth: cacheWidth,
      memCacheHeight: (cacheWidth * 1.6).round(),
      progressIndicatorBuilder: (_, __, progress) {
        if (progress.progress == null) {
          return Container(
            color: Colors.grey[900],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
              Text('Error', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}
