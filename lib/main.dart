import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'services/favorites_service_hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoritesServiceHive.init();
  final settings = ThemeSettings(await Hive.openBox<dynamic>('appearance'));
  runApp(WallpaperApp(settings: settings));
}

class WallpaperApp extends StatelessWidget {
  const WallpaperApp({super.key, required this.settings});
  final ThemeSettings settings;

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      settings: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: 'Wallpapers',
          debugShowCheckedModeBanner: false,
          theme: settings.liquid
              ? liquidTheme(Brightness.light)
              : ThemeData(
                  colorSchemeSeed: Colors.blue,
                  brightness: Brightness.dark,
                  useMaterial3: true),
          darkTheme: settings.liquid ? liquidTheme(Brightness.dark) : null,
          themeMode: settings.liquid ? settings.mode : ThemeMode.light,
          builder: (context, child) =>
              settings.liquid ? LiquidBackground(child: child!) : child!,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
