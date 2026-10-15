import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';
import '../game/config/paw_assets.dart';
import '../game/data/level_data.dart';
import '../game/data/levels.dart';
import '../game/systems/save_manager.dart';
import '../widgets/maze_thumbnail.dart';
import '../widgets/pixel_lock.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key, this.savedState});

  final GameState? savedState;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  late Future<GameState> _stateFuture;

  @override
  void initState() {
    super.initState();
    _stateFuture = widget.savedState != null
        ? Future.value(widget.savedState)
        : SaveManager.load();
  }

  void _selectLevel(GameState state, int level) {
    // Locked levels must never start a game.
    if (!state.isLevelUnlocked(level)) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          selectedCat: state.selectedCat,
          initialLevel: level,
          savedState: state,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: FutureBuilder<GameState>(
          future: _stateFuture,
          builder: (context, snapshot) {
            final state = snapshot.data ?? GameState();
            return Column(
              children: [
                _buildHeader(state),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: Levels.all.length,
                        itemBuilder: (context, index) {
                          final level = index + 1;
                          return _LevelCard(
                            level: level,
                            data: Levels.getLevel(level),
                            unlocked: state.isLevelUnlocked(level),
                            cleared: level < state.highestUnlockedLevel,
                            onTap: () => _selectLevel(state, level),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(GameState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        color: GameColors.panel,
        border: Border(
          bottom: BorderSide(color: GameColors.panelBlue, width: 3),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'SELECT LEVEL',
              style: TextStyle(
                color: GameColors.yellow,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
          Text(
            '${state.highestUnlockedLevel}/5 UNLOCKED',
            style: const TextStyle(
              color: GameColors.white,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: GameColors.white),
            tooltip: 'Back',
          ),
        ],
      ),
    );
  }
}

/// Five filled stars for the difficulty row.
class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Image.asset(
              'assets/images/${PawAssets.star}',
              width: 9,
              height: 9,
              filterQuality: FilterQuality.none,
              color: i < stars ? GameColors.yellow : GameColors.darkGray,
            ),
          ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.data,
    required this.unlocked,
    required this.cleared,
    required this.onTap,
  });

  final int level;
  final LevelData data;
  final bool unlocked;
  final bool cleared;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = LevelTheme.accent(data.theme);
    final iconColor = unlocked ? accent : GameColors.gray;
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: unlocked ? GameColors.panel : GameColors.panelDark,
          border: Border.all(
            color: unlocked ? accent : GameColors.border,
            width: 3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'LEVEL ${level.toString().padLeft(2, '0')}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (cleared)
                    Opacity(
                      opacity: 0.9,
                      child: Image.asset(
                        'assets/images/${PawAssets.star}',
                        width: 14,
                        height: 14,
                        filterQuality: FilterQuality.none,
                        color: GameColors.green,
                      ),
                    )
                  else if (!unlocked)
                    const PixelLock(size: 14),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Opacity(
                  opacity: unlocked ? 1 : 0.25,
                  child: MazeThumbnail(data: data, accent: accent),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unlocked ? GameColors.white : GameColors.gray,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              _statRow(iconColor, PawAssets.fishIcon, '${data.requiredFish}'),
              const SizedBox(height: 2),
              _statRow(iconColor, PawAssets.hazardIcon, '${data.hazardCount}'),
              const SizedBox(height: 4),
              _DifficultyRow(stars: level),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(Color color, String asset, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/$asset',
          width: 11,
          height: 11,
          filterQuality: FilterQuality.none,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Accent colour per level theme, so each maze reads distinctly.
class LevelTheme {
  LevelTheme._();

  static Color accent(String theme) {
    switch (theme) {
      case 'blue':
        return const Color(0xFF4488FF);
      case 'green':
        return const Color(0xFF44DD88);
      case 'red':
        return const Color(0xFFFF5555);
      case 'gray':
        return const Color(0xFFAAAAAA);
      case 'ice':
        return const Color(0xFF7FE8FF);
      default:
        return GameColors.panelBlue;
    }
  }
}
