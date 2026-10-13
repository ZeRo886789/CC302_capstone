import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'components/finish.dart';
import 'components/fish.dart';
import 'components/hazard.dart';
import 'components/maze.dart';
import 'components/player.dart';
import 'components/player_light.dart';
import 'config/game_colors.dart';
import 'config/game_config.dart';
import 'config/paw_assets.dart';
import 'data/levels.dart';
import 'systems/collision_system.dart';
import 'systems/level_manager.dart';
import 'systems/score_manager.dart';
import 'systems/save_manager.dart';

class PawQuestGame extends FlameGame with KeyboardEvents {
  PawQuestGame({
    required this.selectedCat,
    required this.initialLevel,
    required this.savedState,
    required this.onGameComplete,
    this.onExitToLevelSelect = _noop,
  }) : super(
          // Flame's documented shape: the World holds game objects and the
          // camera observes it. The camera is NOT a child of the world.
          world: World(),
          camera: CameraComponent.withFixedResolution(
            width: GameConfig.cameraWidth,
            height: GameConfig.cameraHeight,
          ),
        );

  static void _noop() {}

  final String selectedCat;
  final int initialLevel;
  final GameState savedState;
  final VoidCallback onGameComplete;

  /// Invoked when the player picks "LEVEL SELECT" from the pause menu.
  final VoidCallback onExitToLevelSelect;

  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> fishCollected = ValueNotifier<int>(0);
  final ValueNotifier<int> requiredFish = ValueNotifier<int>(0);
  final ValueNotifier<int> levelNumber = ValueNotifier<int>(1);
  final ValueNotifier<String> elapsed = ValueNotifier<String>('00:00');
  final ValueNotifier<String> hint = ValueNotifier<String>('');
  final ValueNotifier<int> hp = ValueNotifier<int>(GameConfig.startingHp);

  bool isGameOver = false;

  Player? player;
  Maze? maze;
  PlayerLight? playerLight;
  late CollisionSystem collisionSystem;
  late LevelManager levelManager;
  late ScoreManager scoreManager;

  final List<Fish> fishList = [];
  FinishFlag? finishFlag;

  int currentLevel = 1;
  double tileSize = GameConfig.tileSize;

  /// Paw Coins awarded for the most recent completion
  /// (+50 on first clear, 0 on replays).
  int lastLevelBonus = 0;

  bool levelCompleting = false;
  bool isPaused = false;
  bool _isQuitting = false;

   PlayerDirection? _heldDirection;
   final Set<PlayerDirection> _heldDirections = {};
   double _hudClock = 0;

  /// Pushes HUD state to any listening widgets. Writing to a ValueNotifier while
  /// the tree is building throws, so the very first sync (which happens inside
  /// GameWidget's first frame) is deferred to a post-frame callback.
  void _pushHudToWidgets() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final midBuild = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (midBuild) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _pushHudToWidgets());
      return;
    }
    score.value = scoreManager.score;
    fishCollected.value = scoreManager.fishCollected;
    requiredFish.value = scoreManager.requiredFish;
    levelNumber.value = currentLevel;
    elapsed.value = scoreManager.formattedTime;
  }

  @override
  Color backgroundColor() => GameColors.background;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    images.prefix = 'assets/images/';

    currentLevel = initialLevel.clamp(1, Levels.all.length).toInt();
    levelManager = LevelManager();
    scoreManager = ScoreManager();

    await _setupLevel();
  }

  int _setupGeneration = 0;

  Future<void> _setupLevel() async {
    // Every rebuild claims a new generation. If another rebuild starts while
    // this one is awaiting sprites, the stale one bails out before it can add
    // anything, so entities can never stack up.
    final generation = ++_setupGeneration;

    _isQuitting = false;
    levelCompleting = false;
    isGameOver = false;
    hp.value = GameConfig.startingHp;
    isPaused = false;
    _heldDirections.clear();
    _heldDirection = null;
    _hintCooldown = 0;
    hint.value = '';
    overlays.removeAll(['pause', 'levelComplete', 'gameComplete', 'gameOver']);

    // Remove EVERY previous level entity (maze, player, fish,
    // hazards, finish flag, player light) before building the new
    // level, so START / RETRY / NEXT LEVEL / LEVEL SELECT can
    // never leave stale entities behind.
    _teardownWorld();

    levelManager.loadLevel(currentLevel);
    collisionSystem = CollisionSystem(levelManager.levelData!);

    final data = levelManager.levelData!;
    scoreManager.reset(
      requiredFish: data.requiredFish,
      levelNumber: currentLevel,
    );
    // All HUD notifier writes go through _pushHudToWidgets so they never
    // happen while the widget tree is mid-build.
    _pushHudToWidgets();

    // Components must be added to `world`, not `camera`: CameraComponent only
    // renders viewport/backdrop/world/viewfinder, never its own children.
    final newMaze = Maze(levelData: data);
    await world.add(newMaze);
    if (_stale(generation, newMaze)) return;
    maze = newMaze;

    final start = data.playerStart;
    final newPlayer = await Player.create(
      selectedCat,
      gridX: start.x,
      gridY: start.y,
      visualSize: GameConfig.playerVisualSize,
    );
    if (_stale(generation, newPlayer)) return;
    await world.add(newPlayer);
    player = newPlayer;

    _snapCameraToPlayer();

    final fishAnimation = await Fish.buildAnimation();
    if (generation != _setupGeneration) return;
    for (final pos in data.fishPositions) {
      final fish = Fish.fromAnimation(fishAnimation, x: pos.x, y: pos.y);
      fishList.add(fish);
      await world.add(fish);
      if (generation != _setupGeneration) return;
    }

    final exit = data.exitPosition;
    final flag = FinishFlag(
      levelData: data,
      gridX: exit.x,
      gridY: exit.y,
    )..active = false;
    if (_stale(generation, flag)) {
      flag.removeFromParent();
      return;
    }
    finishFlag = flag;
    await world.add(flag);
    if (_stale(generation, flag)) return;

    if (data.hazardCount > 0) {
      final hazardSprite = await Sprite.load(PawAssets.hazard);
      if (generation != _setupGeneration) return;
      for (final point in data.hazardPositions) {
        final hazard = Hazard(
          sprite: hazardSprite,
          gridX: point.x,
          gridY: point.y,
        );
        await world.add(hazard);
        if (_stale(generation, hazard)) return;
      }
    }

    final light = PlayerLight(
      getPlayerPosition: () {
        return player?.position.clone() ??
            Vector2.zero();
      },
      radiusTiles: data.lightRadiusTiles,
    );
    playerLight = light;
    await world.add(light);
    if (_stale(generation, light)) return;
  }

  /// True when a newer [generation] took over; the component is
  /// detached and this stale setup pass stops here.
  bool _stale(int generation, Component component) {
    if (generation == _setupGeneration) return false;
    component.removeFromParent();
    return true;
  }

  /// Removes every level entity from the world. Iterates the world's
  /// actual children so hazards and the player light — which older
  // builds leaked on retry — are always cleaned up.
  void _teardownWorld() {
    for (final child in List<Component>.from(world.children)) {
      if (child is Maze ||
          child is Player ||
          child is Fish ||
          child is Hazard ||
          child is FinishFlag ||
          child is PlayerLight) {
        if (child.parent != null) child.removeFromParent();
      }
    }
    fishList.clear();
    finishFlag = null;
    playerLight = null;
    maze = null;
    player = null;
  }

  void _snapCameraToPlayer() {
    final p = player;
    if (p == null) return;

    final halfWidth =
        GameConfig.cameraWidth / 2;

    final halfHeight =
        GameConfig.cameraHeight / 2;

    // Viewfinder.position is a getter that returns a copy of the
    // camera's focus point (-transform.offset). It must be assigned
    // through the setter: mutating the returned Vector2 (setValues,
    // x +=, ...) would only change a throwaway copy and the camera
    // would never move.
    camera.viewfinder.position = Vector2(
      p.position.x
          .clamp(
            halfWidth,
            GameConfig.boardWidth - halfWidth,
          )
          .toDouble(),
      p.position.y
          .clamp(
            halfHeight,
            GameConfig.boardHeight - halfHeight,
          )
          .toDouble(),
    );
  }

  void _updateCameraFollow(double dt) {
    final p = player;
    if (p == null) return;

    final halfWidth = GameConfig.cameraWidth / 2;
    final halfHeight = GameConfig.cameraHeight / 2;

    final minX = halfWidth;
    final maxX = GameConfig.boardWidth - halfWidth;

    final minY = halfHeight;
    final maxY = GameConfig.boardHeight - halfHeight;

    final targetX = p.position.x
        .clamp(minX, maxX)
        .toDouble();

    final targetY = p.position.y
        .clamp(minY, maxY)
        .toDouble();

    final current = camera.viewfinder.position;

    const followSpeed = 12.0;

    final amount = 1 -
        math.exp(-followSpeed * dt);

    final nextX =
        current.x + (targetX - current.x) * amount;
    final nextY =
        current.y + (targetY - current.y) * amount;

    // Assign through the setter. The position getter returns a
    // copy, so mutating current.x/current.y in place would never
    // move the camera.
    camera.viewfinder.position = Vector2(nextX, nextY);
  }

  /// Full level restart with HP restored. Used by RETRY and by GAME OVER's
  /// RESTART button, so both leave the level in an identical fresh state.
  void restartLevel() {
    if (_isQuitting) return;
    isGameOver = false;
    overlays.remove('gameOver');
    _setupLevel();
  }

  // --- Test hooks -------------------------------------------------------
  // These make the damage and game-over paths reachable from tests without
  // having to walk the cat across the board.

  /// Teleports the cat onto a cell (bypasses collision).
  void debugPlacePlayerOn(int x, int y) {
    final p = player;
    if (p == null) return;
    p.stopMove();
    p.clearKnockback();
    p.setGridPosition(x, y);
    _checkHazards();
  }

  /// Ends the mercy window so the next hazard hit lands.
  void debugClearInvulnerability() {
    player?.updateInvulnerability(GameConfig.invulnerabilitySeconds + 1);
  }

  /// Forces the run to end, as if the cat had lost its last heart.
  void debugForceGameOver() {
    final p = player;
    if (p == null) return;
    p.hp = 0;
    hp.value = 0;
    _triggerGameOver();
  }

  void movePlayer(PlayerDirection direction) {
    if (isPaused || levelCompleting || _isQuitting || isGameOver) return;
    final p = player;
    if (p == null || p.isKnockedBack) return;
    if (p.canStartMove(direction, collisionSystem.canMoveTo)) {
      p.playMove(direction, collisionSystem.canMoveTo);
    }
  }

  void holdDirection(PlayerDirection direction) {
    _heldDirections.add(direction);
    _heldDirection = direction;
    movePlayer(direction);
  }

  /// Only clears the held direction if it matches [direction]. This prevents
  /// a simultaneous release on one button from killing movement on another
  /// button that is still held (multi-touch safety).
  void releaseDirection([PlayerDirection? direction]) {
    if (direction != null) {
      _heldDirections.remove(direction);
      if (_heldDirection == direction) {
        _heldDirection = _heldDirections.lastOrNull;
      }
    } else {
      _heldDirections.clear();
      _heldDirection = null;
    }
  }

  void togglePause() {
    if (levelCompleting || isGameOver) return;
    isPaused = !isPaused;
    if (isPaused) {
      scoreManager.pause();
      overlays.add('pause');
    } else {
      scoreManager.resume();
      overlays.remove('pause');
    }
  }

  void resumeGame() {
    isPaused = false;
    scoreManager.resume();
    overlays.remove('pause');
  }

  void retryLevel() {
    overlays.removeAll(['pause', 'levelComplete', 'gameComplete', 'gameOver']);
    isPaused = false;
    restartLevel();
  }

  void goToLevelSelect() {
    isPaused = false;
    _isQuitting = true;
    overlays.clear();
    onExitToLevelSelect();
  }

  void goToNextLevel() {
    if (currentLevel >= levelManager.levelCount) {
      overlays.remove('levelComplete');
      showGameComplete();
      return;
    }
    currentLevel++;
    overlays.remove('levelComplete');
    _setupLevel();
  }

  void restart() {
    currentLevel = initialLevel;
    overlays.removeAll(['pause', 'levelComplete', 'gameComplete', 'gameOver']);
    isGameOver = false;
    _setupLevel();
  }

  void completeLevel() {
    if (levelCompleting) return;
    levelCompleting = true;
    _heldDirection = null;
    scoreManager.completeLevel();
    score.value = scoreManager.score;
    elapsed.value = scoreManager.formattedTime;

    final isLastLevel = currentLevel >= levelManager.levelCount;
    savedState.addScore(scoreManager.score);

    // The +50 Paw Coin bonus is FIRST CLEAR ONLY. Replaying an
    // already-cleared level must not farm the completion bonus.
    // The actual award is handled inside onLevelCompleted() so it is
    // never double-counted; lastLevelBonus is kept only for the UI.
    final firstClear = !savedState.completedLevels.contains(currentLevel);
    lastLevelBonus = firstClear ? GameConfig.firstClearBonus : 0;
    // Records the clear, unlocks the next level, and awards first-clear
    // Paw Coins (exactly once). Luna and Mochi become AVAILABLE this way;
    // buying them is still required.
    savedState.onLevelCompleted(currentLevel);
    SaveManager.save(savedState);

    if (isLastLevel) {
      showGameComplete();
    } else {
      overlays.add('levelComplete');
    }
  }

  void showGameComplete() {
    levelCompleting = true;
    _isQuitting = true;
    // GameScreen handles the victory UI via _showGameComplete state.
    // Do NOT add a 'gameComplete' overlay (no builder exists for it).
    onGameComplete();
  }

  @override
  void onRemove() {
    score.dispose();
    fishCollected.dispose();
    requiredFish.dispose();
    levelNumber.dispose();
    elapsed.dispose();
    hint.dispose();
    hp.dispose();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isPaused || levelCompleting || _isQuitting) return;

    final p = player;
    if (p == null) return;

    // Always update invulnerability and clear knockback when the mercy
    // window expires, regardless of whether the player is currently moving.
    // The knockback lock is set in knockBack() which also calls stopMove(),
    // so it must be cleared outside the isMoving block.
    p.updateInvulnerability(dt);
    if (p.isKnockedBack && p.invulnerable <= 0) {
      p.clearKnockback();
    }

    if (p.isMoving) {
      p.updateMove(dt, collisionSystem.canMoveTo);
    } else if (_heldDirection != null) {
      final dir = _heldDirection!;
      if (p.canStartMove(dir, collisionSystem.canMoveTo)) {
        p.playMove(dir, collisionSystem.canMoveTo);
      } else {
        _heldDirection = null;
      }
    }

    _hudClock += dt;
    if (_hintCooldown > 0) {
      _hintCooldown--;
      if (_hintCooldown == 0 && hint.value.isNotEmpty) {
        hint.value = '';
      }
    }
    if (_hudClock >= 0.2) {
      _hudClock = 0;
      score.value = scoreManager.score;
      fishCollected.value = scoreManager.fishCollected;
      elapsed.value = scoreManager.formattedTime;
    }

    _checkFishCollection();
    _checkHazards();
    _checkLevelComplete();
    _updateCameraFollow(dt);
  }

  /// Hazards sit on walkable cells but cost a heart. The player is knocked back
  /// to where it came from so a single mistake cannot drain every heart.
  void _checkHazards() {
    if (isGameOver) return;
    final p = player;
    if (p == null) return;

    final data = levelManager.levelData;
    if (data == null || !data.isHazard(p.gridX, p.gridY)) return;

    if (p.takeHit()) {
      hp.value = p.hp;
      p.knockBack(p.lastDirection);
      if (p.isDead) {
        _triggerGameOver();
      } else {
        _showHpHint();
      }
    }
  }

  void _showHpHint() {
    if (_hintCooldown > 0) return;
    _hintCooldown = 60;
    hint.value = 'OUCH!  ${hp.value} ${hp.value == 1 ? 'HEART' : 'HEARTS'} LEFT';
  }

  void _triggerGameOver() {
    isGameOver = true;
    _heldDirection = null;
    scoreManager.pause();
    hint.value = '';
    overlays.add('gameOver');
  }

  void _checkFishCollection() {
    final p = player;
    if (p == null) return;

    for (final fish in fishList) {
      if (fish.collected) continue;
      if (p.gridX != fish.gridX || p.gridY != fish.gridY) continue;
      fish.collected = true;
      scoreManager.collectFish();
      savedState.pawCoins += GameConfig.fishCoinReward;
      SaveManager.save(savedState);
      fish.removeFromParent();
    }

    fishCollected.value = scoreManager.fishCollected;
    if (scoreManager.fishCollected >= scoreManager.requiredFish) {
      finishFlag?.active = true;
    }
  }

  void _checkLevelComplete() {
    if (levelCompleting) return;
    final p = player;
    if (p == null) return;

    // Use the exit position from level data directly, not the visual finish flag.
    // The finish flag is only a visual indicator at the exit location.
    final data = levelManager.levelData;
    if (data == null) return;
    final exit = data.exitPosition;

    // Check if the player has reached the exit cell. We check grid position
    // (updated when a move completes) plus the player's world position against
    // the cell center of the exit. This handles both:
    // 1. Player grid-snapped onto the exit cell
    // 2. Player mid-animation onto the exit cell (grid not yet updated)
    final exitWorldX = GameConfig.cellCenterX(exit.x);
    final exitWorldY = GameConfig.cellCenterY(exit.y);
    final distance = (p.position - Vector2(exitWorldX, exitWorldY)).length;
    final tileSize = GameConfig.tileSize;

    // The player has reached the exit if they are grid-snapped on the exit cell
    // OR if they are mid-move and close enough to the exit center (within
    // half a tile). This ensures the level completes reliably when the player
    // visually reaches the finish flag sprite, without requiring them to
    // travel beyond the visible finish.
    final atExit = (p.gridX == exit.x && p.gridY == exit.y) ||
        distance < (tileSize * 0.5);

    if (!atExit) return;

    if (scoreManager.fishCollected < scoreManager.requiredFish) {
      // Standing on/near the exit before collecting all fish: show hint.
      _showHint();
      return;
    }
    completeLevel();
  }

  int _hintCooldown = 0;

  /// Surfaces "COLLECT ALL FISH!" when the player touches a locked exit.
  void _showHint() {
    if (_hintCooldown > 0) return;
    _hintCooldown = 90; // roughly 1.5 seconds at 60fps
    final remaining = scoreManager.requiredFish - scoreManager.fishCollected;
    hint.value = 'COLLECT ALL FISH!  $remaining LEFT';
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      if (event is KeyUpEvent) {
        // Re-evaluate which movement key is still held so that releasing
        // one arrow key does not kill movement when another is still down.
        final up = keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
            keysPressed.contains(LogicalKeyboardKey.keyW);
        final down = keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
            keysPressed.contains(LogicalKeyboardKey.keyS);
        final left = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
            keysPressed.contains(LogicalKeyboardKey.keyA);
        final right = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
            keysPressed.contains(LogicalKeyboardKey.keyD);

        // Determine which direction was released by inferring from the key
        // that triggered this KeyUpEvent.
        PlayerDirection? releasedDir;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.keyW) {
          releasedDir = PlayerDirection.up;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.keyS) {
          releasedDir = PlayerDirection.down;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.keyA) {
          releasedDir = PlayerDirection.left;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
            event.logicalKey == LogicalKeyboardKey.keyD) {
          releasedDir = PlayerDirection.right;
        }

        if (releasedDir != null) {
          releaseDirection(releasedDir);
        } else if (!up && !down && !left && !right) {
          releaseDirection();
        } else {
          // A different movement key was released; re-derive direction.
          releaseDirection();
          if (down) {
            holdDirection(PlayerDirection.down);
          } else if (up) {
            holdDirection(PlayerDirection.up);
          } else if (right) {
            holdDirection(PlayerDirection.right);
          } else if (left) {
            holdDirection(PlayerDirection.left);
          }
        }
      }
      return KeyEventResult.ignored;
    }
    if (isPaused || levelCompleting || isGameOver) {
      return KeyEventResult.ignored;
    }

    PlayerDirection? dir;
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      dir = PlayerDirection.up;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      dir = PlayerDirection.down;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      dir = PlayerDirection.left;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      dir = PlayerDirection.right;
    }

    if (dir != null) {
      holdDirection(dir);
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent &&
        (keysPressed.contains(LogicalKeyboardKey.escape) ||
            keysPressed.contains(LogicalKeyboardKey.keyP) ||
            keysPressed.contains(LogicalKeyboardKey.pause))) {
      togglePause();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Map<String, dynamic> getLevelResult() {
    return {
      'level': currentLevel,
      'levelName': levelManager.levelData?.name ?? '',
      'score': scoreManager.score,
      'fish': '${scoreManager.fishCollected}/${scoreManager.requiredFish}',
      'time': scoreManager.formattedTime,
      'elapsedSeconds': scoreManager.elapsedSeconds,
    };
  }
}
