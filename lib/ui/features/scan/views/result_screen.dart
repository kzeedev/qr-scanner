import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../core/widgets/curved_bottom_navigation_bar.dart';

class ResultScreen extends StatefulWidget {
  final String barcodeValue;
  final String currentScannedValues;
  final ValueChanged<String>? onContentChanged;
  final Function(String) onSave;
  final Function(String) onSaveWithSeparator;

  const ResultScreen({
    super.key,
    required this.barcodeValue,
    this.currentScannedValues = '',
    this.onContentChanged,
    required this.onSave,
    required this.onSaveWithSeparator,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final TextEditingController _previewController;

  @override
  void initState() {
    super.initState();
    _previewController = TextEditingController(text: widget.currentScannedValues);
    _previewController.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    setState(() {});
    widget.onContentChanged?.call(_previewController.text);
  }

  @override
  void didUpdateWidget(covariant ResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentScannedValues != widget.currentScannedValues &&
        widget.currentScannedValues != _previewController.text) {
      _previewController.text = widget.currentScannedValues;
    }
  }

  @override
  void dispose() {
    _previewController.removeListener(_handleTextChange);
    _previewController.dispose();
    super.dispose();
  }

  int get _lineCount {
    final text = _previewController.text;
    if (text.isEmpty) return 0;
    return text.split('\n').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              size: 32, color: AppColors.primary),
          onPressed: () {
            widget.onContentChanged?.call(_previewController.text);
            Navigator.pop(context);
          },
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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scanned Value',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      widget.barcodeValue,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.dashboard_customize_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            AppStrings.dashboardPreview,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded,
                                    size: 10, color: AppColors.primary),
                                SizedBox(width: 3),
                                Text(
                                  'EDITABLE',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (_lineCount > 0)
                            Text(
                              '$_lineCount ${_lineCount == 1 ? "line" : "lines"}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 10),
                      Expanded(
                        child: TextField(
                          controller: _previewController,
                          maxLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          textAlignVertical: TextAlignVertical.top,
                          cursorColor: AppColors.primary,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          decoration: const InputDecoration(
                            hintText: AppStrings.noScannedValuesInDashboard,
                            hintStyle: TextStyle(
                              color: Colors.white30,
                              fontSize: 13,
                              height: 1.5,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.save_rounded,
                    tooltip: AppStrings.save,
                    onTap: () {
                      widget.onContentChanged?.call(_previewController.text);
                      widget.onSave(widget.barcodeValue);
                      Navigator.pop(context, 'rescan');
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.post_add_rounded,
                    tooltip: AppStrings.saveWithSeparator,
                    onTap: () {
                      widget.onContentChanged?.call(_previewController.text);
                      widget.onSaveWithSeparator(widget.barcodeValue);
                      Navigator.pop(context, 'rescan');
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.copy_rounded,
                    tooltip: 'Copy',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.barcodeValue));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied barcode to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    tooltip: 'Share',
                    onTap: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: widget.barcodeValue,
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
          widget.onContentChanged?.call(_previewController.text);
          Navigator.pop(context);
        },
        onCenterTap: () {
          widget.onContentChanged?.call(_previewController.text);
          Navigator.pop(context, 'rescan');
        },
        onRightTap: () {
          widget.onContentChanged?.call(_previewController.text);
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
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
      ),
    );
  }
}
