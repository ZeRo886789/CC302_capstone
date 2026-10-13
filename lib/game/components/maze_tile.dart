import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// One wall cell rendered from the level theme's pixel-art wall sprite.
class MazeTile extends SpriteComponent {
  MazeTile({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: Anchor.topLeft,
        ) {
    paint.filterQuality = FilterQuality.none;
  }
}
