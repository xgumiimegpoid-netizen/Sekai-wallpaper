import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallpaper_app/screens/appearance_screen.dart';
import 'package:wallpaper_app/theme/app_theme.dart';

void main() {
  late Directory directory;
  late Box<dynamic> box;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('appearance_test');
    Hive.init(directory.path);
    box = await Hive.openBox<dynamic>('appearance');
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('Original theme is default and appearance survives reopening', () async {
    final settings = ThemeSettings(box);
    expect(settings.liquid, isFalse);
    expect(settings.mode, ThemeMode.system);
    await settings.setLiquid(true);
    await settings.setMode(ThemeMode.dark);
    await box.close();
    box = await Hive.openBox<dynamic>('appearance');
    final restored = ThemeSettings(box);
    expect(restored.liquid, isTrue);
    expect(restored.mode, ThemeMode.dark);
    await restored.setLiquid(false);
    expect(restored.liquid, isFalse);
    expect(restored.mode, ThemeMode.dark);
  });

  testWidgets('Appearance switches between themes and light/dark modes',
      (tester) async {
    final settings = ThemeSettings(box);
    await tester.pumpWidget(ThemeScope(
      settings: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          theme: liquidTheme(Brightness.light),
          darkTheme: liquidTheme(Brightness.dark),
          themeMode: settings.mode,
          home: const AppearanceScreen(),
        ),
      ),
    ));
    expect(find.text('Modo de Liquid Glass'), findsNothing);
    await tester.runAsync(() async {
      await tester.tap(find.text('Liquid Glass'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Seguir el sistema'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Oscuro'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(settings.mode, ThemeMode.dark);
    expect(Theme.of(tester.element(find.byType(AppearanceScreen))).brightness,
        Brightness.dark);
    await tester.runAsync(() async {
      await tester.tap(find.text('Claro'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(AppearanceScreen))).brightness,
        Brightness.light);
    await tester.runAsync(() async {
      await tester.tap(find.text('Por defecto'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(settings.liquid, isFalse);
    expect(find.text('Modo de Liquid Glass'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
