import 'package:flutter/material.dart';

class QRScannerGraphic extends StatelessWidget {
  final double size;
  final Color color;

  const QRScannerGraphic({
    super.key,
    this.size = 180,
    this.color = const Color(0xFFFFA726),
  });

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
