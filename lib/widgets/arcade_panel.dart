import 'dart:async';

import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';

/// Framed pixel-art panel: square corners, dark fill, bright blue arcade border.
class ArcadePanel extends StatelessWidget {
  const ArcadePanel({
    super.key,
    required this.child,
    this.width,
    this.borderColor = GameColors.panelBlue,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double? width;
  final Color borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: GameColors.panel,
        border: Border.all(color: borderColor, width: 3),
      ),
      child: child,
    );
  }
}

/// A chunky arcade menu option. Shows a blinking `>` when selected.
class ArcadeMenuOption extends StatefulWidget {
  const ArcadeMenuOption({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSelected = false,
    this.isFirst = false,
    this.height = 42,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isSelected;

  /// Suppresses the focus highlight, used for the first (auto-selected) row.
  final bool isFirst;

  final double height;

  @override
  State<ArcadeMenuOption> createState() => _ArcadeMenuOptionState();
}

class _ArcadeMenuOptionState extends State<ArcadeMenuOption> {
  bool _hovered = false;
  bool _showCursor = true;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() => _showCursor = !_showCursor);
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _hovered || widget.isSelected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: double.infinity,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? GameColors.panelBlue : GameColors.panelDark,
            border: Border.all(
              color: active ? GameColors.yellow : GameColors.border,
              width: 3,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: active && _showCursor
                    ? const Text(
                        '>',
                        style: TextStyle(
                          color: GameColors.yellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: active ? GameColors.yellow : GameColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
