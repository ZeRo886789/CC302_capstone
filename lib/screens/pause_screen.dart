import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';
import '../widgets/arcade_panel.dart';

class PauseScreen extends StatelessWidget {
  const PauseScreen({
    super.key,
    required this.onResume,
    required this.onRetry,
    required this.onLevelSelect,
    required this.onMainMenu,
  });

  final VoidCallback onResume;
  final VoidCallback onRetry;
  final VoidCallback onLevelSelect;
  final VoidCallback onMainMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GameColors.background.withValues(alpha: 0.88),
      child: Center(
        child: SingleChildScrollView(
          child: ArcadePanel(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PAUSED',
                  style: TextStyle(
                    color: GameColors.yellow,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 24),
                ArcadeMenuOption(
                  label: 'RESUME',
                  onPressed: onResume,
                  isFirst: true,
                ),
                const SizedBox(height: 8),
                ArcadeMenuOption(label: 'RETRY', onPressed: onRetry),
                const SizedBox(height: 8),
                ArcadeMenuOption(
                  label: 'LEVEL SELECT',
                  onPressed: onLevelSelect,
                ),
                const SizedBox(height: 8),
                ArcadeMenuOption(label: 'MAIN MENU', onPressed: onMainMenu),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
