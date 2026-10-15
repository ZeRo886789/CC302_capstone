import 'package:flutter/material.dart';

import '../models/history_entry.dart';
import '../widgets/arcade_panel.dart';
import '../game/config/game_colors.dart';

/// A tile displaying a single adventure history entry.
class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry, required this.onDelete});

  final HistoryEntry entry;
  final void Function(HistoryEntry) onDelete;

  @override
  Widget build(BuildContext context) {
    return ArcadePanel(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level ${entry.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Score: ${_formatScore(entry.score)}',
                  style: const TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Time: ${entry.formattedTime}',
                  style: const TextStyle(
                    color: GameColors.factCaption,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(entry.date)} · ${_formatTimeOfDay(entry.date)}',
                  style: const TextStyle(
                    color: GameColors.factCaption,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            iconSize: 48,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.delete,
              color: GameColors.trashRed,
              size: 28,
            ),
            onPressed: () => onDelete(entry),
            tooltip: 'Delete entry',
          ),
        ],
      ),
    );
  }

  /// Formats an integer with thousands separators.
  String _formatScore(int score) {
    return score.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match.group(1)},',
    );
  }

  /// Formats a DateTime as a short date string, e.g., "Mar 5, 2026".
  String _formatDate(DateTime date) {
    return '${_shortMonths[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Formats a DateTime as a time string in 12-hour format, e.g., "3:42 PM".
  String _formatTimeOfDay(DateTime date) {
    final int hour = date.hour % 12;
    final int minute = date.minute;
    final String period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${minute.toString().padLeft(2, '0')} $period';
  }

  static final List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
