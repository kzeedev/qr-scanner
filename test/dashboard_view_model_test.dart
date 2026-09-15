import 'package:flutter_test/flutter_test.dart';
import 'package:qrscanner/domain/models/saved_scan.dart';
import 'package:qrscanner/domain/models/separator_type.dart';
import 'package:qrscanner/domain/repositories/scan_history_repository.dart';
import 'package:qrscanner/ui/features/dashboard/view_models/dashboard_view_model.dart';

class FakeScanHistoryRepository implements ScanHistoryRepository {
  List<SavedScan> stored = [];

  @override
  Future<List<SavedScan>> loadHistory() async => List.from(stored);

  @override
  Future<void> saveScan(SavedScan scan) async => stored.insert(0, scan);

  @override
  Future<void> saveHistoryList(List<SavedScan> history) async =>
      stored = List.from(history);

  @override
  Future<void> renameScan(String id, String newName) async {
    final idx = stored.indexWhere((s) => s.id == id);
    if (idx != -1) {
      stored[idx] = SavedScan(
        id: stored[idx].id,
        content: stored[idx].content,
        timestamp: stored[idx].timestamp,
        name: newName,
      );
    }
  }

  @override
  Future<void> deleteScan(String id) async {
    stored.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> clearHistory() async {
    stored.clear();
  }
}

void main() {
  group('DashboardViewModel appendBarcode', () {
    late DashboardViewModel viewModel;

    setUp(() {
      viewModel = DashboardViewModel(
        historyRepository: FakeScanHistoryRepository(),
      );
    });

    test('appendBarcode normal save adds 1 separator', () {
      viewModel.appendBarcode('123', withSeparator: false);
      expect(viewModel.textController.text, '123\n');

      viewModel.appendBarcode('456', withSeparator: false);
      expect(viewModel.textController.text, '123\n456\n');
    });

    test('appendBarcode save with separator adds double separator', () {
      // Default separator is newLine '\n'
      viewModel.appendBarcode('123', withSeparator: true);
      expect(viewModel.textController.text, '123\n\n');

      viewModel.appendBarcode('456', withSeparator: true);
      expect(viewModel.textController.text, '123\n\n456\n\n');
    });

    test('appendBarcode mixing normal save and save with separator', () {
      viewModel.appendBarcode('123', withSeparator: false);
      expect(viewModel.textController.text, '123\n');

      viewModel.appendBarcode('456', withSeparator: true);
      expect(viewModel.textController.text, '123\n456\n\n');

      viewModel.appendBarcode('789', withSeparator: false);
      expect(viewModel.textController.text, '123\n456\n\n789\n');
    });

    test('appendBarcode handles existing text without trailing separator', () {
      viewModel.textController.text = 'manual_text';

      viewModel.appendBarcode('123', withSeparator: false);
      expect(viewModel.textController.text, 'manual_text\n123\n');
    });

    test('appendBarcode works with custom separator', () {
      viewModel.updateSeparator(SeparatorType.custom);
      viewModel.customSeparatorController.text = ' | ';

      viewModel.appendBarcode('CODE_A', withSeparator: false);
      expect(viewModel.textController.text, 'CODE_A | ');

      viewModel.appendBarcode('CODE_B', withSeparator: true);
      expect(viewModel.textController.text, 'CODE_A | CODE_B |  | ');
    });

    test('updateContent updates textController and notifies listeners', () {
      bool notified = false;
      viewModel.addListener(() {
        notified = true;
      });

      viewModel.updateContent('NEW_CONTENT_123');
      expect(viewModel.textController.text, 'NEW_CONTENT_123');
      expect(notified, isTrue);
    });
  });
}
