import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/game_config.dart';

/// A hazard cell. Stepping on it costs the cat one heart, so it pulses to make
/// it readable as dangerous.
class Hazard extends SpriteComponent {
  Hazard({
    required Sprite sprite,
    required this.gridX,
    required this.gridY,
  }) : super(
          sprite: sprite,
          position: Vector2(
            GameConfig.cellCenterX(gridX),
            GameConfig.cellCenterY(gridY),
          ),
          size: Vector2.all(GameConfig.hazardVisualSize),
          anchor: Anchor.center,
        ) {
    paint.filterQuality = FilterQuality.none;
    _phase = Random(gridX * 31 + gridY * 17).nextDouble() * pi * 2;
  }

  final int gridX;
  final int gridY;
  double _phase = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 4;
    // Gentle pulse so hazards stand out from plain floor.
    final scale = 1 + sin(_phase) * 0.06;
    size = Vector2.all(GameConfig.hazardVisualSize * scale);
  }
}
