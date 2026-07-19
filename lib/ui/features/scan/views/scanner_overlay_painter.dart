import 'package:flutter/material.dart';

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color cornerColor;

  ScannerOverlayPainter({
    required this.scanWindow,
    this.cornerColor = const Color(0xFFFFA726),
  });

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
