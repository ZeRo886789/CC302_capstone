import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';
import '../game/config/paw_assets.dart';

class FishCounter extends StatelessWidget {
  const FishCounter({
    super.key,
    required this.collected,
    required this.total,
  });

  final int collected;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/${PawAssets.fishIcon}',
          width: 16,
          height: 16,
          filterQuality: FilterQuality.none,
        ),
        const SizedBox(width: 4),
        Text(
          '$collected/$total',
          style: const TextStyle(
            color: GameColors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
