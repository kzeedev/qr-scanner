import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain/models/app_version_info.dart';
import '../../../../domain/repositories/update_repository.dart';

class AboutViewModel extends ChangeNotifier {
  final UpdateRepository _updateRepository;

  static const String appVersion = '1.0.0';
  static const String githubUrl = 'https://github.com/KZeeDev/qr-scanner';
  static const String appDescription =
      'Bulk Barcode Scanner is a fast, versatile barcode and QR code scanner tool built with Flutter & ZXing. Easily scan multiple codes continuously, customize item separators, save scan history, and export or share data seamlessly.';

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  AppVersionInfo? _updateInfo;
  AppVersionInfo? get updateInfo => _updateInfo;

  AboutViewModel({required UpdateRepository updateRepository})
      : _updateRepository = updateRepository;

  Future<void> checkForUpdates() async {
    _isChecking = true;
    notifyListeners();

    try {
      _updateInfo = await _updateRepository.checkForUpdates(
        currentVersion: appVersion,
      );
    } catch (e) {
      _updateInfo = AppVersionInfo(
        currentVersion: appVersion,
        error: 'Failed to check for updates: $e',
      );
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<bool> launchUrlString(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
