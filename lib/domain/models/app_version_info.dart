class AppVersionInfo {
  final String currentVersion;
  final String? latestVersion;
  final bool hasUpdate;
  final String? releaseUrl;
  final String? releaseNotes;
  final String? error;

  AppVersionInfo({
    required this.currentVersion,
    this.latestVersion,
    this.hasUpdate = false,
    this.releaseUrl,
    this.releaseNotes,
    this.error,
  });
}
