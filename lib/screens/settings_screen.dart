import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';
import '../game/systems/save_manager.dart';
import '../widgets/arcade_panel.dart';

/// Settings contains only controls that actually do something: there are no
/// audio assets in the project, so no sound/music toggles are shown.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _resetting = false;

  Future<void> _resetProgress() async {
    setState(() => _resetting = true);
    await SaveManager.resetProgress();
    if (!mounted) return;
    setState(() => _resetting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PROGRESS RESET')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ArcadePanel(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'SETTINGS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameColors.yellow,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRow(
                    'CONTROLS',
                    'WASD / ARROWS / DPAD',
                  ),
                  const SizedBox(height: 12),
                  _buildRow('AUDIO', 'NOT INCLUDED'),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _resetting ? null : _resetProgress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameColors.panelDark,
                        foregroundColor: GameColors.red,
                        shape: const RoundedRectangleBorder(
                          side: BorderSide(
                            color: GameColors.red,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        _resetting ? 'RESETTING...' : 'RESET PROGRESS',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameColors.panel,
                        foregroundColor: GameColors.white,
                        shape: const RoundedRectangleBorder(
                          side: BorderSide(color: GameColors.border, width: 3),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        'BACK',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GameColors.red,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: GameColors.white,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
