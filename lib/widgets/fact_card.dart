import 'package:flutter/material.dart';

import '../models/fact.dart';
import '../widgets/arcade_panel.dart';
import '../game/config/game_colors.dart';

/// A card displaying a single cat fact with favorite toggle and delete button.
class FactCard extends StatelessWidget {
  const FactCard({
    super.key,
    required this.fact,
    required this.isFavorite,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  final Fact fact;
  final bool isFavorite;
  final Future<void> Function(Fact) onDelete;
  final void Function(Fact) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return ArcadePanel(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fact.text,
                    style: const TextStyle(
                      color: GameColors.factText,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${fact.length} characters',
                      style: TextStyle(
                        color: GameColors.factCaption,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  iconSize: 48,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite
                        ? GameColors.heartOn
                        : GameColors.heartOff,
                    size: 28,
                  ),
                  onPressed: () => onToggleFavorite(fact),
                  tooltip: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                ),
                const SizedBox(height: 12),
                IconButton(
                  iconSize: 48,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.delete,
                    color: GameColors.trashRed,
                    size: 28,
                  ),
                  onPressed: () async => await onDelete(fact),
                  tooltip: 'Delete fact',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
