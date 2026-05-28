import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../models/wallpaper.dart';
import '../services/wallpaper_action.dart';
import '../widgets/wallpaper_image.dart';

class PreviewScreen extends StatefulWidget {
  final Wallpaper wallpaper;
  const PreviewScreen({super.key, required this.wallpaper});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final _wallpaperService = WallpaperManagerService();
  bool _downloading = false;
  String? _cachedPath;

  @override
  void dispose() {
    _wallpaperService.clearCache();
    _cleanupTempFile();
    super.dispose();
  }

  Future<void> _cleanupTempFile() async {
    if (_cachedPath != null) {
      try {
        final file = File(_cachedPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<String> _ensureDownloaded() async {
    if (_cachedPath != null && File(_cachedPath!).existsSync()) {
      return _cachedPath!;
    }

    final response = await http.get(
      Uri.parse(widget.wallpaper.resolvedUrl),
      headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to download: ${response.statusCode}');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/wp_preview_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(response.bodyBytes);
    _cachedPath = file.path;
    return _cachedPath!;
  }

  Future<void> _shareWallpaper() async {
    if (_downloading) return;
    final RenderBox? box = mounted ? context.findRenderObject() as RenderBox? : null;

    setState(() => _downloading = true);

    try {
      final path = await _ensureDownloaded();

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Mira este wallpaper: ${widget.wallpaper.title}',
        subject: 'Wallpaper: ${widget.wallpaper.title}',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    } catch (e) {
      if (mounted) {
        _showError('No se pudo compartir: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _showOptions() async {
    if (!mounted) return;

    final supportsNative = await WallpaperManagerService.isPlatformSupported();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.wallpaper, color: Theme.of(ctx).colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Opciones',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Guardar en Galería'),
              subtitle: const Text('Descarga la imagen a tu galería'),
              onTap: () {
                Navigator.pop(ctx);
                _saveToGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartir'),
              subtitle: const Text('Envía la imagen por otras apps'),
              onTap: () {
                Navigator.pop(ctx);
                _shareWallpaper();
              },
            ),
            if (supportsNative) ...[
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Establecer como Fondo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Pantalla Principal'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setWallpaper(WallpaperManagerService.locationHome);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Pantalla de Bloqueo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setWallpaper(WallpaperManagerService.locationLock);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('Ambas Pantallas'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setWallpaper(WallpaperManagerService.locationBoth);
                },
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.wallpaper),
                title: const Text('Establecer como Fondo'),
                subtitle: const Text('Guarda y abre en tu galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setAsWallpaperLegacy();
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToGallery() async {
    if (_downloading) return;
    setState(() => _downloading = true);

    try {
      final success = await _wallpaperService.saveToGallery(
        widget.wallpaper.resolvedUrl,
        name: 'wallpaper_${widget.wallpaper.id}',
      );

      if (success) {
        _showSuccess('Guardado en galería');
      } else {
        _showError('No se pudo guardar la imagen');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _setWallpaper(int location) async {
    if (_downloading) return;
    setState(() => _downloading = true);

    try {
      final path = await _ensureDownloaded();
      final (success, error) = await _wallpaperService.setWallpaperFromPath(
        path,
        location: location,
      );

      if (success) {
        final locationName = switch (location) {
          WallpaperManagerService.locationHome => 'pantalla principal',
          WallpaperManagerService.locationLock => 'pantalla de bloqueo',
          _ => 'ambas pantallas',
        };
        _showSuccess('Fondo establecido en $locationName');
      } else {
        _showError(error ?? 'No se pudo establecer el fondo');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _setAsWallpaperLegacy() async {
    if (_downloading) return;

    await _saveToGallery();

    if (mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Fondo Listo'),
          content: const Text('La imagen se ha guardado. Abre tu galería, selecciona la imagen y usa la opción "Establecer como fondo".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.wallpaper.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.wallpaper.author,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _downloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share),
            tooltip: 'Compartir',
            onPressed: _downloading ? null : _shareWallpaper,
          ),
          IconButton(
            icon: _downloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download),
            tooltip: 'Acciones',
            onPressed: _downloading ? null : _showOptions,
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 1.0,
        maxScale: 5.0,
        child: Center(
          child: WallpaperImage(
            wallpaper: widget.wallpaper,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
