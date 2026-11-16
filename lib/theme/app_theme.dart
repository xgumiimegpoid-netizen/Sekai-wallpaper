import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeSettings extends ChangeNotifier {
  ThemeSettings(this._box);
  final Box<dynamic> _box;

  bool get liquid => _box.get('liquid', defaultValue: false) == true;
  ThemeMode get mode => switch (_box.get('mode')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> setLiquid(bool value) async {
    await _box.put('liquid', value);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    await _box.put('mode', value.name);
    notifyListeners();
  }
}

class ThemeScope extends InheritedNotifier<ThemeSettings> {
  const ThemeScope(
      {super.key, required ThemeSettings settings, required super.child})
      : super(notifier: settings);

  static ThemeSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!;
}

ThemeData liquidTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF218CE6),
    brightness: brightness,
    surface: dark ? const Color(0xFF152531) : const Color(0xFFF0F7FC),
  );
  final ink = dark ? const Color(0xFFF1F6FC) : const Color(0xFF142D47);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle:
          TextStyle(color: ink, fontSize: 25, fontWeight: FontWeight.w600),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: ink,
      unselectedLabelColor: ink.withValues(alpha: 0.75),
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: const Color(0xFF349DEE).withValues(alpha: dark ? 0.65 : 0.28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    ),
  );
}

class LiquidBackground extends StatelessWidget {
  const LiquidBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF101B29), Color(0xFF15313B), Color(0xFF101D2C)]
              : const [Color(0xFFF0F6FE), Color(0xFFDCEEF5), Color(0xFFE6F1EA)],
        ),
      ),
      child: child,
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.radius = 28});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.white.withValues(alpha: dark ? 0.09 : 0.38),
            border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.2 : 0.7)),
          ),
          child: child,
        ),
      ),
    );
  }
}
