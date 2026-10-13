import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';
import '../game/config/game_config.dart';
import '../game/config/paw_assets.dart';
import '../game/data/levels.dart';
import '../game/pawquest_game.dart';
import '../game/systems/save_manager.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/mobile_dpad.dart';
import '../widgets/pixel_text.dart';
import 'game_over.dart';
import 'level_complete.dart';
import 'level_select.dart';
import 'pause_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.selectedCat,
    required this.initialLevel,
    required this.savedState,
  });

  final String selectedCat;
  final int initialLevel;
  final GameState savedState;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showGameComplete = false;
  late GameState _state;
  late final PawQuestGame _game;

  @override
  void initState() {
    super.initState();
    _state = widget.savedState;
    _game = PawQuestGame(
      selectedCat: widget.selectedCat,
      initialLevel: widget.initialLevel,
      savedState: _state,
      onGameComplete: () {
        if (!mounted) return;
        setState(() => _showGameComplete = true);
      },
      onExitToLevelSelect: _backToLevelSelect,
    );
  }

  void _backToLevelSelect() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LevelSelectScreen(savedState: _state),
      ),
    );
  }

  @override
  void dispose() {
    _game.overlays.clear();
    super.dispose();
  }

  void _restartGame() {
    setState(() => _showGameComplete = false);
    _game.restart();
  }

  void _backToMainMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_showGameComplete) {
      return _buildGameComplete();
    }

    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHud(),
            _buildStatusStrip(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GameWidget<PawQuestGame>(
                      game: _game,
                      overlayBuilderMap: {
                        'pause': (_, game) => PauseScreen(
                          onResume: game.resumeGame,
                          onRetry: game.retryLevel,
                          onLevelSelect: game.goToLevelSelect,
                          onMainMenu: _backToMainMenu,
                        ),
                         'levelComplete': (_, game) => LevelCompleteScreen(
                           level: game.currentLevel,
                           levelName: game.levelManager.levelData?.name ?? '',
                           score: game.scoreManager.score,
                           fishCollected: game.scoreManager.fishCollected,
                           fishTotal: game.scoreManager.requiredFish,
                           time: game.scoreManager.formattedTime,
                           coinsEarned: game.lastLevelBonus,
                           totalCoins: game.savedState.pawCoins,
                           isLastLevel: game.currentLevel >=
                               game.levelManager.levelCount,
                           selectedCat: widget.selectedCat,
                           onNextLevel: game.goToNextLevel,
                           onRetry: game.retryLevel,
                           onLevelSelect: game.goToLevelSelect,
                           onMainMenu: _backToMainMenu,
                         ),
                        'gameOver': (_, game) => GameOverScreen(
                          level: game.currentLevel,
                          levelName:
                              game.levelManager.levelData?.name ?? '',
                          score: game.scoreManager.score,
                          fishCollected: game.scoreManager.fishCollected,
                          fishTotal: game.scoreManager.requiredFish,
                          selectedCat: widget.selectedCat,
                          onRestart: game.restartLevel,
                          onMainMenu: _backToMainMenu,
                        ),
                      },
                    ),
                  ),
                  // Transient "collect all fish" warning over the board.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 24,
                    child: ValueListenableBuilder<String>(
                      valueListenable: _game.hint,
                      builder: (context, message, _) => message.isEmpty
                          ? const SizedBox.shrink()
                          : Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                color: GameColors.background
                                    .withValues(alpha: 0.85),
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    color: GameColors.yellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: MobileDPad(
                onDirectionPressed: _game.movePlayer,
                onDirectionHeld: _game.holdDirection,
                onDirectionReleased: (dir) => _game.releaseDirection(dir),
                onPause: _game.togglePause,
              ),            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: GameColors.hudBackground,
        border: Border(
          bottom: BorderSide(color: GameColors.panelBlue, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1UP score.
          ValueListenableBuilder<int>(
            valueListenable: _game.score,
            builder: (context, value, _) => _hudBlock(
              label: '1UP',
              labelColor: GameColors.red,
              value: value.toString().padLeft(5, '0'),
            ),
          ),
          const SizedBox(width: 16),
          // High score.
          _hudBlock(
            label: 'HIGH SCORE',
            labelColor: GameColors.red,
            value: _state.highScore.toString().padLeft(5, '0'),
          ),
          const Spacer(),
          // Level.
          ValueListenableBuilder<int>(
            valueListenable: _game.levelNumber,
            builder: (context, level, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                PixelText(
                  'LEVEL',
                  height: 8,
                  spacing: 1,
                  color: GameColors.red,
                ),
                const SizedBox(height: 5),
                PixelText(
                  level.toString().padLeft(2, '0'),
                  height: 16,
                  spacing: 1,
                  color: GameColors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudBlock({
    required String label,
    required Color labelColor,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelText(
          label,
          height: 8,
          spacing: 1,
          color: labelColor,
        ),
        const SizedBox(height: 5),
        PixelText(
          value,
          height: 16,
          spacing: 1,
          color: GameColors.white,
        ),
      ],
    );
  }

  Widget _buildStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/ui/icons/life_${widget.selectedCat}.png',
                width: 20,
                height: 20,
                filterQuality: FilterQuality.none,
              ),
              const SizedBox(width: 6),
              // Hearts track the live HP value, not a fixed count.
              ValueListenableBuilder<int>(
                valueListenable: _game.hp,
                builder: (context, hearts, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < GameConfig.startingHp; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Image.asset(
                          'assets/images/ui/icons/heart.png',
                          width: 14,
                          height: 14,
                          filterQuality: FilterQuality.none,
                          color: i < hearts ? null : GameColors.darkGray,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Image.asset(
                      'assets/images/${PawAssets.fishIcon}',
                     width: 18,
                     height: 18,
                     filterQuality: FilterQuality.none,
                   ),
                  const SizedBox(width: 4),
                  ValueListenableBuilder<int>(
                    valueListenable: _game.fishCollected,
                    builder: (context, collected, _) =>
                        ValueListenableBuilder<int>(
                      valueListenable: _game.requiredFish,
                      builder: (context, total, _) => Text(
                        '$collected/$total',
                        style: const TextStyle(
                          color: GameColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ValueListenableBuilder<String>(
                    valueListenable: _game.elapsed,
                    builder: (context, time, _) => Text(
                      'TIME $time',
                      style: const TextStyle(
                        color: GameColors.yellow,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameComplete() {
    final totalFish = Levels.all.fold(0, (sum, l) => sum + l.requiredFish);
    final catsUnlocked = _state.ownedCatCount;

    return Container(
      color: GameColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      GameColors.yellow,
                      GameColors.orange,
                      GameColors.red,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'PAWQUEST',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 7,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'COMPLETE!',
                  style: TextStyle(
                    color: GameColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final offset in const [
                      Offset(-52, -34),
                      Offset(54, -26),
                      Offset(-44, 36),
                      Offset(48, 40),
                    ])
                      Positioned(
                        left: 48 + offset.dx,
                        top: 44 + offset.dy,
                        child: Image.asset(
                          'assets/images/effects/sparkle_${offset.dx.isNegative ? 'small' : 'big'}.png',
                          width: 18,
                          height: 18,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    Image.asset(
                      'assets/images/cats/${widget.selectedCat}/idle_0.png',
                      width: 96,
                      height: 96,
                      filterQuality: FilterQuality.none,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ArcadePanel(
                  width: 280,
                  child: Column(
                    children: [
                      _completeRow('LEVELS', '${Levels.all.length}/${Levels.all.length}'),
                      const SizedBox(height: 10),
                      _completeRow('FISH FOUND', '$totalFish/$totalFish'),
                      const SizedBox(height: 10),
                      _completeRow('CATS UNLOCKED', '$catsUnlocked/3'),
                      const SizedBox(height: 10),
                      _completeRow(
                        'FINAL SCORE',
                        _state.highScore.toString().padLeft(5, '0'),
                        highlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 240,
                  child: Column(
                    children: [
                      ArcadeMenuOption(
                        label: 'PLAY AGAIN',
                        onPressed: _restartGame,
                        isSelected: true,
                      ),
                      const SizedBox(height: 8),
                      ArcadeMenuOption(
                        label: 'MAIN MENU',
                        onPressed: _backToMainMenu,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _completeRow(String label, String value, {bool highlight = false}) {
    return Row(
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
        Text(
          value,
          style: TextStyle(
            color: highlight ? GameColors.yellow : GameColors.white,
            fontSize: highlight ? 18 : 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
