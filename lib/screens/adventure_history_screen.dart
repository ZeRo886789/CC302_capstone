import 'package:flutter/material.dart';

import 'package:pawquest/game/systems/save_manager.dart';

import '../models/history_entry.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/history_tile.dart';

import '../game/config/game_colors.dart';

/// Screen displaying the adventure history (completed levels).
class AdventureHistoryScreen extends StatefulWidget {
  const AdventureHistoryScreen({super.key});

  @override
  State<AdventureHistoryScreen> createState() => _AdventureHistoryScreenState();
}

class _AdventureHistoryScreenState extends State<AdventureHistoryScreen> {
  List<HistoryEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Loads the adventure history from saved preferences.
  Future<void> _loadHistory() async {
    _history = await SaveManager.loadHistory();
    setState(() {
      _isLoading = false;
    });
  }

  /// Deletes a history entry after confirmation.
  Future<void> _deleteHistoryEntry(HistoryEntry entry) async {
    bool confirmed = await showConfirmDialog(
      context,
      title: 'Delete entry?',
      message: 'This adventure will be removed from your history.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    );
    if (!confirmed) return;

    // Find the index of the entry in the current list (for undo)
    final index = _history.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      // Entry not found, nothing to do
      return;
    }

    // Store the entry for possible undo
    final HistoryEntry removed = _history[index];

    // Remove the entry optimistically
    setState(() {
      _history.removeAt(index);
    });

    // Persist the deletion
    await SaveManager.deleteHistoryEntryById(entry.id);

    if (!mounted) return;

    // Show snackbar with undo action
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: GameColors.panelDark,
        content: const Text('Entry deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: GameColors.yellow,
          onPressed: () async {
            // Revert the deletion: insert the entry back at its original position
            setState(() {
              _history.insert(index.clamp(0, _history.length), removed);
            });
            // Persist the undo
            await SaveManager.saveHistory(_history);
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        title: Text(
          'ADVENTURE HISTORY',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: GameColors.yellow,
          ),
        ),
        centerTitle: true,
        backgroundColor: GameColors.panel,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: GameColors.yellow,
                      ),
                    ),
                  )
                : _history.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'NO ADVENTURE HISTORY YET.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: GameColors.white,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final entry = _history[index];
                      return HistoryTile(
                        entry: entry,
                        onDelete: _deleteHistoryEntry,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
