import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  Future<String> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (_) {
      return '1.0.0';
    }
  }
}
