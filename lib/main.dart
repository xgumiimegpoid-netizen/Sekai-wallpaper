import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/wallpaper.dart';
import 'screens/home_screen.dart';
import 'services/favorites_service_hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(WallpaperAdapter());
  await FavoritesServiceHive.init();
  runApp(const WallpaperApp());
}

class WallpaperApp extends StatelessWidget {
  const WallpaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpapers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
