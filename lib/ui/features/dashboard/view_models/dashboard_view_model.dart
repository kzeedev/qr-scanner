import 'package:flutter/material.dart';
import '../../../../domain/models/saved_scan.dart';
import '../../../../domain/models/separator_type.dart';
import '../../../../domain/repositories/scan_history_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final ScanHistoryRepository _historyRepository;

  final TextEditingController textController = TextEditingController();
  final TextEditingController customSeparatorController = TextEditingController();
  
  List<SavedScan> _history = [];
  List<SavedScan> get history => _history;

  SeparatorType _selectedSeparator = SeparatorType.newLine;
  SeparatorType get selectedSeparator => _selectedSeparator;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DashboardViewModel({required ScanHistoryRepository historyRepository})
      : _historyRepository = historyRepository;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _history = await _historyRepository.loadHistory();
    } catch (e) {
      debugPrint('Error loading history in VM: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveScan(String name) async {
    final text = textController.text.trim();
    if (text.isEmpty) return false;

    final newScan = SavedScan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      timestamp: DateTime.now(),
      name: name.isNotEmpty ? name : null,
    );

    _history.insert(0, newScan);
    notifyListeners();

    try {
      await _historyRepository.saveScan(newScan);
      return true;
    } catch (e) {
      debugPrint('Error saving scan in VM: $e');
      return false;
    }
  }

  Future<void> renameScan(String id, String newName) async {
    final index = _history.indexWhere((item) => item.id == id);
    if (index != -1) {
      final oldScan = _history[index];
      _history[index] = SavedScan(
        id: oldScan.id,
        content: oldScan.content,
        timestamp: oldScan.timestamp,
        name: newName.isNotEmpty ? newName : null,
      );
      notifyListeners();

      try {
        await _historyRepository.renameScan(id, newName);
      } catch (e) {
        debugPrint('Error renaming scan in VM: $e');
      }
    }
  }

  Future<void> deleteScan(SavedScan scan) async {
    _history.removeWhere((item) => item.id == scan.id);
    notifyListeners();

    try {
      await _historyRepository.deleteScan(scan.id);
    } catch (e) {
      debugPrint('Error deleting scan in VM: $e');
    }
  }

  Future<void> undoDelete(int index, SavedScan scan) async {
    _history.insert(index, scan);
    notifyListeners();

    try {
      await _historyRepository.saveHistoryList(_history);
    } catch (e) {
      debugPrint('Error undoing delete in VM: $e');
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();

    try {
      await _historyRepository.clearHistory();
    } catch (e) {
      debugPrint('Error clearing history in VM: $e');
    }
  }

  void updateSeparator(SeparatorType type) {
    _selectedSeparator = type;
    notifyListeners();
  }

  void addSeparator() {
    String separator = _selectedSeparator.value;
    if (_selectedSeparator == SeparatorType.custom) {
      separator = customSeparatorController.text;
    }

    final currentText = textController.text;
    textController.text = currentText + separator;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
    notifyListeners();
  }

  void appendBarcode(String barcode) {
    String separator = '';
    if (textController.text.isNotEmpty) {
      if (_selectedSeparator == SeparatorType.custom) {
        separator = customSeparatorController.text;
      } else {
        separator = _selectedSeparator.value;
      }
    }

    textController.text = textController.text + separator + barcode;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
    notifyListeners();
  }

  void applyRestore(String content) {
    textController.text = content;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    customSeparatorController.dispose();
    super.dispose();
  }
}
