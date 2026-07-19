import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _historyKey = 'scan_history';

  Future<List<String>?> getStringList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey);
  }

  Future<bool> setStringList(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(_historyKey, list);
  }

  Future<bool> removeKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_historyKey);
  }
}
