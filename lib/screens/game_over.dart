import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/pixel_text.dart';

/// Shown when the cat runs out of hearts. RESTART replays the level from the
/// beginning with full HP; MAIN MENU returns to the hub.
class GameOverScreen extends StatelessWidget {
  const GameOverScreen({
    super.key,
    required this.level,
    required this.levelName,
    required this.score,
    required this.fishCollected,
    required this.fishTotal,
    required this.selectedCat,
    required this.onRestart,
    required this.onMainMenu,
  });

  final int level;
  final String levelName;
  final int score;
  final int fishCollected;
  final int fishTotal;
  final String selectedCat;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GameColors.background.withValues(alpha: 0.94),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ArcadePanel(
            width: 280,
            borderColor: GameColors.red,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PixelText(
                  'GAME OVER',
                  height: 14,
                  color: GameColors.red,
                ),
                const SizedBox(height: 18),
                Opacity(
                  opacity: 0.85,
                  child: Image.asset(
                    'assets/images/cats/$selectedCat/idle_0.png',
                    width: 96,
                    height: 96,
                    filterQuality: FilterQuality.none,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'LEVEL ${level.toString().padLeft(2, '0')}  '
                  '${levelName.toUpperCase()}',
                  style: const TextStyle(
                    color: GameColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FISH',
                      style: TextStyle(
                        color: GameColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    PixelText(
                      '$fishCollected/$fishTotal',
                      height: 12,
                      color: GameColors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SCORE',
                      style: TextStyle(
                        color: GameColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    PixelText(
                      score.toString().padLeft(5, '0'),
                      height: 12,
                      color: GameColors.yellow,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ArcadeMenuOption(
                    label: 'RESTART',
                    onPressed: onRestart,
                    isSelected: true,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ArcadeMenuOption(
                    label: 'MAIN MENU',
                    onPressed: onMainMenu,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
