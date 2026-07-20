import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../core/widgets/curved_bottom_navigation_bar.dart';
import 'result_screen.dart';
import 'scanner_custom_overlay.dart';

class ScannerScreen extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  const ScannerScreen({super.key, required this.onBarcodeScanned});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  Key? _readerKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final double scanWindowSize = AppConstants.defaultScanWindowSize;
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
          if (_readerKey != null)
            SizedBox.expand(
              child: ReaderWidget(
                key: _readerKey,
                onScan: _onScanSuccess,
                onControllerCreated: (controller, error) {
                  if (controller != null) {
                    _cameraController = controller;
                  }
                },
                tryInverted: true,
                tryHarder: true,
                tryRotate: true,
                cropPercent: 0.8,
                scanDelay: const Duration(milliseconds: 500),
                resolution: ResolutionPreset.max,
                lensDirection: CameraLensDirection.back,
                showFlashlight: false,
                showGallery: false,
                showToggleCamera: false,
                showScannerOverlay: false,
              ),
            ),
          // Custom overlay with scan window and animated line
          IgnorePointer(
            child: ScannerCustomOverlay(
              scanWindow: scanWindow,
            ),
          ),
          // Top bar with torch and camera switch
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: _isTorchOn ? AppColors.primary : Colors.white,
                        size: 28,
                      ),
                      onPressed: () async {
                        if (_cameraController != null) {
                          try {
                            if (_isTorchOn) {
                              await _cameraController!
                                  .setFlashMode(FlashMode.off);
                            } else {
                              await _cameraController!
                                  .setFlashMode(FlashMode.torch);
                            }
                            setState(() {
                              _isTorchOn = !_isTorchOn;
                            });
                          } catch (e) {
                            debugPrint('Error toggling torch: $e');
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_android_rounded,
                          color: Colors.white, size: 26),
                      onPressed: () {
                        // Rebuild ReaderWidget with a new key to trigger camera re-init
                        _restartScanner();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom navigation bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CurvedBottomNavigationBar(
              onLeftTap: () {
                Navigator.pop(context);
              },
              onCenterTap: () {
                HapticFeedback.mediumImpact();
                _restartScanner();
              },
              onRightTap: () {
                Navigator.pop(context, 'show_history');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onScanSuccess(Code? code) async {
    if (_isProcessing) return;
    if (code != null && code.isValid && code.text != null) {
      setState(() {
        _isProcessing = true;
      });
      _showResult(code.text!);
    }
  }

  void _restartScanner() {
    // Remove the ReaderWidget from the tree first
    setState(() {
      _isProcessing = false;
      _isTorchOn = false;
      _cameraController = null;
      _readerKey = null;
    });
    // Re-add it next frame so the old camera is fully released
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _readerKey = UniqueKey();
        });
      }
    });
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
        _restartScanner();
      } else if (result == 'show_history') {
        Navigator.pop(context, 'show_history');
      }
    } else {
      _restartScanner();
    }
  }
}
