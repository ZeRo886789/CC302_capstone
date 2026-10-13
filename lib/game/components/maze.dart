import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../config/paw_assets.dart';
import '../data/level_data.dart';
import 'maze_tile.dart';

/// Draws the maze for one level: one [MazeTile] sprite per wall cell, plus the
/// walkable path dots. The maze occupies the complete world.
/// The camera shows only a moving portion of this world.
class Maze extends PositionComponent {
  Maze({required this.levelData});

  final LevelData levelData;
  final List<MazeTile> tiles = [];

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = Vector2.zero();
    size = Vector2(GameConfig.boardWidth, GameConfig.boardHeight);
    await _buildWalls();
  }

  Future<void> _buildWalls() async {
    final theme = levelData.theme;
    final variantSprites = <Sprite>[];
    for (var i = 0; i < 8; i++) {
      variantSprites.add(await Sprite.load(PawAssets.wallVariant(theme, i)));
    }

    for (var y = 0; y < levelData.height; y++) {
      for (var x = 0; x < levelData.width; x++) {
        if (levelData.maze[y][x] != '#') continue;
        // Vary the sprite per cell so long walls do not look tiled.
        final variant = (x * 3 + y * 5) % 8;
        tiles.add(
          MazeTile(
            sprite: variantSprites[variant],
            position: Vector2(x * GameConfig.tileSize, y * GameConfig.tileSize),
            size: Vector2.all(GameConfig.tileSize),
          ),
        );
      }
    }

    await addAll(tiles);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderPathDots(canvas);
  }

  /// Faint dots on walkable cells that hold no fish, so the route reads clearly.
  void _renderPathDots(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF15152B);
    final radius = GameConfig.tileSize * 0.10;
    final occupied = <String>{
      for (final p in levelData.fishPositions) '${p.x},${p.y}',
      '${levelData.playerStart.x},${levelData.playerStart.y}',
      '${levelData.exitPosition.x},${levelData.exitPosition.y}',
    };

    for (var y = 0; y < levelData.height; y++) {
      for (var x = 0; x < levelData.width; x++) {
        if (levelData.maze[y][x] == '#') continue;
        if (occupied.contains('$x,$y')) continue;
        canvas.drawCircle(
          Offset(
            x * GameConfig.tileSize + GameConfig.tileSize / 2,
            y * GameConfig.tileSize + GameConfig.tileSize / 2,
          ),
          radius,
          paint,
        );
      }
    }
  }
}
