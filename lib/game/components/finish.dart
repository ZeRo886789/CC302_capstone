import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../config/paw_assets.dart';
import '../data/level_data.dart';

/// The level exit, drawn from the supplied finish-flag sprite.
/// Each level has a unique visual style and animation.
/// The base finish sprite remains at fixed size and orientation;
/// uniqueness comes from particles, glow, and color effects.
class FinishFlag extends PositionComponent {
  FinishFlag({
    required this.levelData,
    required this.gridX,
    required this.gridY,
  }) : super(
         position: Vector2(
           GameConfig.cellCenterX(gridX),
           GameConfig.cellCenterY(gridY),
         ),
         size: Vector2.all(GameConfig.flagVisualSize),
         anchor: Anchor.center,
       );

  final LevelData levelData;
  final int gridX;
  final int gridY;

  bool active = false;

  // Animation state
  double _pulsePhase = 0;
  double _particleTimer = 0;
  double _glowIntensity = 0;

  // Components for different styles
  SpriteComponent? _baseSprite;
  SpriteComponent? _glowSprite;
  final List<_FinishParticle> _particles = [];

  // Style-specific config
  late final _StyleConfig _config;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _config = _StyleConfig.forStyle(levelData.finishStyle, levelData.theme);

    // Load base sprite - fixed size and orientation
    final baseSprite = await Sprite.load(_config.baseSpritePath);
    _baseSprite = SpriteComponent(
      sprite: baseSprite,
      size: Vector2.all(GameConfig.flagVisualSize),
      anchor: Anchor.center,
    );
    _baseSprite!.paint.filterQuality = FilterQuality.none;
    add(_baseSprite!);

    // Load glow sprite if applicable
    if (_config.glowSpritePath != null) {
      final glowSprite = await Sprite.load(_config.glowSpritePath!);
      _glowSprite = SpriteComponent(
        sprite: glowSprite,
        size: Vector2.all(GameConfig.flagVisualSize * _config.glowScale!),
        anchor: Anchor.center,
      );
      _glowSprite!.paint.filterQuality = FilterQuality.none;
      _glowSprite!.paint.blendMode = BlendMode.plus;
      add(_glowSprite!);
    }

    // Spawn initial particles for some styles
    if (_config.spawnParticlesOnLoad) {
      _spawnParticles(3);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!active) {
      // Locked state: subtle pulse on glow only
      _pulsePhase += dt * 2;
      if (_glowSprite != null) {
        _glowIntensity = 0.2 + math.sin(_pulsePhase) * 0.1;
        _glowSprite!.paint.color = Colors.white.withValues(
          alpha: _glowIntensity,
        );
        final lockedScale = 1 + math.sin(_pulsePhase) * 0.05;
        _glowSprite!.size = Vector2.all(
          GameConfig.flagVisualSize * _config.glowScale! * lockedScale,
        );
      }
      return;
    }

    // Active state: unique animation per style (glow/particles only)
    _pulsePhase += dt * _config.pulseSpeed;
    _particleTimer += dt;

    // Style-specific animations (glow/particles only - base sprite fixed)
    switch (levelData.finishStyle) {
      case FinishStyle.welcomingGate:
        _updateWelcomingGate(dt);
        break;
      case FinishStyle.magicalPortal:
        _updateMagicalPortal(dt);
        break;
      case FinishStyle.crystalGate:
        _updateCrystalGate(dt);
        break;
      case FinishStyle.epicArchway:
        _updateEpicArchway(dt);
        break;
      case FinishStyle.victoryPortal:
        _updateVictoryPortal(dt);
        break;
      default:
        break;
    }

    // Update particles
    _updateParticles(dt);

    // Spawn new particles periodically
    if (_particleTimer >= _config.particleSpawnInterval) {
      _particleTimer = 0;
      _spawnParticles(_config.particlesPerSpawn);
    }
  }

  void _updateWelcomingGate(double dt) {
    // Gentle warm pulse on glow only
    if (_glowSprite != null) {
      _glowIntensity = 0.3 + math.sin(_pulsePhase * 0.8) * 0.2;
      _glowSprite!.paint.color = Colors.amber.withValues(alpha: _glowIntensity);
      final glowPulse = 1 + math.sin(_pulsePhase * 0.8) * 0.15;
      _glowSprite!.size = Vector2.all(
        GameConfig.flagVisualSize * _config.glowScale! * glowPulse,
      );
    }
  }

  void _updateMagicalPortal(double dt) {
    // Rotating glow with color cycling (base sprite stays fixed)
    if (_glowSprite != null) {
      _glowSprite!.angle = _pulsePhase * 0.5;
      final glowPulse = 1 + math.sin(_pulsePhase * 1.2) * 0.2;
      _glowSprite!.size = Vector2.all(
        GameConfig.flagVisualSize * _config.glowScale! * glowPulse,
      );
      _glowIntensity = 0.4 + math.sin(_pulsePhase * 1.5) * 0.3;
      _glowSprite!.paint.color = Colors.cyanAccent.withValues(
        alpha: _glowIntensity,
      );
    }
  }

  void _updateCrystalGate(double dt) {
    // Sharp crystalline pulsing with color shift on glow
    if (_glowSprite != null) {
      final colorShift = (math.sin(_pulsePhase * 1.5) + 1) / 2;
      _glowIntensity = 0.5 + math.sin(_pulsePhase * 2.5) * 0.3;
      _glowSprite!.paint.color = Color.lerp(
        Colors.deepOrangeAccent,
        Colors.cyanAccent,
        colorShift,
      )!.withValues(alpha: _glowIntensity);
      final glowPulse = 1 + math.sin(_pulsePhase * 2) * 0.25;
      _glowSprite!.size = Vector2.all(
        GameConfig.flagVisualSize * _config.glowScale! * glowPulse,
      );
    }
  }

  void _updateEpicArchway(double dt) {
    // Grand, slow majestic glow pulse
    if (_glowSprite != null) {
      _glowIntensity = 0.6 + math.sin(_pulsePhase * 1.0) * 0.25;
      _glowSprite!.paint.color = Colors.amber.withValues(alpha: _glowIntensity);
      final glowPulse = 1 + math.sin(_pulsePhase * 0.8) * 0.2;
      _glowSprite!.size = Vector2.all(
        GameConfig.flagVisualSize * _config.glowScale! * glowPulse,
      );
    }
  }

  void _updateVictoryPortal(double dt) {
    // Spectacular final portal - color cycling glow with bursts
    if (_glowSprite != null) {
      // Multi-layer glow with color cycling
      final colorCycle = (_pulsePhase * 0.5) % (2 * math.pi);
      final r = (math.sin(colorCycle) + 1) / 2;
      final g = (math.sin(colorCycle + 2) + 1) / 2;
      final b = (math.sin(colorCycle + 4) + 1) / 2;

      _glowIntensity = 0.7 + math.sin(_pulsePhase * 2) * 0.2;
      _glowSprite!.paint.color = Color.fromRGBO(
        (255 * r).round(),
        (255 * g).round(),
        (255 * b).round(),
        _glowIntensity,
      );
      final glowPulse = 1 + math.sin(_pulsePhase * 1.5) * 0.3;
      _glowSprite!.size = Vector2.all(
        GameConfig.flagVisualSize * _config.glowScale! * glowPulse,
      );
      _glowSprite!.angle = _pulsePhase * 0.3;
    }

    // Extra particle bursts on major pulses
    if (math.sin(_pulsePhase * 1.5) > 0.95) {
      _spawnParticles(5);
    }
  }

  void _spawnParticles(int count) {
    if (_particles.length >= _config.maxParticles) return;

    for (int i = 0; i < count; i++) {
      final angle = math.Random().nextDouble() * 2 * math.pi;
      final speed =
          _config.particleSpeed * (0.5 + math.Random().nextDouble() * 0.5);
      final lifetime =
          _config.particleLifetime * (0.5 + math.Random().nextDouble() * 0.5);
      final size =
          _config.particleSize * (0.5 + math.Random().nextDouble() * 0.5);

      _particles.add(
        _FinishParticle(
          position: position.clone(),
          velocity: Vector2(math.cos(angle), math.sin(angle)) * speed,
          lifetime: lifetime,
          maxLifetime: lifetime,
          size: size,
          color: _config.particleColor,
        ),
      );
    }
  }

  void _updateParticles(double dt) {
    for (final particle in _particles) {
      particle.update(dt);
    }
    _particles.removeWhere((p) => p.isDead);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render particles
    for (final particle in _particles) {
      particle.render(canvas);
    }
  }
}

/// Configuration for each finish style.
class _StyleConfig {
  final String baseSpritePath;
  final String? glowSpritePath;
  final double? glowScale;
  final double pulseSpeed;
  final double particleSpawnInterval;
  final int particlesPerSpawn;
  final int maxParticles;
  final double particleSpeed;
  final double particleLifetime;
  final double particleSize;
  final Color particleColor;
  final bool spawnParticlesOnLoad;

  const _StyleConfig({
    required this.baseSpritePath,
    this.glowSpritePath,
    this.glowScale,
    required this.pulseSpeed,
    required this.particleSpawnInterval,
    required this.particlesPerSpawn,
    required this.maxParticles,
    required this.particleSpeed,
    required this.particleLifetime,
    required this.particleSize,
    required this.particleColor,
    required this.spawnParticlesOnLoad,
  });

  static _StyleConfig forStyle(FinishStyle style, String theme) {
    // Use the existing finish_flag.png as base for all levels.
    // Unique feel comes from glow animations, colors, particles.
    final baseSprite = PawAssets.finishFlag;

    switch (style) {
      case FinishStyle.welcomingGate:
        return _StyleConfig(
          baseSpritePath: baseSprite,
          glowSpritePath: baseSprite, // reuse flag as glow
          glowScale: 1.6,
          pulseSpeed: 1.2,
          particleSpawnInterval: 1.5,
          particlesPerSpawn: 2,
          maxParticles: 10,
          particleSpeed: 30,
          particleLifetime: 1.5,
          particleSize: 4,
          particleColor: Colors.amber,
          spawnParticlesOnLoad: false,
        );
      case FinishStyle.magicalPortal:
        return _StyleConfig(
          baseSpritePath: baseSprite,
          glowSpritePath: baseSprite,
          glowScale: 2.0,
          pulseSpeed: 2.0,
          particleSpawnInterval: 0.8,
          particlesPerSpawn: 3,
          maxParticles: 20,
          particleSpeed: 50,
          particleLifetime: 2.0,
          particleSize: 5,
          particleColor: Colors.cyanAccent,
          spawnParticlesOnLoad: true,
        );
      case FinishStyle.crystalGate:
        return _StyleConfig(
          baseSpritePath: baseSprite,
          glowSpritePath: baseSprite,
          glowScale: 1.8,
          pulseSpeed: 2.5,
          particleSpawnInterval: 1.0,
          particlesPerSpawn: 2,
          maxParticles: 15,
          particleSpeed: 40,
          particleLifetime: 1.8,
          particleSize: 4,
          particleColor: Colors.deepOrangeAccent,
          spawnParticlesOnLoad: true,
        );
      case FinishStyle.epicArchway:
        return _StyleConfig(
          baseSpritePath: baseSprite,
          glowSpritePath: baseSprite,
          glowScale: 2.2,
          pulseSpeed: 1.0,
          particleSpawnInterval: 0.6,
          particlesPerSpawn: 4,
          maxParticles: 25,
          particleSpeed: 60,
          particleLifetime: 2.5,
          particleSize: 6,
          particleColor: Colors.amber,
          spawnParticlesOnLoad: true,
        );
      case FinishStyle.victoryPortal:
        return _StyleConfig(
          baseSpritePath: baseSprite,
          glowSpritePath: baseSprite,
          glowScale: 2.5,
          pulseSpeed: 2.0,
          particleSpawnInterval: 0.4,
          particlesPerSpawn: 5,
          maxParticles: 35,
          particleSpeed: 80,
          particleLifetime: 3.0,
          particleSize: 7,
          particleColor: Colors.white,
          spawnParticlesOnLoad: true,
        );
      case FinishStyle.standard:
        return _StyleConfig(
          baseSpritePath: baseSprite,
          glowSpritePath: null,
          glowScale: null,
          pulseSpeed: 0,
          particleSpawnInterval: 999,
          particlesPerSpawn: 0,
          maxParticles: 0,
          particleSpeed: 0,
          particleLifetime: 0,
          particleSize: 0,
          particleColor: Colors.transparent,
          spawnParticlesOnLoad: false,
        );
    }
  }
}

/// Simple particle for finish line effects.
class _FinishParticle {
  _FinishParticle({
    required this.position,
    required this.velocity,
    required this.lifetime,
    required this.maxLifetime,
    required this.size,
    required this.color,
  });

  Vector2 position;
  Vector2 velocity;
  double lifetime;
  final double maxLifetime;
  final double size;
  final Color color;

  bool get isDead => lifetime <= 0;

  void update(double dt) {
    lifetime -= dt;
    position += velocity * dt;
    velocity *= 0.98; // drag
  }

  void render(Canvas canvas) {
    if (isDead) return;
    final alpha = (lifetime / maxLifetime).clamp(0.0, 1.0).toDouble();
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(position.x, position.y), size * alpha, paint);
  }
}
