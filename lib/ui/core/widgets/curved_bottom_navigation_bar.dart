import 'package:flutter/material.dart';

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
