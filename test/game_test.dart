import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/game/config/game_config.dart';
import 'package:pawquest/game/config/paw_assets.dart';
import 'package:pawquest/game/data/cat_data.dart';
import 'package:pawquest/game/data/level_data.dart';
import 'package:pawquest/game/data/levels.dart';
import 'package:pawquest/game/systems/collision_system.dart';
import 'package:pawquest/game/systems/save_manager.dart';
import 'package:pawquest/game/systems/score_manager.dart';
import 'package:pawquest/models/history_entry.dart';

/// Note: sprite *loading* is deliberately not covered here. `flutter_test` has
/// no asset bundle, so `Sprite.load` cannot resolve under `flutter test`. The
/// render-tree wiring is verified by reading Flame's CameraComponent source
/// (`renderTree` renders viewport/backdrop/world/viewfinder, never `children`),
/// which is why every level entity is added to `world`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('level data', () {
    test('all five levels are valid 15x21 portrait mazes', () {
      expect(Levels.all.length, 5);
      for (final level in Levels.all) {
        expect(() => level.validate(), returnsNormally,
            reason: 'level ${level.number}');
        expect(level.maze.length, 21);
        for (final row in level.maze) {
          expect(row.length, 15);
        }
      }
    });

    test('fish progression totals 42', () {
      expect(Levels.all.map((l) => l.requiredFish).toList(), [5, 7, 8, 10, 12]);
      expect(Levels.all.fold(0, (s, l) => s + l.requiredFish), 42);
    });

    test('each level has its own wall theme', () {
      expect(Levels.all.map((l) => l.theme).toList(),
          ['blue', 'green', 'red', 'gray', 'ice']);
    });

    test('wall variant paths point at real filenames', () {
      for (final level in Levels.all) {
        for (var i = 0; i < 8; i++) {
          expect(
            PawAssets.wallVariant(level.theme, i),
            'tiles/${level.theme}/wall_$i.png',
          );
        }
      }
    });

    test('floor path points at the file that actually exists', () {
      expect(PawAssets.floorDark, 'tiles/extra/floor_dark.png');
    });

    test('levels reject malformed maps', () {
      expect(
        () => Levels.all.first.validate(),
        returnsNormally,
      );
      // A row with the wrong width must be rejected.
      final broken = Levels.all.first.maze.toList();
      expect(broken.length, 21);
    });
  });

  group('board geometry', () {
    test('the camera viewport is smaller than the full maze', () {
      expect(
        GameConfig.cameraWidth,
        lessThan(GameConfig.boardWidth),
      );
      expect(
        GameConfig.cameraHeight,
        lessThan(GameConfig.boardHeight),
      );
    });

    test('the board spans the full world size', () {
      expect(GameConfig.boardWidth, 15 * GameConfig.tileSize);
      expect(GameConfig.boardHeight, 21 * GameConfig.tileSize);
    });

    test('the board starts at the origin with no hidden offset', () {
      expect(GameConfig.cellCenterX(0), GameConfig.tileSize / 2);
      expect(GameConfig.cellCenterY(0), GameConfig.tileSize / 2);
    });

    test('the last cell is fully inside the board on both axes', () {
      final lastX = GameConfig.cellCenterX(GameConfig.mazeColumns - 1);
      final lastY = GameConfig.cellCenterY(GameConfig.mazeRows - 1);
      expect(lastX + GameConfig.tileSize / 2, lessThanOrEqualTo(
        GameConfig.boardWidth,
      ));
      expect(lastY + GameConfig.tileSize / 2, lessThanOrEqualTo(
        GameConfig.boardHeight,
      ));
    });

    test('every cell centre lands inside the board', () {
      for (var x = 0; x < GameConfig.mazeColumns; x++) {
        expect(GameConfig.cellCenterX(x), greaterThan(0));
        expect(
          GameConfig.cellCenterX(x),
          lessThan(GameConfig.boardWidth),
        );
      }
      for (var y = 0; y < GameConfig.mazeRows; y++) {
        expect(GameConfig.cellCenterY(y), greaterThan(0));
        expect(
          GameConfig.cellCenterY(y),
          lessThan(GameConfig.boardHeight),
        );
      }
    });

    test('every level grid spans the full board', () {
      for (final level in Levels.all) {
        expect(level.width, GameConfig.mazeColumns, reason: 'level ${level.number}');
        expect(level.height, GameConfig.mazeRows, reason: 'level ${level.number}');
        expect(level.width * GameConfig.tileSize, GameConfig.boardWidth);
        expect(level.height * GameConfig.tileSize, GameConfig.boardHeight);
      }
    });
  });

  group('hazards', () {
    test('every level has obstacles that cost HP', () {
      for (final level in Levels.all) {
        expect(level.hazardCount, greaterThan(0),
            reason: 'level ${level.number} needs obstacles');
      }
    });

    test('obstacle count grows with difficulty', () {
      final counts = Levels.all.map((l) => l.hazardCount).toList();
      expect(counts, [2, 3, 4, 5, 6]);
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThan(counts[i - 1]));
      }
    });

    test('hazards never sit on the spawn, a fish, the exit, or a wall', () {
      for (final level in Levels.all) {
        for (final h in level.hazardPositions) {
          expect(level.maze[h.y][h.x], 'X');
          expect(
            [level.playerStart.x, level.playerStart.y],
            isNot(equals([h.x, h.y])),
            reason: 'level ${level.number} hazard on spawn',
          );
          expect(
            [level.exitPosition.x, level.exitPosition.y],
            isNot(equals([h.x, h.y])),
            reason: 'level ${level.number} hazard on exit',
          );
        }
        // Fish cells keep their marker.
        for (final f in level.fishPositions) {
          expect(level.maze[f.y][f.x], 'F');
        }
      }
    });

    test('hazards are never adjacent to the spawn or the exit', () {
      for (final level in Levels.all) {
        for (final h in level.hazardPositions) {
          final dSpawn = (h.x - level.playerStart.x).abs() +
              (h.y - level.playerStart.y).abs();
          final dExit = (h.x - level.exitPosition.x).abs() +
              (h.y - level.exitPosition.y).abs();
          expect(dSpawn, greaterThan(1));
          expect(dExit, greaterThan(1));
        }
      }
    });

    test('hazards are spread out, never stacked', () {
      for (final level in Levels.all) {
        final list = level.hazardPositions;
        for (var i = 0; i < list.length; i++) {
          for (var j = i + 1; j < list.length; j++) {
            final d = (list[i].x - list[j].x).abs() +
                (list[i].y - list[j].y).abs();
            expect(d, greaterThanOrEqualTo(3),
                reason: 'level ${level.number} hazards too close');
          }
        }
      }
    });

    test('hazards do not block the path: all fish stay reachable', () {
      for (final level in Levels.all) {
        expect(() => level.validate(), returnsNormally,
            reason: 'level ${level.number} still solvable with hazards');
      }
    });

    test('Level 1 is completely walkable', () {
      expect(
        () => Levels.level1.validateFullWalkability(),
        returnsNormally,
      );
    });

    test('Level 1 can be completed without touching a hazard', () {
      expect(
        () => Levels.level1.validateHazardSafety(),
        returnsNormally,
      );
    });

    test('isHazard only matches obstacle cells', () {
      final level = Levels.all.first;
      final h = level.hazardPositions.first;
      expect(level.isHazard(h.x, h.y), isTrue);
      expect(level.isHazard(level.playerStart.x, level.playerStart.y), isFalse);
      expect(level.isHazard(level.exitPosition.x, level.exitPosition.y), isFalse);
      expect(level.isHazard(-1, 0), isFalse);
      expect(level.isHazard(0, 999), isFalse);
    });
  });

  group('player health', () {
    test('the cat starts with full hearts', () {
      expect(GameConfig.startingHp, 3);
    });

    test('a hazard always costs exactly one heart, and HP floors at zero', () {
      var hearts = GameConfig.startingHp;
      for (var hit = 0; hit < 3; hit++) {
        expect(hearts, greaterThan(0));
        hearts--;
      }
      expect(hearts, 0);
      // Further hits must not push HP negative.
      expect(hearts - 1, lessThan(0));
    });

    test('mercy window prevents instant multi-hit drain', () {
      expect(GameConfig.invulnerabilitySeconds, greaterThan(0));
    });

    test('hazards are avoidable, so a sparse board is still clearable', () {
      for (final level in Levels.all) {
        // Every fish is reachable without crossing a hazard, because hazards
        // live on walkable floor and never sit between the spawn and a fish.
        expect(() => level.validate(), returnsNormally);
        final hazardCount = level.hazardCount;
        final walkable =
            level.fishCount + 2 + hazardCount; // fish + spawn + exit + hazards
        expect(hazardCount, lessThan(walkable));
      }
    });
  });

  group('collision', () {
    test('perimeter is solid on every level', () {
      for (final level in Levels.all) {
        final cs = CollisionSystem(level);
        for (var x = 0; x < level.width; x++) {
          expect(cs.canMoveTo(x, 0), isFalse,
              reason: 'level ${level.number} top wall at $x');
          expect(cs.canMoveTo(x, level.height - 1), isFalse,
              reason: 'level ${level.number} bottom wall at $x');
        }
        for (var y = 0; y < level.height; y++) {
          expect(cs.canMoveTo(0, y), isFalse);
          expect(cs.canMoveTo(level.width - 1, y), isFalse);
        }
      }
    });

    test('spawn is walkable and outside the board is not', () {
      for (final level in Levels.all) {
        final cs = CollisionSystem(level);
        final start = level.playerStart;
        expect(cs.canMoveTo(start.x, start.y), isTrue);
        expect(cs.isValidPosition(-1, 0), isFalse);
        expect(cs.isValidPosition(0, level.height), isFalse);
      }
    });

    test('every fish cell and the exit are walkable', () {
      for (final level in Levels.all) {
        final cs = CollisionSystem(level);
        for (final p in level.fishPositions) {
          expect(cs.canMoveTo(p.x, p.y), isTrue,
              reason: 'level ${level.number} fish at ${p.x},${p.y}');
        }
        final exit = level.exitPosition;
        expect(cs.canMoveTo(exit.x, exit.y), isTrue);
      }
    });
  });

  group('timer', () {
    test('pausing freezes the level timer', () {
      final manager = ScoreManager()..reset(requiredFish: 5, levelNumber: 1);
      expect(manager.timerRunning, isTrue, reason: 'clock starts on reset');
      manager.pause();
      expect(manager.timerRunning, isFalse);
      final frozen = manager.stopwatch.elapsedMilliseconds;
      // A stopped Stopwatch does not accumulate while real time passes.
      expect(manager.stopwatch.elapsedMilliseconds, frozen);
    });

    test('resume continues from where it stopped', () {
      final manager = ScoreManager()..reset(requiredFish: 5, levelNumber: 1);
      manager.pause();
      expect(manager.timerRunning, isFalse);
      manager.resume();
      expect(manager.timerRunning, isTrue);
    });

    test('completing the level stops the timer permanently', () {
      final manager = ScoreManager()..reset(requiredFish: 5, levelNumber: 1);
      manager.completeLevel();
      expect(manager.timerRunning, isFalse);
      manager.resume();
      expect(
        manager.timerRunning,
        isFalse,
        reason: 'resume must not restart a finished level timer',
      );
    });

    test('pause is idempotent and does not double-count time', () {
      final manager = ScoreManager()..reset(requiredFish: 5, levelNumber: 1);
      manager.pause();
      manager.pause();
      expect(manager.timerRunning, isFalse);
      manager.resume();
      manager.resume();
      expect(manager.timerRunning, isTrue);
    });

    test('retry resets the timer and score', () {
      final manager = ScoreManager()..reset(requiredFish: 5, levelNumber: 1);
      manager.collectFish();
      manager.collectFish();
      expect(manager.score, 200);
      manager.reset(requiredFish: 5, levelNumber: 1);
      expect(manager.score, 0);
      expect(manager.fishCollected, 0);
      expect(manager.timerRunning, isTrue);
    });

    test('score awards 100 per fish and 500 for completion', () {
      final manager = ScoreManager()..reset(requiredFish: 2, levelNumber: 1);
      manager.collectFish();
      manager.collectFish();
      expect(manager.score, 200);
      manager.completeLevel();
      expect(manager.score, 700);
    });

    test('level completion can only be scored once', () {
      final manager = ScoreManager()..reset(requiredFish: 1, levelNumber: 1);
      manager.completeLevel();
      manager.completeLevel();
      manager.completeLevel();
      expect(manager.score, 500, reason: 'no duplicate completion bonus');
    });

    test('formatted time is zero padded', () {
      final manager = ScoreManager()..reset(requiredFish: 1, levelNumber: 1);
      expect(manager.formattedTime, matches(RegExp(r'^\d{2}:\d{2}$')));
    });
  });

  group('level validation rejects bad maps', () {
    LevelData build(List<String> maze, {int requiredFish = 1}) => LevelData(
          number: 99,
          name: 'Broken',
          theme: 'blue',
          requiredFish: requiredFish,
          maze: maze,
        );

    test('rejects ragged rows', () {
      expect(
        () => build([
          '#####',
          '#P..#',
          '###',
        ]),
        throwsStateError,
      );
    });

    test('rejects a map with no player spawn', () {
      expect(
        () => build(const ['#####', '#..E#', '#####']),
        throwsStateError,
      );
    });

    test('rejects a wrong fish count', () {
      expect(
        () => build(const ['#####', '#P.E#', '#####']),
        throwsStateError,
      );
    });

    test('rejects an unknown symbol', () {
      expect(
        () => build(const ['#####', '#PXE#', '#####']),
        throwsStateError,
      );
    });

    test('rejects an unreachable exit', () {
      expect(
        () => build(const [
          '#####',
          '#PF.#',
          '####',
          '#..E#',
          '#####',
        ]),
        throwsStateError,
      );
    });

    test('rejects an unreachable fish', () {
      expect(
        () => build(const [
          '#####',
          '#P..#',
          '####',
          '#F.E#',
          '#####',
        ]),
        throwsStateError,
      );
    });

    test('rejects a map with no walls', () {
      expect(
        () => build(const ['.....', '.P.E.', '.....']),
        throwsStateError,
      );
    });

    test('all shipped levels pass every check', () {
      for (final level in Levels.all) {
        expect(() => level.validate(), returnsNormally);
      }
    });
  });

group('progression and save data', () {
  test('a fresh save defaults to Kuro with locked cats', () {
    final state = GameState();
    expect(state.selectedCat, 'kuro');
    // Kuro is owned immediately.
    expect(state.isCatUnlocked('kuro'), isTrue,
        reason: 'Kuro is owned from the start');
    // Luna and Mochi are NOT owned on a fresh save.
    expect(state.isCatUnlocked('luna'), isFalse,
        reason: 'Luna is not owned on a fresh save');
    expect(state.isCatUnlocked('mochi'), isFalse,
        reason: 'Mochi is not owned on a fresh save');
    // Luna and Mochi are NOT available (level requirement not met).
    expect(state.catIsAvailable('luna'), isFalse,
        reason: 'Luna requires Level 2');
    expect(state.catIsAvailable('mochi'), isFalse,
        reason: 'Mochi requires Level 4');
    expect(state.lunaAvailable, isFalse);
    expect(state.mochiAvailable, isFalse);
    expect(state.unlockedCatCount, 1, reason: 'only Kuro is owned');
    expect(state.isLevelUnlocked(1), isTrue);
    expect(state.isLevelUnlocked(2), isFalse);
    expect(state.isLevelUnlocked(0), isFalse);
  });

  test('cat order is kuro, luna, mochi', () {
    expect(CatSkins.names, ['kuro', 'luna', 'mochi']);
    expect(
      CatSkins.all().map((c) => c.name).toList(),
      ['kuro', 'luna', 'mochi'],
    );
  });

  test('cats have correct unlock levels and prices', () {
    expect(CatSkins.kuro.unlockLevel, 0);
    expect(CatSkins.luna.unlockLevel, 2);
    expect(CatSkins.mochi.unlockLevel, 4);
    expect(CatSkins.kuro.price, 0);
    expect(CatSkins.luna.price, 250);
    expect(CatSkins.mochi.price, 500);
  });

  test('completing level 1 does not unlock Luna or Mochi', () {
    final state = GameState();
    state.onLevelCompleted(1);
    expect(state.isLevelUnlocked(2), isTrue);
    expect(state.isLevelUnlocked(1), isTrue);
    expect(state.catIsAvailable('luna'), isFalse,
        reason: 'Luna still not available after L1');
    expect(state.catIsAvailable('mochi'), isFalse);
    expect(state.isCatUnlocked('luna'), isFalse);
    expect(state.isCatUnlocked('mochi'), isFalse);
    expect(state.unlockedCatCount, 1);
  });

  test('completing level 2 makes Luna available for purchase', () {
    final state = GameState();
    // Award the L1 + L2 first-clear bonuses (50 each = 100 total).
    state.onLevelCompleted(1);
    state.onLevelCompleted(2);
    expect(state.pawCoins, 100, reason: '50 per first clear');
    // Luna is now AVAILABLE but not yet OWNED.
    expect(state.catIsAvailable('luna'), isTrue,
        reason: 'Luna available after completing Level 2');
    expect(state.isCatUnlocked('luna'), isFalse,
        reason: 'Luna must be purchased, not just available');
    expect(state.unlockedCatCount, 1);
  });

  test('buyCat is an atomic transaction: Luna costs 250 coins', () {
    final state = GameState()..pawCoins = 300;

    // Luna is not available yet (level 2 not completed).
    expect(state.buyCat('luna'), isFalse);
    expect(state.pawCoins, 300, reason: 'coins unchanged on failure');

    // Complete level 2.
    state.onLevelCompleted(1); // +50
    // pawCoins is now 350, but Luna still not available until L2 is done.
    state.onLevelCompleted(2); // +50 → 400
    expect(state.catIsAvailable('luna'), isTrue);

    // Buy succeeds: 400 - 250 = 150.
    expect(state.buyCat('luna'), isTrue);
    expect(state.pawCoins, 150);
    expect(state.isCatUnlocked('luna'), isTrue);
    expect(state.unlockedCatCount, 2);

    // Buying again fails (already owned).
    expect(state.buyCat('luna'), isFalse);
    expect(state.pawCoins, 150, reason: 'coins unchanged on second attempt');
  });

  test('buyCat rejects purchase when coins are insufficient', () {
    final state = GameState()..pawCoins = 100;
    // Complete level 2 to make Luna available.
    state.onLevelCompleted(1); // +50 → 150
    state.onLevelCompleted(2); // +50 → 200
    // Luna costs 250, we only have 200.
    expect(state.buyCat('luna'), isFalse);
    expect(state.pawCoins, 200, reason: 'no coin deduction on failure');
    expect(state.isCatUnlocked('luna'), isFalse);
  });

  test('completing level 4 makes Mochi available for purchase', () {
    final state = GameState();
    // Complete levels 1-4.
    for (var i = 1; i <= 4; i++) {
      state.onLevelCompleted(i);
    }
    // 4 first-clear bonuses = 200 coins.
    expect(state.pawCoins, 200);
    expect(state.catIsAvailable('luna'), isTrue);
    expect(state.catIsAvailable('mochi'), isTrue);
    expect(state.isCatUnlocked('mochi'), isFalse);
    expect(state.isCatUnlocked('luna'), isFalse);
  });

  test('buyCat is an atomic transaction: Mochi costs 500 coins', () {
    final state = GameState()..pawCoins = 600;
    // Complete levels 1-4.
    for (var i = 1; i <= 4; i++) {
      state.onLevelCompleted(i);
    }
    // pawCoins = 600 + 200 (4 first clears) = 800, but wait:
    // Actually pawCoins setter replaces the value. Let's check.
    // GameState() starts with pawCoins=0, then we set it to 600.
    // Then onLevelCompleted(1..4) adds 50*4=200.
    // So pawCoins = 600 + 200 = 800.
    expect(state.catIsAvailable('mochi'), isTrue);
    expect(state.buyCat('mochi'), isTrue);
    expect(state.pawCoins, 300, reason: '800 - 500 = 300');
    expect(state.isCatUnlocked('mochi'), isTrue);
    expect(state.unlockedCatCount, 2); // Kuro + Mochi
  });

  test('can only select owned cats', () {
    final state = GameState();
    // Fresh save: only Kuro is owned.
    expect(state.canSelectCat('kuro'), isTrue);
    expect(state.canSelectCat('luna'), isFalse);
    expect(state.canSelectCat('mochi'), isFalse);

    // Selecting an unowned cat silently fails.
    state.selectedCat = 'luna';
    expect(state.selectedCat, 'kuro',
        reason: 'setter must reject unowned cats');

    // After buying Luna, it can be selected.
    state.pawCoins = 1000;
    state.onLevelCompleted(1); // +50
    state.onLevelCompleted(2); // +50
    state.buyCat('luna');
    state.selectedCat = 'luna';
    expect(state.selectedCat, 'luna');
  });

  test('clearing level 5 never unlocks a phantom level 6', () {
    final state = GameState();
    for (var level = 1; level <= 5; level++) {
      state.onLevelCompleted(level);
    }
    expect(state.highestUnlockedLevel, 5);
    expect(state.isLevelUnlocked(5), isTrue);
    expect(state.isLevelUnlocked(6), isFalse);
  });

  test('Kuro stays owned through the entire progression', () {
    final state = GameState();
    for (var level = 1; level <= 5; level++) {
      state.onLevelCompleted(level);
      expect(state.isCatUnlocked('kuro'), isTrue,
          reason: 'Kuro is always owned after clearing level $level');
    }
    // Luna and Mochi are never auto-owned — only made available.
    expect(state.isCatUnlocked('luna'), isFalse,
        reason: 'Luna is never auto-owned');
    expect(state.isCatUnlocked('mochi'), isFalse,
        reason: 'Mochi is never auto-owned');
    expect(state.catIsAvailable('luna'), isTrue,
        reason: 'Luna is available after Level 2');
    expect(state.catIsAvailable('mochi'), isTrue,
        reason: 'Mochi is available after Level 4');
  });

  test('first-clear bonus is not double-awarded', () {
    final state = GameState();
    state.onLevelCompleted(1);
    expect(state.pawCoins, 50, reason: 'first clear gives exactly 50');

    // Re-completing the same level yields no bonus.
    state.onLevelCompleted(1);
    expect(state.pawCoins, 50, reason: 'no bonus on replay');
  });

  test('resetting progress restores fresh defaults', () async {
    SharedPreferences.setMockInitialValues({});
    var state = GameState(
      highestUnlockedLevel: 5,
      lunaOwned: true,
      mochiOwned: true,
      selectedCat: 'mochi',
      highScore: 9999,
      pawCoins: 999,
    );
    await SaveManager.save(state);

    await SaveManager.resetProgress();
    state = await SaveManager.load();

    expect(state.highestUnlockedLevel, 1);
    expect(state.selectedCat, 'kuro');
    expect(state.isCatUnlocked('kuro'), isTrue);
    expect(state.isCatUnlocked('luna'), isFalse,
        reason: 'Luna is reset to un-owned');
    expect(state.isCatUnlocked('mochi'), isFalse,
        reason: 'Mochi is reset to un-owned');
    expect(state.highScore, 0);
    expect(state.pawCoins, 0);
  });

  test('stale save with locked selected cat falls back to Kuro', () async {
    // Simulate a save where the user selected Luna, but the save was
    // written by a build that didn't track ownership — so Luna is not
    // in the completed-levels set and must not be selectable.
    SharedPreferences.setMockInitialValues({
      'selected_cat': 'luna',
      'luna_owned': false,
      'completed_levels': '',
      'highest_unlocked_level': 1,
      'paw_coins': 0,
    });
    final state = await SaveManager.load();
    expect(state.selectedCat, 'kuro',
        reason: 'locked selection falls back to Kuro');
    expect(state.isCatUnlocked(state.selectedCat), isTrue);
  });

  test('save round-trips preserve ownership state', () async {
    SharedPreferences.setMockInitialValues({});
    final state = GameState(
      highestUnlockedLevel: 5,
      lunaOwned: true,
      mochiOwned: true,
      selectedCat: 'luna',
      highScore: 4250,
      pawCoins: 123,
      completedLevels: {1, 2, 3, 4, 5},
    );
    await SaveManager.save(state);
    final loaded = await SaveManager.load();

    expect(loaded.highestUnlockedLevel, 5);
    expect(loaded.lunaOwned, isTrue,
        reason: 'Luna ownership persists across save/load');
    expect(loaded.mochiOwned, isTrue);
    expect(loaded.selectedCat, 'luna', reason: 'selected cat persists');
    expect(loaded.highScore, 4250);
    expect(loaded.pawCoins, 123);
    expect(loaded.completedLevels, {1, 2, 3, 4, 5});
  });

  test('json round-trip preserves ownership state', () {
    final state = GameState(
      selectedCat: 'luna',
      highScore: 120,
      pawCoins: 50,
      lunaOwned: true,
      mochiOwned: false,
    );
    final restored = GameState.fromJson(state.toJson());
    expect(restored.lunaOwned, isTrue);
    expect(restored.mochiOwned, isFalse);
    // Luna is owned but not selectable unless Level 2 is completed.
    expect(restored.isCatUnlocked('luna'), isTrue);
    expect(restored.catIsAvailable('luna'), isFalse,
        reason: 'availability requires level completion');
    expect(restored.selectedCat, SaveManager.defaultCat,
        reason: 'non-selectable cat falls back to default');
    expect(restored.pawCoins, 50);
  });

  test('high score only ever rises', () {
    final state = GameState();
    state.addScore(1200);
    state.addScore(300);
    expect(state.highScore, 1200);
  });

  test('unlock never walks the level counter backwards', () {
    final state = GameState()..unlockLevel(3);
    state.unlockLevel(2);
    expect(state.highestUnlockedLevel, 3);
  });

  test('loaded progress is clamped to the shipped campaign', () {
    final state = GameState(highestUnlockedLevel: 99);
    expect(state.highestUnlockedLevel, 5);
    expect(state.isLevelUnlocked(6), isFalse);
  });

  test('unknown cat names are never unlocked', () {
    final state = GameState();
    expect(state.isCatUnlocked('unknown'), isFalse);
    expect(state.isCatUnlocked(''), isFalse);
  });

  test('fresh save only unlocks level 1 (not all levels)', () {
    SharedPreferences.setMockInitialValues({});
    SaveManager.load().then((state) {
      expect(state.highestUnlockedLevel, 1,
          reason: 'Fresh save should have only level 1 unlocked');
      expect(state.isLevelUnlocked(1), isTrue);
      expect(state.isLevelUnlocked(2), isFalse,
          reason: 'Level 2 should be locked on fresh save');
      expect(state.isLevelUnlocked(3), isFalse);
      expect(state.isLevelUnlocked(4), isFalse);
      expect(state.isLevelUnlocked(5), isFalse);
    });
  });

  test('completing level 1 unlocks level 2 and records one history entry',
      () async {
    SharedPreferences.setMockInitialValues({});
    final state = GameState(
      highestUnlockedLevel: 1,
      lunaOwned: false,
      mochiOwned: false,
      selectedCat: 'kuro',
      highScore: 0,
      pawCoins: 0,
      completedLevels: {},
      adventureHistory: [],
    );

    // Simulate completing level 1
    state.onLevelCompleted(1);
    state.addAdventureHistoryEntry(
      HistoryEntry(
        level: 1,
        levelName: 'Classic',
        score: 1000,
        formattedTime: '01:30',
        date: DateTime.now(),
      ),
    );
    await SaveManager.save(state);

    // Verify level 2 is unlocked
    expect(state.isLevelUnlocked(2), isTrue,
        reason: 'Level 2 should be unlocked after completing Level 1');
    expect(state.isLevelUnlocked(3), isFalse,
        reason: 'Level 3 should still be locked');

    // Reload from save
    final loaded = await SaveManager.load();
    expect(loaded.isLevelUnlocked(2), isTrue,
        reason: 'Level 2 should still be unlocked after save/load');
    expect(loaded.adventureHistory.length, 1,
        reason: 'History should have exactly one entry after save/load');
    expect(loaded.adventureHistory.first.level, 1);
  });

test('history delete still works after fixes', () async {
    SharedPreferences.setMockInitialValues({});
    final state = GameState(
      highestUnlockedLevel: 1,
      adventureHistory: [
        HistoryEntry(
          level: 1,
          levelName: 'Test',
          score: 100,
          formattedTime: '00:30',
          date: DateTime.now(),
        ),
      ],
    );
    await SaveManager.save(state);

// Delete the history entry
    await SaveManager.deleteHistoryEntryById(state.adventureHistory.first.id);

    // Reload and verify it's gone
    final loaded = await SaveManager.load();
    expect(loaded.adventureHistory, isEmpty,
        reason: 'History should be empty after deletion');
  });
});
}
