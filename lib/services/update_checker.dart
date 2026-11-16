import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String downloadUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['latestVersion'] as String? ?? '',
      latestBuildNumber: json['latestBuildNumber'] as int? ?? 0,
      downloadUrl: json['downloadUrl'] as String? ?? '',
      releaseNotes: json['releaseNotes'] as String? ?? '',
    );
  }

  bool isValid() {
    final uri = Uri.tryParse(downloadUrl);
    return RegExp(r'^\d+\.\d+\.\d+$').hasMatch(latestVersion) &&
        latestBuildNumber > 0 &&
        uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty;
  }
}

class UpdateChecker {
  // Must match the version in pubspec.yaml
  static const String currentVersion = '1.5.3';
  static const int currentBuildNumber = 8;

  static const _versionUrl =
      'https://raw.githubusercontent.com/xgumiimegpoid-netizen/Sekai-wallpaper/main/version.json';

  static Future<File> _getSkipFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/skipped_version.json');
  }

  static Future<String?> _getSkippedVersion() async {
    try {
      final file = await _getSkipFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        return data['version'] as String?;
      }
    } catch (e, stack) {
      debugPrint('UpdateChecker._getSkippedVersion error: $e\n$stack');
    }
    return null;
  }

  static Future<void> _skipVersion(String version) async {
    try {
      final file = await _getSkipFile();
      await file.writeAsString(jsonEncode({'version': version}));
    } catch (e, stack) {
      debugPrint('UpdateChecker._skipVersion error: $e\n$stack');
    }
  }

  static Future<UpdateInfo?> fetchUpdateInfo() async {
    try {
      final response = await http.get(
          Uri.parse(_versionUrl).replace(queryParameters: {
            't': DateTime.now().millisecondsSinceEpoch.toString()
          }),
          headers: {
            'Cache-Control': 'no-cache'
          }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final info = UpdateInfo.fromJson(json);
      return info.isValid() ? info : null;
    } catch (e, stack) {
      debugPrint('UpdateChecker.fetchUpdateInfo error: $e\n$stack');
      return null;
    }
  }

  static Future<bool> hasUpdate(UpdateInfo info) async {
    final installed = await installedVersion();
    return info.latestBuildNumber > installed.$2;
  }

  static Future<(String, int)> installedVersion() async {
    try {
      final info = await const MethodChannel('com.wallpaper.app/wallpaper')
          .invokeMapMethod<String, dynamic>('getAppVersion');
      if (info?['version'] is String && info?['build'] is int) {
        return (info!['version'] as String, info['build'] as int);
      }
    } on MissingPluginException {
      // Desktop previews and tests have no Android package metadata.
    }
    return (currentVersion, currentBuildNumber);
  }

  static bool _isVersionNewer(String latest, String skipped) {
    return _compareVersions(latest, skipped) > 0;
  }

  static int _compareVersions(String a, String b) {
    final partsA = a.split('.').map(int.parse).toList();
    final partsB = b.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final va = i < partsA.length ? partsA[i] : 0;
      final vb = i < partsB.length ? partsB[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }

  static Future<bool> shouldShowUpdate(UpdateInfo info) async {
    final skipped = await _getSkippedVersion();
    if (skipped == null) return true;
    final parts = skipped.split('+');
    if (parts.length == 2) {
      return info.latestBuildNumber > (int.tryParse(parts[1]) ?? 0);
    }
    return _isVersionNewer(info.latestVersion, skipped);
  }

  static Future<void> markSkipped(String version) async {
    await _skipVersion(version);
  }

  static Future<void> launchDownload(String url) async {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https' || uri.host.isEmpty) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
