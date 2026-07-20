import '../../domain/models/app_version_info.dart';
import '../../domain/repositories/update_repository.dart';
import '../services/github_update_service.dart';

class UpdateRepositoryImpl implements UpdateRepository {
  final GitHubUpdateService _service;

  UpdateRepositoryImpl({required GitHubUpdateService service})
      : _service = service;

  @override
  Future<AppVersionInfo> checkForUpdates({required String currentVersion}) async {
    try {
      final release = await _service.fetchLatestRelease();

      if (release == null) {
        return AppVersionInfo(
          currentVersion: currentVersion,
          hasUpdate: false,
          error: 'No releases found on GitHub repository.',
        );
      }

      final latestTag = release.tagName.trim();
      final hasUpdate = _isVersionNewer(currentVersion, latestTag);

      return AppVersionInfo(
        currentVersion: currentVersion,
        latestVersion: latestTag.startsWith('v') ? latestTag.substring(1) : latestTag,
        hasUpdate: hasUpdate,
        releaseUrl: release.htmlUrl,
        releaseNotes: release.body,
        apkUrl: release.apkUrl,
        apkSize: release.apkSize,
        sha1Url: release.sha1Url,
      );
    } catch (e) {
      return AppVersionInfo(
        currentVersion: currentVersion,
        hasUpdate: false,
        error: 'Unable to check for updates. Please check your network connection.',
      );
    }
  }

  bool _isVersionNewer(String current, String latest) {
    final cleanCurrent = current.startsWith('v') ? current.substring(1) : current;
    final cleanLatest = latest.startsWith('v') ? latest.substring(1) : latest;

    final curBase = cleanCurrent.split('+').first.split('-').first;
    final latBase = cleanLatest.split('+').first.split('-').first;

    final curParts = curBase.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latParts = latBase.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = curParts.length > latParts.length ? curParts.length : latParts.length;

    for (int i = 0; i < maxLength; i++) {
      final curNum = i < curParts.length ? curParts[i] : 0;
      final latNum = i < latParts.length ? latParts[i] : 0;

      if (latNum > curNum) {
        return true;
      } else if (latNum < curNum) {
        return false;
      }
    }

    return false;
  }
}
