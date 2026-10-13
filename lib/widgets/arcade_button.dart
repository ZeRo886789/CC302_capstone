import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';

class ArcadeButton extends StatelessWidget {
  const ArcadeButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height = 44,
    this.backgroundColor,
    this.textColor,
  });

  final String text;
  final VoidCallback onPressed;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? GameColors.panel,
          foregroundColor: textColor ?? GameColors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: GameColors.border, width: 2),
            borderRadius: BorderRadius.zero,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
