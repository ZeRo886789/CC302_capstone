import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/pixel_text.dart';

class LevelCompleteScreen extends StatelessWidget {
  const LevelCompleteScreen({
    super.key,
    required this.level,
    required this.levelName,
    required this.score,
    required this.fishCollected,
    required this.fishTotal,
    required this.time,
    required this.onNextLevel,
    required this.onRetry,
    required this.onLevelSelect,
    required this.onMainMenu,
    required this.isLastLevel,
    required this.coinsEarned,
    required this.totalCoins,
    this.selectedCat = 'kuro',
  });

  final int level;
  final String levelName;
  final int score;
  final int fishCollected;
  final int fishTotal;
  final String time;

  /// Paw Coins awarded for this clear (+50 first clear, 0 replay).
  final int coinsEarned;

  /// Total Paw Coins held after the clear.
  final int totalCoins;

  final VoidCallback onNextLevel;
  final VoidCallback onRetry;
  final VoidCallback onLevelSelect;
  final VoidCallback onMainMenu;
  final bool isLastLevel;
  final String selectedCat;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GameColors.background.withValues(alpha: 0.92),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ArcadePanel(
            width: 280,
            borderColor: GameColors.yellow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PixelText(
                  'LEVEL COMPLETE',
                  height: 12,
                  color: GameColors.yellow,
                ),
                const SizedBox(height: 16),
                // The real cat sprite, surrounded by sparkle effects.
                Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final spot in const [
                      Offset(-46, -38),
                      Offset(48, -30),
                      Offset(-40, 40),
                      Offset(44, 42),
                    ])
                      Positioned(
                        left: 48 + spot.dx,
                        top: 44 + spot.dy,
                        child: Image.asset(
                          spot.dx.isNegative
                              ? 'assets/images/effects/sparkle_small.png'
                              : 'assets/images/effects/sparkle_big.png',
                          width: 16,
                          height: 16,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    Image.asset(
                      'assets/images/cats/$selectedCat/idle_0.png',
                      width: 96,
                      height: 96,
                      filterQuality: FilterQuality.none,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                PixelText(
                  'LEVEL ${level.toString().padLeft(2, '0')}  '
                  '${levelName.toUpperCase()}',
                  height: 12,
                  color: GameColors.white,
                ),
                const SizedBox(height: 14),
                _stat('TIME', time),
                _stat('FISH', '$fishCollected/$fishTotal'),
                _stat('SCORE', score.toString().padLeft(5, '0')),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/tiles/extra/coin.png',
                          width: 14,
                          height: 14,
                          filterQuality: FilterQuality.none,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'PAW COINS',
                          style: TextStyle(
                            color: GameColors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    PixelText(
                      '+$coinsEarned',
                      height: 12,
                      color: GameColors.yellow,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _stat('TOTAL COINS', totalCoins.toString().padLeft(5, '0')),
                const SizedBox(height: 18),
                if (!isLastLevel) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ArcadeMenuOption(
                      label: 'NEXT LEVEL',
                      onPressed: onNextLevel,
                      isSelected: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ArcadeMenuOption(
                    label: 'RETRY',
                    onPressed: onRetry,
                    isSelected: !isLastLevel,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ArcadeMenuOption(
                    label: 'LEVEL SELECT',
                    onPressed: onLevelSelect,
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

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: GameColors.red,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          PixelText(value, height: 12, color: GameColors.white),
        ],
      ),
    );
  }
}
