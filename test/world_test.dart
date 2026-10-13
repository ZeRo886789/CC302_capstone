import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/game/components/finish.dart';
import 'package:pawquest/game/components/fish.dart';
import 'package:pawquest/game/components/hazard.dart';
import 'package:pawquest/game/components/maze.dart';
import 'package:pawquest/game/components/player.dart';
import 'package:pawquest/game/config/game_config.dart';
import 'package:pawquest/game/data/levels.dart';
import 'package:pawquest/game/pawquest_game.dart';
import 'package:pawquest/game/systems/save_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_image_cache.dart';

/// Mounts the real game inside a GameWidget and drives the update loop, so the
/// whole world (maze, cat, fish, hazards, flag) is really constructed.
Future<PawQuestGame> mountGame(
  WidgetTester tester, {
  int level = 1,
  String cat = 'kuro',
}) async {
  SharedPreferences.setMockInitialValues({});
  final game = PawQuestGame(
    selectedCat: cat,
    initialLevel: level,
    savedState: GameState(),
    onGameComplete: () {},
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: GameWidget<PawQuestGame>(
            game: game,
            overlayBuilderMap: {
              for (final name in [
                'pause',
                'levelComplete',
                'gameOver',
                'gameComplete',
              ])
                name: (context, game) => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    ),
  );

  await tester.pump();

  // Sprite decoding is real async I/O, so it only progresses inside runAsync.
  // Wait for the level to be fully constructed.
  await tester.runAsync(() async {
    for (var i = 0; i < 200; i++) {
      if (game.player != null &&
          game.maze != null &&
          game.maze!.tiles.isNotEmpty &&
          game.finishFlag != null &&
          game.fishList.length == Levels.all[level - 1].requiredFish) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });

  // Let the deferred removals and pending frames settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return game;
}

/// Pumps until [done] holds, allowing real async work to progress.
Future<void> settle(
  WidgetTester tester,
  bool Function() done, {
  int maxPumps = 200,
}) async {
  await tester.runAsync(() async {
    for (var i = 0; i < maxPumps; i++) {
      if (done()) return;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(preseedTestSprites);

  group('game world mounts', () {
    testWidgets('level 1 builds maze, cat, fish, hazards and flag',
        (tester) async {
      final game = await mountGame(tester);
      final data = Levels.all.first;

      final maze = game.world.children.whereType<Maze>().single;
      final player = game.world.children.whereType<Player>().single;
      final fish = game.world.children.whereType<Fish>();
      final hazards = game.world.children.whereType<Hazard>();
      final flag = game.world.children.whereType<FinishFlag>().single;

      var wallCells = 0;
      for (final row in data.maze) {
        wallCells += '#'.allMatches(row).length;
      }

      expect(maze.tiles.length, wallCells,
          reason: 'one wall sprite per wall cell');
      expect(fish.length, data.requiredFish);
      expect(hazards.length, data.hazardCount);
      // FinishFlag now uses child SpriteComponents instead of direct sprite.
      // Verify the flag has its base sprite component.
      final flagBaseSprite = flag.children.whereType<SpriteComponent>().firstOrNull;
      expect(flagBaseSprite, isNotNull);
      expect(player.animations?.length, 5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every level mounts with the right entity counts',
        (tester) async {
      for (var level = 1; level <= Levels.all.length; level++) {
        final game = await mountGame(tester, level: level);
        final data = Levels.all[level - 1];
        expect(game.world.children.whereType<Maze>(), hasLength(1),
            reason: 'level $level maze');
        expect(game.world.children.whereType<Player>(), hasLength(1),
            reason: 'level $level player');
        expect(game.world.children.whereType<Fish>().length,
            data.requiredFish,
            reason: 'level $level fish');
        expect(game.world.children.whereType<Hazard>().length,
            data.hazardCount,
            reason: 'level $level hazards');
        expect(game.world.children.whereType<FinishFlag>(), hasLength(1),
            reason: 'level $level flag');
        expect(tester.takeException(), isNull, reason: 'level $level');
      }
    });

    testWidgets('no duplicate entities after restarting a level',
        (tester) async {
      final game = await mountGame(tester);
      final data = Levels.all.first;

      for (var attempt = 0; attempt < 4; attempt++) {
        game.restartLevel();
        await settle(
          tester,
          () => game.player != null &&
              game.maze != null &&
              game.fishList.length == data.requiredFish,
        );

        expect(game.world.children.whereType<Maze>(), hasLength(1),
            reason: 'attempt $attempt maze');
        expect(game.world.children.whereType<Player>(), hasLength(1),
            reason: 'attempt $attempt player');
        expect(game.world.children.whereType<FinishFlag>(), hasLength(1),
            reason: 'attempt $attempt flag');
        expect(game.world.children.whereType<Fish>().length,
            data.requiredFish,
            reason: 'attempt $attempt fish must not stack');
        expect(game.world.children.whereType<Hazard>().length,
            data.hazardCount,
            reason: 'attempt $attempt hazards must not stack');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('restart restores full hearts and clears game over',
        (tester) async {
      final game = await mountGame(tester);
      expect(game.hp.value, GameConfig.startingHp);
      expect(game.isGameOver, isFalse);

      // Simulate a fatal blow.
      game.debugForceGameOver();
      await tester.pump();
      expect(game.isGameOver, isTrue);
      expect(game.hp.value, 0);

      game.restartLevel();
      await settle(
        tester,
        () => game.player != null && game.hp.value == GameConfig.startingHp,
      );

      expect(game.isGameOver, isFalse);
      expect(game.hp.value, GameConfig.startingHp);
      expect(game.overlays.isActive('gameOver'), isFalse);
      expect(game.player!.gridX, Levels.all.first.playerStart.x);
      expect(game.player!.gridY, Levels.all.first.playerStart.y);
      expect(tester.takeException(), isNull);
    });

    testWidgets('walking into a hazard costs a heart and can end the run',
        (tester) async {
      final game = await mountGame(tester);
      final data = Levels.all.first;
      final hazard = data.hazardPositions.first;

      // Place the cat directly on the hazard cell.
      game.debugPlacePlayerOn(hazard.x, hazard.y);
      await tester.pump();

      expect(game.hp.value, GameConfig.startingHp - 1);
      expect(game.isGameOver, isFalse);

      // Clear the mercy window, then hit it twice more.
      for (var hit = 0; hit < 2; hit++) {
        game.debugClearInvulnerability();
        game.debugPlacePlayerOn(hazard.x, hazard.y);
        await tester.pump();
      }

      expect(game.hp.value, 0);
      expect(game.isGameOver, isTrue);
      expect(game.overlays.isActive('gameOver'), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('movement stays inside the visible board', (tester) async {
      final game = await mountGame(tester);
      final player = game.player!;

      for (var step = 0; step < 60; step++) {
        game.movePlayer(PlayerDirection.down);
        await tester.pump(const Duration(milliseconds: 200));
        expect(player.position.x, greaterThan(0));
        expect(player.position.y, greaterThan(0));
        expect(
          player.position.x,
          lessThanOrEqualTo(GameConfig.boardWidth),
        );
        expect(
          player.position.y,
          lessThanOrEqualTo(GameConfig.boardHeight),
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('camera follows the player when moving', (tester) async {
      final game = await mountGame(tester);
      final player = game.player!;

      // Initial camera position should be snapped to player (clamped to world bounds).
      // Level 1 spawn is at grid (1,1) -> world (36, 36).
      // Camera clamps to [halfWidth=120, boardWidth-halfWidth=240] x [halfHeight=160, boardHeight-halfHeight=344].
      // So initial camera position should be (120, 160).
      expect(game.camera.viewfinder.position.x, closeTo(120, 1));
      expect(game.camera.viewfinder.position.y, closeTo(160, 1));

      // Check initial player position
      expect(player.gridX, 1);
      expect(player.gridY, 1);
      expect(player.position.x, closeTo(36, 1));
      expect(player.position.y, closeTo(36, 1));

      // From spawn (1,1), the only open direction is RIGHT (maze[1][2] == '.').
      // Move player right 5 cells (each cell = 24px, moveDuration = 0.15s).
      // After 5 moves, player should be at gridX = 6 -> worldX = 6*24 + 12 = 156.
      for (var i = 0; i < 5; i++) {
        game.movePlayer(PlayerDirection.right);
        await tester.pump(const Duration(milliseconds: 200));
      }

      // After 5 moves, player at gridX=6, worldX=156
      expect(player.gridX, 6);
      expect(player.position.x, closeTo(156, 1));

      // Target camera X = clamp(156, 120, 240) = 156 (within bounds, not clamped).
      // Camera should have started following.
      // ignore: avoid_print
      print('Camera X after 5 moves right: ${game.camera.viewfinder.position.x}');
      expect(game.camera.viewfinder.position.x, greaterThan(125));
      expect(game.camera.viewfinder.position.x, lessThanOrEqualTo(156));

      // Move player right one more cell to gridX=7 -> worldX=180.
      game.movePlayer(PlayerDirection.right);
      await tester.pump(const Duration(milliseconds: 200));

      // Player at gridX=7, worldX=180
      expect(player.gridX, 7);
      expect(player.position.x, closeTo(180, 1));

      // Camera should be following closely.
      // ignore: avoid_print
      print('Camera X after 6 moves right: ${game.camera.viewfinder.position.x}');
      expect(game.camera.viewfinder.position.x, greaterThan(165));
      expect(game.camera.viewfinder.position.x, lessThanOrEqualTo(180));

      // Move further right - camera should keep following.
      for (var i = 0; i < 5; i++) {
        game.movePlayer(PlayerDirection.right);
        await tester.pump(const Duration(milliseconds: 200));
      }
      // Player at gridX=12 -> worldX = 12*24+12 = 300.
      // Target camera X = clamp(300, 120, 240) = 240 (clamped at right edge).
      expect(player.gridX, 12);
      // ignore: avoid_print
      print('Camera X after 11 moves right: ${game.camera.viewfinder.position.x}');
      expect(game.camera.viewfinder.position.x, closeTo(240, 10));

      // Camera Y should remain clamped at 160 (player hasn't moved vertically).
      expect(game.camera.viewfinder.position.y, closeTo(160, 1));

      expect(tester.takeException(), isNull);
    });

    testWidgets('walls block the cat and the flag starts locked',
        (tester) async {
      final game = await mountGame(tester);
      final data = Levels.all.first;
      final player = game.player!;

      // Row 0 is a solid wall, so up must be refused.
      game.movePlayer(PlayerDirection.up);
      await tester.pump(const Duration(milliseconds: 200));
      expect(player.gridY, data.playerStart.y);

      expect(game.finishFlag!.active, isFalse,
          reason: 'flag locked until all fish collected');
      expect(tester.takeException(), isNull);
    });

    testWidgets('finish flag is positioned at the exit grid location',
        (tester) async {
      for (var level = 1; level <= Levels.all.length; level++) {
        final game = await mountGame(tester, level: level);
        final data = Levels.all[level - 1];

        final exit = data.exitPosition;
        final expectedX = GameConfig.cellCenterX(exit.x);
        final expectedY = GameConfig.cellCenterY(exit.y);

        // The finish flag should be at the exit cell center
        expect(game.finishFlag!.position.x, closeTo(expectedX, 0.1),
            reason: 'level $level: finish flag X at exit cell center');
        expect(game.finishFlag!.position.y, closeTo(expectedY, 0.1),
            reason: 'level $level: finish flag Y at exit cell center');
      }
    });

    testWidgets(
        'player reaching the finish with all fish collected completes the level',
        (tester) async {
      final game = await mountGame(tester, level: 1);
      final data = Levels.all.first;

      // Teleport the player to the exit cell and collect all fish
      game.debugPlacePlayerOn(data.exitPosition.x, data.exitPosition.y);
      await tester.pump();

      // Collect all fish first
      for (int i = 0; i < data.fishCount; i++) {
        game.scoreManager.collectFish();
      }
      await tester.pump();

      // Now the player is on the exit with all fish collected
      // The level should complete
      expect(game.levelCompleting, isTrue,
          reason: 'level completes when player reaches finish with all fish');
    });
  });
}
