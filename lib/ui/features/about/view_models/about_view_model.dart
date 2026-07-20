import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/services/apk_download_service.dart';
import '../../../../data/services/app_info_service.dart';
import '../../../../domain/models/app_version_info.dart';
import '../../../../domain/repositories/update_repository.dart';

enum DownloadState {
  idle,
  downloading,
  verifyingChecksum,
  checksumVerified,
  checksumFailed,
  downloadFailed,
}

class AboutViewModel extends ChangeNotifier {
  final UpdateRepository _updateRepository;
  final ApkDownloadService _downloadService;
  final AppInfoService _appInfoService;

  static const String githubUrl = AppConstants.githubRepoUrl;
  static const String appDescription = AppStrings.appDescription;

  String _appVersion = 'Loading...';
  String get appVersion => _appVersion;

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  AppVersionInfo? _updateInfo;
  AppVersionInfo? get updateInfo => _updateInfo;

  // In-app download state
  DownloadState _downloadState = DownloadState.idle;
  DownloadState get downloadState => _downloadState;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  int _receivedBytes = 0;
  int get receivedBytes => _receivedBytes;

  int _totalBytes = 0;
  int get totalBytes => _totalBytes;

  String? _downloadErrorMessage;
  String? get downloadErrorMessage => _downloadErrorMessage;

  String? _computedSha1;
  String? get computedSha1 => _computedSha1;

  String? _expectedSha1;
  String? get expectedSha1 => _expectedSha1;

  File? _downloadedApkFile;
  File? get downloadedApkFile => _downloadedApkFile;

  AboutViewModel({
    required UpdateRepository updateRepository,
    ApkDownloadService? downloadService,
    AppInfoService? appInfoService,
  })  : _updateRepository = updateRepository,
        _downloadService = downloadService ?? ApkDownloadService(),
        _appInfoService = appInfoService ?? AppInfoService() {
    initAppVersion();
  }

  Future<void> initAppVersion() async {
    _appVersion = await _appInfoService.getAppVersion();
    notifyListeners();
  }

  Future<void> checkForUpdates() async {
    if (_appVersion == 'Loading...') {
      _appVersion = await _appInfoService.getAppVersion();
    }

    _isChecking = true;
    _downloadState = DownloadState.idle;
    _downloadErrorMessage = null;
    notifyListeners();

    try {
      _updateInfo = await _updateRepository.checkForUpdates(
        currentVersion: _appVersion,
      );
    } catch (e) {
      _updateInfo = AppVersionInfo(
        currentVersion: _appVersion,
        error: 'Failed to check for updates: $e',
      );
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> startInAppUpdate(String apkUrl, String? sha1Url) async {
    _downloadState = DownloadState.downloading;
    _downloadProgress = 0.0;
    _receivedBytes = 0;
    _totalBytes = 0;
    _downloadErrorMessage = null;
    _computedSha1 = null;
    _expectedSha1 = null;
    _downloadedApkFile = null;
    notifyListeners();

    try {
      // 1. Download APK file
      final apkFile = await _downloadService.downloadApk(
        apkUrl: apkUrl,
        onProgress: (received, total) {
          _receivedBytes = received;
          _totalBytes = total;
          if (total > 0) {
            _downloadProgress = received / total;
          }
          notifyListeners();
        },
      );

      // 2. Verifying Checksum
      _downloadState = DownloadState.verifyingChecksum;
      notifyListeners();

      final actualSha1 = await _downloadService.computeFileSha1(apkFile);
      _computedSha1 = actualSha1;

      if (sha1Url != null && sha1Url.isNotEmpty) {
        final expected = await _downloadService.fetchExpectedSha1(sha1Url);
        _expectedSha1 = expected;

        if (expected != null && expected.isNotEmpty) {
          if (actualSha1 != expected) {
            _downloadState = DownloadState.checksumFailed;
            _downloadErrorMessage =
                'SHA-1 Checksum mismatch!\nExpected: $expected\nActual: $actualSha1';
            if (await apkFile.exists()) {
              await apkFile.delete();
            }
            notifyListeners();
            return;
          }
        }
      }

      // 3. Checksum Verified
      _downloadState = DownloadState.checksumVerified;
      _downloadedApkFile = apkFile;
      notifyListeners();

      // Trigger automatic installation prompt
      await installDownloadedApk();
    } catch (e) {
      _downloadState = DownloadState.downloadFailed;
      _downloadErrorMessage = 'Download failed: $e';
      notifyListeners();
    }
  }

  Future<void> installDownloadedApk() async {
    if (_downloadedApkFile != null && await _downloadedApkFile!.exists()) {
      try {
        await _downloadService.installApk(_downloadedApkFile!);
      } catch (e) {
        _downloadErrorMessage = 'Failed to launch installer: $e';
        notifyListeners();
      }
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
