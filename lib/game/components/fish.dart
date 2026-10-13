import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../config/paw_assets.dart';

/// A collectible fish drawn from the supplied fish sprites, with a gentle bob
/// and a looping animation across every supplied frame.
class Fish extends SpriteAnimationComponent {
  Fish._({
    required SpriteAnimation animation,
    required this.gridX,
    required this.gridY,
    required double visualSize,
  }) : super(
          animation: animation,
          position: Vector2(
            GameConfig.cellCenterX(gridX),
            GameConfig.cellCenterY(gridY),
          ),
          size: Vector2.all(visualSize),
          anchor: Anchor.center,
        ) {
    paint.filterQuality = FilterQuality.none;
  }

  final int gridX;
  final int gridY;
  bool collected = false;
  double _bobOffset = 0;

  /// Builds the shared animation once and hands a clone to each fish so all
  /// fish animate in sync without re-loading sprites per instance.
  static Future<SpriteAnimation> buildAnimation() async {
    final sprites = await Future.wait(
      List.generate(
        PawAssets.fishFrameCount,
        (i) => Sprite.load(PawAssets.fishFrame(i)),
      ),
    );
    return SpriteAnimation.spriteList(sprites, stepTime: 0.12);
  }

  static Fish fromAnimation(
    SpriteAnimation animation, {
    required int x,
    required int y,
    double visualSize = GameConfig.fishVisualSize,
  }) {
    return Fish._(
      animation: animation.clone(),
      gridX: x,
      gridY: y,
      visualSize: visualSize,
    ).._bobOffset = (x + y) * 0.7;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bobOffset += dt * 3;
    position.setFrom(Vector2(
      GameConfig.cellCenterX(gridX),
      GameConfig.cellCenterY(gridY) + sin(_bobOffset) * 2,
    ));
  }

  @override
  void render(Canvas canvas) {
    final glowPaint = Paint()
      ..color = const Color(0x5533AAFF)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        4,
      );

    canvas.drawCircle(
      Offset(
        size.x / 2,
        size.y / 2,
      ),
      size.x * 0.45,
      glowPaint,
    );

    super.render(canvas);
  }
}
