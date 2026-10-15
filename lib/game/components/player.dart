import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../config/paw_assets.dart';

enum PlayerDirection { up, down, left, right }

enum _PlayerAnim { idle, up, down, left, right }

/// Tunable constants for the cat's animation polish.
class _CatAnim {
  _CatAnim._();

  /// Time per frame of each walk-direction animation.
  static const double walkStepTime = 0.12;

  /// Time per frame of the idle animation.
  static const double idleStepTime = 0.25;

  /// How long a single tile-to-tile move takes (seconds).
  static const double moveDuration = 0.15;
}

class Player extends SpriteAnimationGroupComponent<_PlayerAnim> {
  Player._({
    required this.catName,
    required Map<_PlayerAnim, SpriteAnimation> animations,
    required Vector2 position,
    required double visualSize,
  }) : super(
         animations: animations,
         current: _PlayerAnim.idle,
         size: Vector2.all(visualSize),
         position: position,
         anchor: Anchor.center,
       ) {
    paint.filterQuality = FilterQuality.none;
  }

  final String catName;
  int gridX = 0;
  int gridY = 0;
  bool isMoving = false;
  double moveProgress = 0.0;
  PlayerDirection moveDirection = PlayerDirection.down;

  /// Remaining hearts. Reaching zero ends the run for this level attempt.
  int hp = GameConfig.startingHp;

  /// Seconds of damage immunity remaining.
  double invulnerable = 0;

  /// Set when the player is knocked back off a hazard.
  bool _knockback = false;

  /// Cell the player occupied before the current move, so a hazard
  /// hit can bounce the cat back to where it came from.
  int _previousGridX = 0;
  int _previousGridY = 0;

  // --- Animation polish state ---

  bool get isDead => hp <= 0;

  static const double moveDuration = _CatAnim.moveDuration;

  static Future<Player> create(
    String catName, {
    required int gridX,
    required int gridY,
    double visualSize = GameConfig.playerVisualSize,
  }) async {
    final anims = <_PlayerAnim, SpriteAnimation>{};

    Future<SpriteAnimation> load(String dirName, double stepTime) async {
      final sprites = await Future.wait(
        List.generate(
          PawAssets.catFramesPerRow,
          (i) => Sprite.load(PawAssets.catFrame(catName, dirName, i)),
        ),
      );
      return SpriteAnimation.spriteList(sprites, stepTime: stepTime);
    }

    for (final entry in {
      _PlayerAnim.up: 'walk_up',
      _PlayerAnim.down: 'walk_down',
      _PlayerAnim.left: 'walk_left',
      _PlayerAnim.right: 'walk_right',
    }.entries) {
      anims[entry.key] = await load(entry.value, _CatAnim.walkStepTime);
    }
    anims[_PlayerAnim.idle] = await load('idle', _CatAnim.idleStepTime);

    return Player._(
        catName: catName,
        animations: anims,
        position: Vector2(
          GameConfig.cellCenterX(gridX),
          GameConfig.cellCenterY(gridY),
        ),
        visualSize: visualSize,
      )
      ..gridX = gridX
      ..gridY = gridY
      .._previousGridX = gridX
      .._previousGridY = gridY
      ..hp = GameConfig.startingHp;
  }

  /// Applies one point of damage. Returns true if the hit actually landed.
  bool takeHit() {
    if (invulnerable > 0 || isDead) return false;
    hp--;
    invulnerable = GameConfig.invulnerabilitySeconds;
    return true;
  }

  /// Bounces the cat back to the cell it came from after hitting a
  /// hazard, then locks movement for the mercy window.
  void knockBack(PlayerDirection fromDirection) {
    stopMove();
    gridX = _previousGridX;
    gridY = _previousGridY;
    _snapToGrid();
    _knockback = true;
  }

  void updateInvulnerability(double dt) {
    if (invulnerable > 0) {
      invulnerable = (invulnerable - dt).clamp(0.0, double.infinity).toDouble();
    }
  }

  // No update override needed — SpriteAnimationGroupComponent
  // handles animation ticking via the Flame component tree.

  @override
  void render(Canvas canvas) {
    // Blink while immune so the player can read the mercy window.
    final previous = paint.color;
    if (invulnerable > 0) {
      paint.color = (invulnerable * 12).floor().isEven
          ? const Color(0xFFFFFFFF)
          : const Color(0x88FFFFFF);
    }
    super.render(canvas);
    paint.color = previous;
  }

  Vector2 _gridCenter(int x, int y) =>
      Vector2(GameConfig.cellCenterX(x), GameConfig.cellCenterY(y));

  static _PlayerAnim _animFor(PlayerDirection dir) {
    switch (dir) {
      case PlayerDirection.up:
        return _PlayerAnim.up;
      case PlayerDirection.down:
        return _PlayerAnim.down;
      case PlayerDirection.left:
        return _PlayerAnim.left;
      case PlayerDirection.right:
        return _PlayerAnim.right;
    }
  }

  void setGridPosition(int x, int y) {
    gridX = x;
    gridY = y;
    _previousGridX = x;
    _previousGridY = y;
    _snapToGrid();
  }

  void _snapToGrid() {
    position.setFrom(_gridCenter(gridX, gridY));
  }

  bool canStartMove(
    PlayerDirection dir,
    bool Function(int x, int y) canMoveTo,
  ) {
    if (_knockback) return false;
    return !isMoving && canMoveTo(gridX + _dx(dir), gridY + _dy(dir));
  }

  bool playMove(PlayerDirection dir, bool Function(int x, int y) canMoveTo) {
    if (isMoving) return false;
    if (!canMoveTo(gridX + _dx(dir), gridY + _dy(dir))) return false;
    _previousGridX = gridX;
    _previousGridY = gridY;
    isMoving = true;
    moveProgress = 0.0;
    moveDirection = dir;
    _knockback = false;
    current = _animFor(dir);
    return true;
  }

  void updateMove(double dt, bool Function(int x, int y) canMoveTo) {
    if (!isMoving) return;

    moveProgress += dt / moveDuration;
    if (moveProgress >= 1.0) {
      moveProgress = 0.0;
      final newX = gridX + _dx(moveDirection);
      final newY = gridY + _dy(moveDirection);
      if (canMoveTo(newX, newY)) {
        gridX = newX;
        gridY = newY;
      }
      isMoving = false;
      current = _PlayerAnim.idle;
      _snapToGrid();
      return;
    }

    // Ease-out: the cat starts fast and glides to a stop, which reads
    // as more natural than a rigid linear slide.
    final t = moveProgress;
    final u = 1.0 - t;
    final eased = 1.0 - u * u * u;
    position.setFrom(
      Vector2(
        GameConfig.cellCenterX(gridX) +
            _dx(moveDirection) * GameConfig.tileSize * eased,
        GameConfig.cellCenterY(gridY) +
            _dy(moveDirection) * GameConfig.tileSize * eased,
      ),
    );
  }

  int _dx(PlayerDirection dir) {
    switch (dir) {
      case PlayerDirection.right:
        return 1;
      case PlayerDirection.left:
        return -1;
      default:
        return 0;
    }
  }

  int _dy(PlayerDirection dir) {
    switch (dir) {
      case PlayerDirection.down:
        return 1;
      case PlayerDirection.up:
        return -1;
      default:
        return 0;
    }
  }

  void stopMove() {
    isMoving = false;
    moveProgress = 0.0;
    current = _PlayerAnim.idle;
    _snapToGrid();
  }

  /// Clears the knockback lock so the player can move again.
  void clearKnockback() {
    _knockback = false;
  }

  bool get isKnockedBack => _knockback;

  /// Direction the player was travelling when knocked back.
  PlayerDirection get lastDirection => moveDirection;
}
