import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Holds the result of a remote config version check.
class UpdateInfo {
  final bool forceUpdate;
  final bool softUpdate;
  final String latestVersion;
  final String updateMessage;

  const UpdateInfo({
    required this.forceUpdate,
    required this.softUpdate,
    required this.latestVersion,
    required this.updateMessage,
  });

  bool get hasUpdate => forceUpdate || softUpdate;

  /// Hardcoded platform store URLs
  String get storeUrl => Platform.isIOS
      ? 'https://apps.apple.com/in/app/my-crm-app-real-estate/id6748617714'
      : 'https://play.google.com/store/apps/details?id=com.redefine.saleapp';
}

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // ─── Exact key names from Firebase Remote Config ─────────────────────────
  static const String _keyAndroidForceUpdate   = 'crm_android_force_update';
  static const String _keyAndroidLatestVersion = 'crm_android_latest_version';
  static const String _keyIosForceUpdate       = 'crm_ios_force_update';
  static const String _keyIosLatestVersion     = 'crm_ios_latest_version';

  // ─── Default fallback values ──────────────────────────────────────────────
  static const Map<String, dynamic> _defaults = {
    _keyAndroidForceUpdate:   false,
    _keyAndroidLatestVersion: '1.0.0',
    _keyIosForceUpdate:       false,
    _keyIosLatestVersion:     '1.0.0',
  };

  /// Initialize Remote Config — call once in main() after Firebase.initializeApp.
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 15),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await _remoteConfig.setDefaults(_defaults);
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('RemoteConfig initial fetch failed (using cache/defaults): $e');
    }
  }

  /// Fetch latest config and decide if an update is needed for this platform.
  Future<UpdateInfo> checkForUpdate() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // Continue with cached values
    }

    final PackageInfo info = await PackageInfo.fromPlatform();
    final String currentVersion = info.version;

    if (Platform.isAndroid) {
      return _resolveAndroid(currentVersion);
    } else {
      return _resolveIos(currentVersion);
    }
  }

  // ─── Android ──────────────────────────────────────────────────────────────
  UpdateInfo _resolveAndroid(String currentVersion) {
    final bool forceUpdate =
        _remoteConfig.getBool(_keyAndroidForceUpdate);
    final String latestVersion =
        _remoteConfig.getString(_keyAndroidLatestVersion);

    final bool softUpdate =
        !forceUpdate && _isVersionLower(currentVersion, latestVersion);

    return UpdateInfo(
      forceUpdate:   forceUpdate,
      softUpdate:    softUpdate,
      latestVersion: latestVersion,
      updateMessage: forceUpdate
          ? 'A critical update is required to continue using the app. Please update now.'
          : 'A new version ($latestVersion) is available on the Play Store.',
    );
  }

  // ─── iOS ──────────────────────────────────────────────────────────────────
  UpdateInfo _resolveIos(String currentVersion) {
    final bool forceUpdate =
        _remoteConfig.getBool(_keyIosForceUpdate);
    final String latestVersion =
        _remoteConfig.getString(_keyIosLatestVersion);

    final bool softUpdate =
        !forceUpdate && _isVersionLower(currentVersion, latestVersion);

    return UpdateInfo(
      forceUpdate:   forceUpdate,
      softUpdate:    softUpdate,
      latestVersion: latestVersion,
      updateMessage: forceUpdate
          ? 'A critical update is required to continue using the app. Please update now.'
          : 'A new version ($latestVersion) is available on the App Store.',
    );
  }

  // ─── Version comparison ───────────────────────────────────────────────────
  bool _isVersionLower(String version, String other) {
    if (version.isEmpty || other.isEmpty) return false;
    try {
      final v = version.split('.').map(int.parse).toList();
      final o = other.split('.').map(int.parse).toList();
      while (v.length < 3) { v.add(0); }
      while (o.length < 3) { o.add(0); }
      for (int i = 0; i < 3; i++) {
        if (v[i] < o[i]) return true;
        if (v[i] > o[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
