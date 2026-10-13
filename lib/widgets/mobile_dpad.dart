import 'package:flutter/material.dart';

import '../game/components/player.dart';
import '../game/config/game_colors.dart';

/// Square pixel-style D-pad. Every button funnels into the same
/// [onDirectionPressed] / [onDirectionHeld] callbacks, so touch and
/// keyboard share one movement path. The centre pad pauses the game
/// through [onPause].
class MobileDPad extends StatelessWidget {
  const MobileDPad({
    super.key,
    required this.onDirectionPressed,
    this.onDirectionHeld,
    this.onDirectionReleased,
    this.onPause,
  });

  final void Function(PlayerDirection direction) onDirectionPressed;
  final void Function(PlayerDirection direction)? onDirectionHeld;
  final void Function(PlayerDirection direction)? onDirectionReleased;
  final VoidCallback? onPause;

  static const double buttonSize = 50;
  static const double gap = 5;

  @override
  Widget build(BuildContext context) {
    Widget arrow(PlayerDirection direction) => _HoldButton(
          arrow: direction,
          onPressed: onDirectionPressed,
          onHeld: onDirectionHeld,
          onReleased: onDirectionReleased,
        );

    final width = buttonSize * 3 + gap * 2;
    final height = buttonSize * 3 + gap * 2;

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(PlayerDirection.up),
          const SizedBox(height: gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              arrow(PlayerDirection.left),
              const SizedBox(width: gap),
              // Centre pad pauses the game.
              _CenterButton(onPressed: onPause),
              const SizedBox(width: gap),
              arrow(PlayerDirection.right),
            ],
          ),
          const SizedBox(height: gap),
          arrow(PlayerDirection.down),
        ],
      ),
    );
  }
}

class _HoldButton extends StatefulWidget {
  const _HoldButton({
    required this.arrow,
    required this.onPressed,
    this.onHeld,
    this.onReleased,
  });

  final PlayerDirection arrow;
  final void Function(PlayerDirection direction) onPressed;
  final void Function(PlayerDirection direction)? onHeld;
  final void Function(PlayerDirection direction)? onReleased;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _pressed = false;

  void _start() {
    if (_pressed) return;
    setState(() => _pressed = true);
    if (widget.onHeld != null) {
      widget.onHeld!(widget.arrow);
    } else {
      widget.onPressed(widget.arrow);
    }
  }

  void _end() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onReleased?.call(widget.arrow);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _labelFor(widget.arrow),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _start(),
        onTapUp: (_) => _end(),
        onTapCancel: _end,
        child: Container(
          width: MobileDPad.buttonSize,
          height: MobileDPad.buttonSize,
          decoration: BoxDecoration(
            color: GameColors.panel,
            border: Border.all(
              color: _pressed ? GameColors.yellow : GameColors.border,
              width: 3,
            ),
          ),
          child: CustomPaint(
            painter: _PixelArrowPainter(
              direction: widget.arrow,
              color: _pressed ? GameColors.yellow : GameColors.white,
            ),
            size: const Size(30, 30),
          ),
        ),
      ),
    );
  }

  String _labelFor(PlayerDirection direction) {
    switch (direction) {
      case PlayerDirection.up:
        return 'UP';
      case PlayerDirection.down:
        return 'DOWN';
      case PlayerDirection.left:
        return 'LEFT';
      case PlayerDirection.right:
        return 'RIGHT';
    }
  }
}

/// Chunky pixel arrow drawn from solid blocks, matching the
/// game's 8-bit look instead of a Material icon.
class _PixelArrowPainter extends CustomPainter {
  _PixelArrowPainter({required this.direction, required this.color});

  final PlayerDirection direction;
  final Color color;

  /// Filled cells on a 5x5 grid, per direction.
  List<Offset> get cells {
    switch (direction) {
      case PlayerDirection.up:
        return const [
          Offset(2, 0),
          Offset(1, 1),
          Offset(2, 1),
          Offset(3, 1),
          Offset(0, 2),
          Offset(1, 2),
          Offset(2, 2),
          Offset(3, 2),
          Offset(4, 2),
          Offset(2, 3),
          Offset(2, 4),
        ];
      case PlayerDirection.down:
        return const [
          Offset(2, 0),
          Offset(2, 1),
          Offset(0, 2),
          Offset(1, 2),
          Offset(2, 2),
          Offset(3, 2),
          Offset(4, 2),
          Offset(1, 3),
          Offset(2, 3),
          Offset(3, 3),
          Offset(2, 4),
        ];
      case PlayerDirection.left:
        return const [
          Offset(2, 0),
          Offset(1, 1),
          Offset(2, 1),
          Offset(0, 2),
          Offset(1, 2),
          Offset(2, 2),
          Offset(3, 2),
          Offset(4, 2),
          Offset(1, 3),
          Offset(2, 3),
          Offset(2, 4),
        ];
      case PlayerDirection.right:
        return const [
          Offset(2, 0),
          Offset(2, 1),
          Offset(3, 1),
          Offset(0, 2),
          Offset(1, 2),
          Offset(2, 2),
          Offset(3, 2),
          Offset(4, 2),
          Offset(2, 3),
          Offset(3, 3),
          Offset(2, 4),
        ];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 5;
    final paint = Paint()..color = color;
    for (final cell in cells) {
      canvas.drawRect(
        Rect.fromLTWH(
          cell.dx * unit,
          cell.dy * unit,
          unit,
          unit,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelArrowPainter oldDelegate) =>
      oldDelegate.direction != direction || oldDelegate.color != color;
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'PAUSE',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: MobileDPad.buttonSize,
          height: MobileDPad.buttonSize,
          decoration: BoxDecoration(
            color: GameColors.panelDark,
            border: Border.all(color: GameColors.border, width: 3),
          ),
          child: CustomPaint(
            painter: _PixelPausePainter(
              color: GameColors.gray,
            ),
            size: const Size(24, 24),
          ),
        ),
      ),
    );
  }
}

/// Pixel pause glyph: two solid bars.
class _PixelPausePainter extends CustomPainter {
  _PixelPausePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 6;
    final paint = Paint()..color = color;
    for (final x in const [1.0, 2.0, 4.0, 5.0]) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, unit, unit, unit * 4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelPausePainter oldDelegate) =>
      oldDelegate.color != color;
}
