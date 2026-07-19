import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../domain/models/saved_scan.dart';
import '../view_models/dashboard_view_model.dart';

class HistoryBottomSheet extends StatelessWidget {
  final DashboardViewModel viewModel;

  const HistoryBottomSheet({super.key, required this.viewModel});

  static void show(BuildContext context, DashboardViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return HistoryBottomSheet(viewModel: viewModel);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    if (viewModel.history.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _confirmClearAll(context),
                        icon: const Icon(Icons.delete_sweep),
                        label: const Text('Clear All'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: viewModel.history.isEmpty
                    ? _buildEmptyState(context)
                    : _buildHistoryList(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: viewModel.history.length,
      itemBuilder: (context, index) {
        final scan = viewModel.history[index];
        final dateStr =
            '${scan.timestamp.year}-${scan.timestamp.month.toString().padLeft(2, '0')}-${scan.timestamp.day.toString().padLeft(2, '0')} ${scan.timestamp.hour.toString().padLeft(2, '0')}:${scan.timestamp.minute.toString().padLeft(2, '0')}';
        final lines = scan.content.split('\n').where((l) => l.trim().isNotEmpty).length;
        final subTitle = '$lines barcode${lines == 1 ? '' : 's'} • $dateStr';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Dismissible(
            key: Key(scan.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            onDismissed: (direction) async {
              final messenger = ScaffoldMessenger.of(context);
              await viewModel.deleteScan(scan);
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Scan deleted'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => viewModel.undoDelete(index, scan),
                  ),
                ),
              );
            },
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.qr_code),
                ),
                title: Text(
                  scan.name ??
                      (scan.content.replaceAll('\n', ' ').substring(
                              0, scan.content.length > 30 ? 30 : scan.content.length) +
                          (scan.content.length > 30 ? '...' : '')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(subTitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Rename List',
                      onPressed: () => _showRenameDialog(context, scan),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy to Clipboard',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: scan.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied scan to clipboard!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'Share List',
                      onPressed: () => _shareHistoryList(scan.content),
                    ),
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: 'Load into Editor',
                      onPressed: () {
                        Navigator.pop(context);
                        _restoreScan(context, scan);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text('Are you sure you want to permanently delete all saved scans?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
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
  }

  Future<void> _showRenameDialog(BuildContext context, SavedScan scan) async {
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

    if (newName != null) {
      await viewModel.renameScan(scan.id, newName);
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

  void _restoreScan(BuildContext context, SavedScan scan) {
    if (viewModel.textController.text.isNotEmpty &&
        viewModel.textController.text != scan.content) {
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
                _applyRestore(context, scan.content);
              },
              child: const Text('Restore'),
            ),
          ],
        ),
      );
    } else {
      _applyRestore(context, scan.content);
    }
  }

  void _applyRestore(BuildContext context, String content) {
    viewModel.applyRestore(content);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded from history!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
