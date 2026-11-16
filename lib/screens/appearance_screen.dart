import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  Future<void> _save(
      BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se pudo guardar la apariencia. Inténtalo de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ThemeScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Apariencia')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Tema de la app', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...[false, true].map((liquid) => Card(
                child: ListTile(
                  leading:
                      Icon(liquid ? Icons.blur_on : Icons.palette_outlined),
                  title: Text(liquid ? 'Liquid Glass' : 'Por defecto'),
                  subtitle: Text(liquid
                      ? 'Transparencias suaves y tonos frescos'
                      : 'El estilo oscuro original'),
                  trailing: settings.liquid == liquid
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: () => _save(context, () => settings.setLiquid(liquid)),
                ),
              )),
          if (settings.liquid) ...[
            const SizedBox(height: 28),
            Text('Modo de Liquid Glass',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...ThemeMode.values.map((mode) => ListTile(
                  leading: Icon(switch (mode) {
                    ThemeMode.system => Icons.brightness_auto,
                    ThemeMode.light => Icons.light_mode_outlined,
                    ThemeMode.dark => Icons.dark_mode_outlined,
                  }),
                  title: Text(switch (mode) {
                    ThemeMode.system => 'Seguir el sistema',
                    ThemeMode.light => 'Claro',
                    ThemeMode.dark => 'Oscuro',
                  }),
                  trailing:
                      settings.mode == mode ? const Icon(Icons.check) : null,
                  onTap: () => _save(context, () => settings.setMode(mode)),
                )),
          ],
        ],
      ),
    );
  }
}
