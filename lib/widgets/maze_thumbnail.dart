import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';
import '../game/data/level_data.dart';

/// Miniature preview of a level drawn straight from its grid data, tinted with
/// the level's accent colour.
class MazeThumbnail extends StatelessWidget {
  const MazeThumbnail({
    super.key,
    required this.data,
    required this.accent,
  });

  final LevelData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MazeThumbnailPainter(data: data, accent: accent),
      size: Size.infinite,
    );
  }
}

class _MazeThumbnailPainter extends CustomPainter {
  _MazeThumbnailPainter({required this.data, required this.accent});

  final LevelData data;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = data.width;
    final rows = data.height;
    final cell = (size.width / cols) < (size.height / rows)
        ? size.width / cols
        : size.height / rows;
    final originX = (size.width - cell * cols) / 2;
    final originY = (size.height - cell * rows) / 2;

    final wallPaint = Paint()..color = accent;
    final floorPaint = Paint()
      ..color = accent.withValues(alpha: 0.10);
    final fishPaint = Paint()..color = GameColors.yellow;
    final exitPaint = Paint()..color = GameColors.red;
    final spawnPaint = Paint()..color = GameColors.white;

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final rect = Rect.fromLTWH(
          originX + x * cell,
          originY + y * cell,
          cell,
          cell,
        );
        final symbol = data.maze[y][x];

        if (symbol == '#') {
          canvas.drawRect(rect.deflate(cell * 0.06), wallPaint);
        } else {
          canvas.drawRect(rect.deflate(cell * 0.10), floorPaint);
        }

        if (symbol == 'F') {
          canvas.drawCircle(rect.center, cell * 0.28, fishPaint);
        } else if (symbol == 'E') {
          canvas.drawCircle(rect.center, cell * 0.30, exitPaint);
        } else if (symbol == 'P') {
          canvas.drawCircle(rect.center, cell * 0.26, spawnPaint);
        }
      }
    }

    // Outline the whole board so the thumbnail reads as a framed maze.
    final frame = Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(
        originX,
        originY,
        cell * cols,
        cell * rows,
      ),
      frame,
    );
  }

  @override
  bool shouldRepaint(_MazeThumbnailPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.accent != accent;
  }
}
