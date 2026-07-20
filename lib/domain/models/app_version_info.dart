class AppVersionInfo {
  final String currentVersion;
  final String? latestVersion;
  final bool hasUpdate;
  final String? releaseUrl;
  final String? releaseNotes;
  final String? apkUrl;
  final int? apkSize;
  final String? sha1Url;
  final String? error;

  AppVersionInfo({
    required this.currentVersion,
    this.latestVersion,
    this.hasUpdate = false,
    this.releaseUrl,
    this.releaseNotes,
    this.apkUrl,
    this.apkSize,
    this.sha1Url,
    this.error,
  });
}
