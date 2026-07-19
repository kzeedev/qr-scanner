import '../models/saved_scan.dart';

abstract class ScanHistoryRepository {
  Future<List<SavedScan>> loadHistory();
  Future<void> saveScan(SavedScan scan);
  Future<void> renameScan(String id, String newName);
  Future<void> deleteScan(String id);
  Future<void> clearHistory();
  Future<void> saveHistoryList(List<SavedScan> history);
}
