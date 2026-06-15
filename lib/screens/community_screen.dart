import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  // === CONFIGURACIÓN ===
  // Cambia estos valores por los tuyos:
  static const _telegramLink = 'https://t.me/+4bclr2JX_yY0NWZh';
  // =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.groups, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            '¡Comparte tus wallpapers!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Queremos que la comunidad crezca con tus fondos de pantalla favoritos. '
            'Envía tus wallpapers por Telegram y los agregaremos a la app.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildTelegramCard(context),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            '¿Cómo compartir tu wallpaper?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildStep(1, 'Abre el wallpaper que quieras compartir', Theme.of(context).colorScheme.primary),
          _buildStep(2, 'Presiona el botón de compartir', Theme.of(context).colorScheme.primary),
          _buildStep(3, 'Elige Telegram', Theme.of(context).colorScheme.primary),
          _buildStep(4, 'Selecciona este canal y envía', Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildTelegramCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Image.network(
            'https://cdn.jsdelivr.net/gh/simple-icons/simple-icons/icons/telegram.svg',
            width: 24,
            height: 24,
            color: Colors.white,
            errorBuilder: (_, __, ___) => const Icon(Icons.send, color: Colors.white, size: 24),
          ),
        ),
        title: const Text('Enviar por Telegram'),
        subtitle: const Text('Canal de wallpapers'),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => _launchUrl(_telegramLink),
      ),
    );
  }

  Widget _buildStep(int number, String text, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // fallback: abrir en navegador
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e, stack) {
        debugPrint('CommunityScreen._launchUrl error: $e\n$stack');
      }
    }
  }
}
