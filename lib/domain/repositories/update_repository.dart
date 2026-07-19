import '../models/app_version_info.dart';

abstract class UpdateRepository {
  Future<AppVersionInfo> checkForUpdates({required String currentVersion});
}
