import 'package:flutter/material.dart';
import 'scanner_overlay_painter.dart';

class ScannerCustomOverlay extends StatefulWidget {
  final Rect scanWindow;

  const ScannerCustomOverlay({
    super.key,
    required this.scanWindow,
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
