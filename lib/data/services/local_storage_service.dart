import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class LocalStorageService {
  Future<List<String>?> getStringList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(AppConstants.historyStorageKey);
  }

  Future<bool> setStringList(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(AppConstants.historyStorageKey, list);
  }

  Future<bool> removeKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(AppConstants.historyStorageKey);
  }
}
