import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di.dart';
import '../../../../domain/repositories/scan_history_repository.dart';
import '../../../core/widgets/curved_bottom_navigation_bar.dart';
import '../../about/views/about_screen.dart';
import '../../scan/views/scanner_screen.dart';
import '../view_models/dashboard_view_model.dart';
import 'history_bottom_sheet.dart';
import 'separator_settings_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(
      historyRepository: di().get<ScanHistoryRepository>(),
    );
    _viewModel.loadHistory();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _saveScan() async {
    final text = _viewModel.textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to save! Scan or enter barcodes first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final saveName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Scan List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter a name for this list (optional):'),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'List Name',
                hintText: 'e.g. Warehouse Section B',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, nameController.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saveName == null) return;
    if (!mounted) return;

    final success = await _viewModel.saveScan(saveName);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to history successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save to history.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareList() async {
    final text = _viewModel.textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to share! Scan or enter barcodes first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          title: 'Bulk Barcodes',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing barcodes: $e');
    }
  }

  void _copyToClipboard() {
    final text = _viewModel.textController.text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to copy!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          onBarcodeScanned: (barcode) {
            _viewModel.appendBarcode(barcode);
          },
        ),
      ),
    );

    if (result != null && result is String) {
      if (result == 'show_history') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showHistoryBottomSheet();
        });
      }
    }
  }

  void _showSeparatorDialog() {
    SeparatorSettingsDialog.show(context, _viewModel);
  }

  void _showHistoryBottomSheet() {
    HistoryBottomSheet.show(context, _viewModel);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Barcode Scanner'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
                tooltip: 'About',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _viewModel.textController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Scanned barcodes will appear here...',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        label: const Text('Copy'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saveScan,
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: const Text('Save'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFFFA726),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareList,
                        icon: const Icon(Icons.share_rounded, size: 20),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white12),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          bottomNavigationBar: CurvedBottomNavigationBar(
            onLeftTap: _showSeparatorDialog,
            onCenterTap: _scanBarcode,
            onRightTap: _showHistoryBottomSheet,
          ),
        );
      },
    );
  }
}
