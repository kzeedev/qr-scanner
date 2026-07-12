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
          title: 'Barcode Scanner',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF1E1E1E),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFA726),
              secondary: Color(0xFF2C2C2E),
              surface: Color(0xFF222222),
              onSurface: Colors.white,
            ),
          ),
          themeMode: ThemeMode.dark,
          home: const OnboardingScreen(),
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
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          onBarcodeScanned: (barcode) {
            setState(() {
              String separator = '';
              if (_textController.text.isNotEmpty) {
                switch (_selectedSeparator) {
                  case SeparatorType.newLine:
                    separator = '\n';
                    break;
                  case SeparatorType.emptyLine:
                    separator = '\n\n';
                    break;
                  case SeparatorType.dash:
                    separator = ' - ';
                    break;
                  case SeparatorType.dot:
                    separator = ' . ';
                    break;
                  case SeparatorType.custom:
                    separator = _customSeparatorController.text;
                    break;
                }
              }
              _textController.text = _textController.text + separator + barcode;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });
          },
        ),
      ),
    );

    if (result != null && result is String) {
      if (result == 'show_history') {
        // Wait a frame so the scanner screen is fully popped before showing the history sheet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showHistoryBottomSheet();
        });
      }
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
                                                            : scan.content
                                                                .length) +
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

  void _showSeparatorDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Separator Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<SeparatorType>(
                    initialValue: _selectedSeparator,
                    dropdownColor: const Color(0xFF222222),
                    decoration: InputDecoration(
                      labelText: 'Separator Type',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                    ),
                    items: SeparatorType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label,
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSeparator = val;
                        });
                        setModalState(() {});
                      }
                    },
                  ),
                  if (_selectedSeparator == SeparatorType.custom) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customSeparatorController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Custom Separator',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Enter characters (e.g. | or ,)',
                        hintStyle: const TextStyle(color: Colors.white30),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      _addSeparator();
                      Navigator.pop(context);
                    },
                    child: const Text('Insert Separator'),
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
        title: const Text('Barcode Scanner'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                  controller: _textController,
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
  }
}

class ScannerScreen extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  const ScannerScreen({super.key, required this.onBarcodeScanned});

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
      invertImage: true,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double scanWindowSize = 240;
    final Rect scanWindow = Rect.fromCenter(
      center: Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2 - 60,
      ),
      width: scanWindowSize,
      height: scanWindowSize,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AiBarcodeScanner(
            controller: _scannerController,
            scanWindow: scanWindow,
            fit: BoxFit.cover,
            galleryButtonType: GalleryButtonType.none,
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
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: ValueListenableBuilder<MobileScannerState>(
                valueListenable: controller,
                builder: (context, state, child) {
                  final bool isTorchOn = state.torchState == TorchState.on;
                  return IconButton(
                    icon: Icon(
                      isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: isTorchOn ? const Color(0xFFFFA726) : Colors.white,
                      size: 28,
                    ),
                    onPressed: () => controller.toggleTorch(),
                  );
                },
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 26),
                  onPressed: () => controller.switchCamera(),
                ),
                const SizedBox(width: 12),
              ],
            ),
            overlayBuilder: (context, constraints, controller, isSuccess) {
              return Stack(
                children: [
                  IgnorePointer(
                    child: ScannerCustomOverlay(
                      scanWindow: scanWindow,
                      controller: controller,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 32,
                    right: 32,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ValueListenableBuilder<MobileScannerState>(
                        valueListenable: controller,
                        builder: (context, state, child) {
                          if (!state.isInitialized) {
                            return const SizedBox.shrink();
                          }
                          final double currentZoom = state.zoomScale;
                          return Row(
                            children: [
                              const Icon(Icons.zoom_out, color: Colors.white70, size: 18),
                              Expanded(
                                child: Slider(
                                  value: currentZoom,
                                  activeColor: const Color(0xFFFFA726),
                                  inactiveColor: Colors.white24,
                                  onChanged: (val) {
                                    controller.setZoomScale(val);
                                  },
                                ),
                              ),
                              const Icon(Icons.zoom_in, color: Colors.white70, size: 18),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
            bottomNavigationBarBuilder: (context, controller) {
              return CurvedBottomNavigationBar(
                onLeftTap: () {
                  Navigator.pop(context);
                },
                onCenterTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _isProcessing = false;
                  });
                  _scannerController.start();
                },
                onRightTap: () {
                  Navigator.pop(context, 'show_history');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showResult(String barcodeValue) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          barcodeValue: barcodeValue,
          onSave: (val) {
            widget.onBarcodeScanned(val);
          },
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      if (result == 'rescan') {
        setState(() {
          _isProcessing = false;
        });
        _scannerController.start();
      } else if (result == 'show_history') {
        Navigator.pop(context, 'show_history');
      }
    } else {
      setState(() {
        _isProcessing = false;
      });
      _scannerController.start();
    }
  }
}

class ScannerCustomOverlay extends StatefulWidget {
  final Rect scanWindow;
  final MobileScannerController controller;

  const ScannerCustomOverlay({
    super.key,
    required this.scanWindow,
    required this.controller,
  });

  @override
  State<ScannerCustomOverlay> createState() => _ScannerCustomOverlayState();
}

class _ScannerCustomOverlayState extends State<ScannerCustomOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: ScannerOverlayPainter(scanWindow: widget.scanWindow),
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final double topPosition = widget.scanWindow.top +
                (widget.scanWindow.height * _animation.value);
            return Positioned(
              top: topPosition,
              left: widget.scanWindow.left + 12,
              width: widget.scanWindow.width - 24,
              child: Container(
                height: 2,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFA726),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFFA726),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color cornerColor;

  ScannerOverlayPainter(
      {required this.scanWindow, this.cornerColor = const Color(0xFFFFA726)});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanWindow)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    const double cornerLength = 24;

    // Top Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.left, scanWindow.top + cornerLength)
        ..lineTo(scanWindow.left, scanWindow.top)
        ..lineTo(scanWindow.left + cornerLength, scanWindow.top),
      cornerPaint,
    );

    // Top Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.right, scanWindow.top + cornerLength)
        ..lineTo(scanWindow.right, scanWindow.top)
        ..lineTo(scanWindow.right - cornerLength, scanWindow.top),
      cornerPaint,
    );

    // Bottom Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.left, scanWindow.bottom - cornerLength)
        ..lineTo(scanWindow.left, scanWindow.bottom)
        ..lineTo(scanWindow.left + cornerLength, scanWindow.bottom),
      cornerPaint,
    );

    // Bottom Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.right, scanWindow.bottom - cornerLength)
        ..lineTo(scanWindow.right, scanWindow.bottom)
        ..lineTo(scanWindow.right - cornerLength, scanWindow.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ResultScreen extends StatelessWidget {
  final String barcodeValue;
  final Function(String) onSave;

  const ResultScreen({
    super.key,
    required this.barcodeValue,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              size: 32, color: Color(0xFFFFA726)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('QR Code'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      barcodeValue,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: const Color(0xFFFFA726), width: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 160,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.save_rounded,
                    tooltip: 'Add to List',
                    onTap: () {
                      onSave(barcodeValue);
                      Navigator.pop(context, 'rescan');
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildActionButton(
                    icon: Icons.copy_rounded,
                    tooltip: 'Copy',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: barcodeValue));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied barcode to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    tooltip: 'Share',
                    onTap: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: barcodeValue,
                          title: 'Scanned Barcode',
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CurvedBottomNavigationBar(
        onLeftTap: () {
          Navigator.pop(context);
        },
        onCenterTap: () {
          Navigator.pop(context, 'rescan');
        },
        onRightTap: () {
          Navigator.pop(context, 'show_history');
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: const Color(0xFFFFA726), size: 24),
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

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.02),
                    ),
                  ),
                ),
                Positioned(
                  left: -50,
                  bottom: 50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.01),
                    ),
                  ),
                ),
                const QRScannerGraphic(size: 200),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(32, 48, 32, 80 + bottomInset),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Get Started',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your all-in-one solution for scanning and generating QR codes—fast, easy, and secure.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: bottomInset,
                  child: SizedBox(
                    width: 160,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 140,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(70),
                                topRight: Radius.circular(70),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MainScreen()),
                            );
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFA726),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QRScannerGraphic extends StatelessWidget {
  final double size;
  final Color color;
  const QRScannerGraphic(
      {super.key, this.size = 180, this.color = const Color(0xFFFFA726)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: 4),
                  left: BorderSide(color: color, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: 4),
                  right: BorderSide(color: color, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: 4),
                  left: BorderSide(color: color, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: 4),
                  right: BorderSide(color: color, width: 4),
                ),
              ),
            ),
          ),
          Icon(
            Icons.qr_code_2_rounded,
            size: size * 0.7,
            color: Colors.white,
          ),
          Container(
            width: size * 0.8,
            height: 2,
            color: color,
          ),
        ],
      ),
    );
  }
}

class CurvedBottomNavigationBar extends StatelessWidget {
  final VoidCallback onLeftTap;
  final VoidCallback onCenterTap;
  final VoidCallback onRightTap;

  const CurvedBottomNavigationBar({
    super.key,
    required this.onLeftTap,
    required this.onCenterTap,
    required this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return SizedBox(
      height: 100 + bottomInset,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 70 + bottomInset),
            painter: CurvedBottomBarPainter(),
          ),
          Container(
            height: 70 + bottomInset,
            padding: EdgeInsets.fromLTRB(48, 0, 48, bottomInset),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.grid_view_rounded,
                      color: Colors.white70, size: 28),
                  onPressed: onLeftTap,
                ),
                IconButton(
                  icon: const Icon(Icons.history_rounded,
                      color: Colors.white70, size: 28),
                  onPressed: onRightTap,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20 + bottomInset,
            child: GestureDetector(
              onTap: onCenterTap,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFA726),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurvedBottomBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    double width = size.width;
    double height = size.height;
    double center = width / 2;
    double dipWidth = 90;
    double dipHeight = 40;

    path.lineTo(center - dipWidth / 2 - 15, 0);
    path.cubicTo(
      center - dipWidth / 2,
      0,
      center - dipWidth / 2,
      dipHeight,
      center,
      dipHeight,
    );
    path.cubicTo(
      center + dipWidth / 2,
      dipHeight,
      center + dipWidth / 2,
      0,
      center + dipWidth / 2 + 15,
      0,
    );

    path.lineTo(width, 0);
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
