import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/widgets/curved_bottom_navigation_bar.dart';

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
