import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';

/// Pixel-art padlock drawn with rectangles so it matches the game's 8-bit look
/// instead of using a Material icon.
class PixelLock extends StatelessWidget {
  const PixelLock({super.key, this.size = 26, this.color = GameColors.yellow});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PixelLockPainter(color: color),
    );
  }
}

class _PixelLockPainter extends CustomPainter {
  _PixelLockPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 8;
    final paint = Paint()..color = color;
    final dark = Paint()..color = GameColors.background;

    // Shackle: two uprights joined by a solid bar.
    canvas.drawRect(Rect.fromLTWH(unit * 2, unit * 1, unit, unit * 3), paint);
    canvas.drawRect(Rect.fromLTWH(unit * 5, unit * 1, unit, unit * 3), paint);
    canvas.drawRect(Rect.fromLTWH(unit * 2, unit * 1, unit * 4, unit), paint);

    // Body.
    canvas.drawRect(Rect.fromLTWH(unit, unit * 4, unit * 6, unit * 3), paint);

    // Keyhole punched back out.
    canvas.drawRect(
      Rect.fromLTWH(unit * 3, unit * 5, unit * 2, unit * 1),
      dark,
    );
    canvas.drawRect(
      Rect.fromLTWH(unit * 3, unit * 6, unit * 2, unit * 1),
      dark,
    );
  }

  @override
  bool shouldRepaint(_PixelLockPainter oldDelegate) =>
      oldDelegate.color != color;
}
