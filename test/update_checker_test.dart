import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wallpaper_app/services/update_checker.dart';

UpdateInfo info(int build,
        {String version = '1.5.3',
        String url = 'https://github.com/test/app.apk'}) =>
    UpdateInfo(
        latestVersion: version,
        latestBuildNumber: build,
        downloadUrl: url,
        releaseNotes: '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.wallpaper.app/wallpaper');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            channel, (call) async => {'version': '1.5.2', 'build': 7});
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
      'Updates compare against installed Android build, including same-version rebuilds',
      () async {
    expect(await UpdateChecker.hasUpdate(info(8, version: '1.5.2')), isTrue);
    expect(await UpdateChecker.hasUpdate(info(7)), isFalse);
    expect(await UpdateChecker.hasUpdate(info(6, version: '9.0.0')), isFalse);
  });
  test('Malformed versions and non-HTTPS downloads are rejected', () {
    expect(info(8).isValid(), isTrue);
    expect(info(8, version: 'broken').isValid(), isFalse);
    expect(info(8, url: 'http://example.com/app.apk').isValid(), isFalse);
    expect(info(0).isValid(), isFalse);
  });
  test('Remote manifest uses fresh request and validates response', () async {
    await http.runWithClient(() async {
      expect((await UpdateChecker.fetchUpdateInfo())?.latestBuildNumber, 8);
    },
        () => MockClient((request) async {
              expect(request.url.queryParameters.containsKey('t'), isTrue);
              expect(request.headers['Cache-Control'], 'no-cache');
              return http.Response(
                  jsonEncode({
                    'latestVersion': '1.5.3',
                    'latestBuildNumber': 8,
                    'downloadUrl': 'https://github.com/test/app.apk'
                  }),
                  200);
            }));
    await http.runWithClient(() async {
      expect(await UpdateChecker.fetchUpdateInfo(), isNull);
    }, () => MockClient((_) async => http.Response('unavailable', 503)));
  });
}
