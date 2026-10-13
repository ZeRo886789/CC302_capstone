import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';

class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final scoreStr = score.toString().padLeft(5, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GameColors.hudBackground,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: GameColors.border, width: 1),
      ),
      child: Text(
        'SCORE $scoreStr',
        style: const TextStyle(
          color: GameColors.yellow,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
