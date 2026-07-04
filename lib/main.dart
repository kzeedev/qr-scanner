import 'dart:convert';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BarcodeScannerApp());
}

class BarcodeScannerApp extends StatelessWidget {
  const BarcodeScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Bulk Barcode Scanner',
          theme: ThemeData(
            colorScheme: lightDynamic ??
                ColorScheme.fromSeed(
                  seedColor: Colors.teal,
                  brightness: Brightness.light,
                ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ??
                ColorScheme.fromSeed(
                  seedColor: Colors.teal,
                  brightness: Brightness.dark,
                ),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: const MainScreen(),
        );
      },
    );
  }
}

enum SeparatorType { newLine, emptyLine, dash, dot, custom }

extension SeparatorTypeExtension on SeparatorType {
  String get label {
    switch (this) {
      case SeparatorType.newLine:
        return 'New Line';
      case SeparatorType.emptyLine:
        return 'Empty Line';
      case SeparatorType.dash:
        return 'Dash';
      case SeparatorType.dot:
        return 'Dot';
      case SeparatorType.custom:
        return 'Custom...';
    }
  }

  String get value {
    switch (this) {
      case SeparatorType.newLine:
        return '\n';
      case SeparatorType.emptyLine:
        return '\n\n';
      case SeparatorType.dash:
        return '-';
      case SeparatorType.dot:
        return '.';
      case SeparatorType.custom:
        return '';
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _customSeparatorController =
      TextEditingController();
  SeparatorType _selectedSeparator = SeparatorType.newLine;

  List<SavedScan> _history = [];
  static const String _historyKey = 'scan_history';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey);
      if (historyJson != null) {
        setState(() {
          _history = historyJson
              .map((item) =>
                  SavedScan.fromJson(jsonDecode(item) as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveScan() async {
    final text = _textController.text.trim();
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

    if (saveName == null) {
      return;
    }

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    final newScan = SavedScan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _textController.text,
      timestamp: DateTime.now(),
      name: saveName.isNotEmpty ? saveName : null,
    );

    setState(() {
      _history.insert(0, newScan);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson =
          _history.map((scan) => jsonEncode(scan.toJson())).toList();
      await prefs.setStringList(_historyKey, historyJson);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Saved to history successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error saving history: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to save to history.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _renameScan(SavedScan scan, StateSetter setModalState) async {
    final nameController = TextEditingController(text: scan.name ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'List Name',
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

    if (newName == null) return;

    final index = _history.indexWhere((item) => item.id == scan.id);
    if (index != -1) {
      final updatedScan = SavedScan(
        id: scan.id,
        content: scan.content,
        timestamp: scan.timestamp,
        name: newName.isNotEmpty ? newName : null,
      );

      setState(() {
        _history[index] = updatedScan;
      });
      setModalState(() {});

      try {
        final prefs = await SharedPreferences.getInstance();
        final historyJson =
            _history.map((s) => jsonEncode(s.toJson())).toList();
        await prefs.setStringList(_historyKey, historyJson);
      } catch (e) {
        debugPrint('Error renaming scan: $e');
      }
    }
  }

  Future<void> _shareList() async {
    final text = _textController.text.trim();
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

  Future<void> _shareHistoryList(String content) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: content,
          title: 'Bulk Barcodes',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing scan: $e');
    }
  }

  Future<void> _deleteScan(SavedScan scan) async {
    setState(() {
      _history.removeWhere((item) => item.id == scan.id);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson =
          _history.map((scan) => jsonEncode(scan.toJson())).toList();
      await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      debugPrint('Error deleting scan: $e');
    }
  }

  Future<void> _clearHistory() async {
    setState(() {
      _history.clear();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  void _restoreScan(SavedScan scan) {
    if (_textController.text.isNotEmpty &&
        _textController.text != scan.content) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Scan'),
          content: const Text(
              'This will overwrite the current barcodes in the editor. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _applyRestore(scan.content);
              },
              child: const Text('Restore'),
            ),
          ],
        ),
      );
    } else {
      _applyRestore(scan.content);
    }
  }

  void _applyRestore(String content) {
    setState(() {
      _textController.text = content;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded from history!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addSeparator() {
    String separator = _selectedSeparator.value;
    if (_selectedSeparator == SeparatorType.custom) {
      separator = _customSeparatorController.text;
    }

    final text = _textController.text;
    _textController.text = text + separator;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _textController.text));
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
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (result != null && result is String) {
      setState(() {
        _textController.text = _textController.text + result;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _customSeparatorController.dispose();
    super.dispose();
  }

  void _showHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Scan History',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        if (_history.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Clear All History'),
                                  content: const Text(
                                      'Are you sure you want to permanently delete all saved scans?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _clearHistory();
                                        setModalState(() {});
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('History cleared!'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: const Text('Clear All'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_sweep),
                            label: const Text('Clear All'),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: _history.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_toggle_off,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No saved scans yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final scan = _history[index];
                              final dateStr =
                                  '${scan.timestamp.year}-${scan.timestamp.month.toString().padLeft(2, '0')}-${scan.timestamp.day.toString().padLeft(2, '0')} ${scan.timestamp.hour.toString().padLeft(2, '0')}:${scan.timestamp.minute.toString().padLeft(2, '0')}';
                              final lines = scan.content
                                  .split('\n')
                                  .where((l) => l.trim().isNotEmpty)
                                  .length;
                              final subTitle =
                                  '$lines barcode${lines == 1 ? '' : 's'} • $dateStr';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Dismissible(
                                  key: Key(scan.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                  ),
                                  onDismissed: (direction) async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    await _deleteScan(scan);
                                    setModalState(() {});
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: const Text('Scan deleted'),
                                        behavior: SnackBarBehavior.floating,
                                        action: SnackBarAction(
                                          label: 'Undo',
                                          onPressed: () async {
                                            setState(() {
                                              _history.insert(index, scan);
                                            });
                                            final prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            final historyJson = _history
                                                .map((s) =>
                                                    jsonEncode(s.toJson()))
                                                .toList();
                                            await prefs.setStringList(
                                                _historyKey, historyJson);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                        child: const Icon(Icons.qr_code),
                                      ),
                                      title: Text(
                                        scan.name ??
                                            (scan.content
                                                    .replaceAll('\n', ' ')
                                                    .substring(
                                                        0,
                                                        scan.content.length > 30
                                                            ? 30
                                                            : scan.content.length) +
                                                (scan.content.length > 30
                                                    ? '...'
                                                    : '')),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(subTitle),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            tooltip: 'Rename List',
                                            onPressed: () {
                                              _renameScan(scan, setModalState);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy),
                                            tooltip: 'Copy to Clipboard',
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: scan.content));
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Copied scan to clipboard!'),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.share),
                                            tooltip: 'Share List',
                                            onPressed: () {
                                              _shareHistoryList(scan.content);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.restore),
                                            tooltip: 'Load into Editor',
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _restoreScan(scan);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Barcode Scanner'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: _showHistoryBottomSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Scanned barcodes will appear here...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<SeparatorType>(
                            initialValue: _selectedSeparator,
                            decoration: InputDecoration(
                              labelText: 'Separator Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            items: SeparatorType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSeparator = val;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _addSeparator,
                          icon: const Icon(Icons.add_box),
                          label: const Text('Add'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedSeparator == SeparatorType.custom) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customSeparatorController,
                        decoration: InputDecoration(
                          labelText: 'Custom Separator',
                          hintText: 'Enter characters (e.g. | or ,)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saveScan,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareList,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanBarcode,
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Barcode'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late MobileScannerController _scannerController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AiBarcodeScanner(
      controller: _scannerController,
      onDetect: (capture) {
        if (_isProcessing) return;
        final List<Barcode> barcodes = capture.barcodes;
        if (barcodes.isNotEmpty) {
          final barcode = barcodes.first;
          if (barcode.rawValue != null) {
            setState(() {
              _isProcessing = true;
            });
            _scannerController.stop();
            _showResult(barcode.rawValue!);
          }
        }
      },
      appBarBuilder: (context, controller) => AppBar(
        title: const Text('Scan Barcode',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      galleryButtonType: GalleryButtonType.none,
      bottomSheetBuilder: (context, controller) {
        return ValueListenableBuilder<MobileScannerState>(
          valueListenable: controller,
          builder: (context, state, child) {
            if (!state.isInitialized) {
              return const SizedBox.shrink();
            }
            final double zoom = state.zoomScale;
            final bool isTorchOn = state.torchState == TorchState.on;

            return Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              elevation: 8,
              color: Colors.black.withValues(alpha: 0.75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_out, color: Colors.white70),
                          onPressed: () {
                            controller.setZoomScale((zoom - 0.1).clamp(0.0, 1.0));
                          },
                        ),
                        Expanded(
                          child: Slider(
                            value: zoom,
                            onChanged: (val) {
                              controller.setZoomScale(val);
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            inactiveColor: Colors.white24,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_in, color: Colors.white70),
                          onPressed: () {
                            controller.setZoomScale((zoom + 0.1).clamp(0.0, 1.0));
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(zoom * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isTorchOn
                                ? Colors.amber.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.1),
                            foregroundColor: isTorchOn ? Colors.amber : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isTorchOn
                                    ? Colors.amber.withValues(alpha: 0.5)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: () => controller.toggleTorch(),
                          icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
                          label: Text(
                            isTorchOn ? 'Torch On' : 'Torch Off',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          children: [1, 2, 4].map((multiplier) {
                            final double targetScale = multiplier == 1
                                ? 0.0
                                : (multiplier == 2 ? 0.33 : 1.0);
                            final bool isSelected = (zoom - targetScale).abs() < 0.1;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                showCheckmark: false,
                                label: Text('${multiplier}x'),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    controller.setZoomScale(targetScale);
                                  }
                                },
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.black : Colors.white,
                                ),
                                selectedColor: Theme.of(context).colorScheme.primary,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide.none,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showResult(String barcodeValue) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(barcodeValue: barcodeValue),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      if (result == 'rescan') {
        setState(() {
          _isProcessing = false;
        });
        _scannerController.start();
      } else {
        Navigator.pop(context, result);
      }
    } else {
      Navigator.pop(context);
    }
  }
}

class ResultScreen extends StatelessWidget {
  final String barcodeValue;

  const ResultScreen({super.key, required this.barcodeValue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.qr_code_2,
                size: 96,
                color: Colors.teal,
              ),
              const SizedBox(height: 24),
              const Text(
                'Scanned Value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SelectableText(
                  barcodeValue,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context, barcodeValue);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add to List'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context, 'rescan');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Rescan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedScan {
  final String id;
  final String content;
  final DateTime timestamp;
  final String? name;

  SavedScan({
    required this.id,
    required this.content,
    required this.timestamp,
    this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'name': name,
      };

  factory SavedScan.fromJson(Map<String, dynamic> json) => SavedScan(
        id: json['id'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        name: json['name'] as String?,
      );
}
