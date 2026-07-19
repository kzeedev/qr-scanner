import 'dart:convert';
import '../../domain/models/saved_scan.dart';
import '../../domain/repositories/scan_history_repository.dart';
import '../services/local_storage_service.dart';

class ScanHistoryRepositoryImpl implements ScanHistoryRepository {
  final LocalStorageService _storageService;

  ScanHistoryRepositoryImpl({required LocalStorageService storageService})
      : _storageService = storageService;

  @override
  Future<List<SavedScan>> loadHistory() async {
    final list = await _storageService.getStringList();
    if (list == null) return [];
    return list
        .map((item) => SavedScan.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveScan(SavedScan scan) async {
    final history = await loadHistory();
    history.insert(0, scan);
    await saveHistoryList(history);
  }

  @override
  Future<void> renameScan(String id, String newName) async {
    final history = await loadHistory();
    final index = history.indexWhere((item) => item.id == id);
    if (index != -1) {
      final oldScan = history[index];
      history[index] = SavedScan(
        id: oldScan.id,
        content: oldScan.content,
        timestamp: oldScan.timestamp,
        name: newName.isNotEmpty ? newName : null,
      );
      await saveHistoryList(history);
    }
  }

  @override
  Future<void> deleteScan(String id) async {
    final history = await loadHistory();
    history.removeWhere((item) => item.id == id);
    await saveHistoryList(history);
  }

  @override
  Future<void> clearHistory() async {
    await _storageService.removeKey();
  }

  @override
  Future<void> saveHistoryList(List<SavedScan> history) async {
    final stringList = history.map((scan) => jsonEncode(scan.toJson())).toList();
    await _storageService.setStringList(stringList);
  }
}
