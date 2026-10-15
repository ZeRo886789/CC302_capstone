import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/game_config.dart';

/// Soft circular visibility around the cat. The light is centred on the
/// player's world position, so the bright area is a true circle that
/// follows the cat; the far side of the maze is dimmed but never pitch
/// black, keeping the mood relaxing rather than horror-like.
class PlayerLight extends PositionComponent {
  PlayerLight({required this.getPlayerPosition, required this.radiusTiles})
    : super(
        position: Vector2.zero(),
        size: Vector2(GameConfig.boardWidth, GameConfig.boardHeight),
      );

  final Vector2 Function() getPlayerPosition;

  /// Visibility radius in tiles, supplied by the level data.
  final double radiusTiles;

  double get radius => radiusTiles * GameConfig.tileSize;

  /// The gradient radius is expressed as a fraction of the shortest
  /// side of the paint box, which keeps the light perfectly circular
  /// on the 360x504 world instead of stretching it into an ellipse.
  double get _radiusFraction =>
      radius / math.min(GameConfig.boardWidth, GameConfig.boardHeight);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final player = getPlayerPosition();

    final rect = Rect.fromLTWH(
      0,
      0,
      GameConfig.boardWidth,
      GameConfig.boardHeight,
    );

    final shader = RadialGradient(
      center: Alignment(
        (player.x / GameConfig.boardWidth) * 2 - 1,
        (player.y / GameConfig.boardHeight) * 2 - 1,
      ),
      radius: _radiusFraction,
      colors: const [
        Color(0x00000000),
        Color(0x1A000000),
        Color(0x47000000),
        Color(0x73000000),
      ],
      stops: const [0.0, 0.45, 0.75, 1.0],
    ).createShader(rect);

    final paint = Paint()..shader = shader;

    canvas.drawRect(rect, paint);
  }
}
