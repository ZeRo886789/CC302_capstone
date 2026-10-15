import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:math' show min;

import '../game/config/game_colors.dart';
import '../game/systems/save_manager.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/pixel_text.dart';
import 'cat_select.dart';
import 'adventure_history_screen.dart';
import 'cat_facts_screen.dart';
import 'game_screen.dart';
import 'level_select.dart';
import 'settings_screen.dart';
import 'shop.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  late Future<GameState> _gameStateFuture;
  final FocusNode _menuFocus = FocusNode();

  static const List<String> _items = [
    'START GAME',
    'SELECT CAT',
    'SHOP',
    'SELECT LEVEL',
    'CAT FACTS',
    'ADVENTURE HISTORY',
    'SETTINGS',
  ];

  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _gameStateFuture = SaveManager.load();
  }

  @override
  void dispose() {
    _menuFocus.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _gameStateFuture = SaveManager.load();
    });
  }

  void _openCatSelect(GameState state) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => CatSelectScreen(savedState: state),
          ),
        )
        .then((_) => _reload());
  }

  void _openLevelSelect(GameState state) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => LevelSelectScreen(savedState: state),
          ),
        )
        .then((_) => _reload());
  }

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const SettingsScreen()))
        .then((_) => _reload());
  }

  void _openShop(GameState state) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ShopScreen(savedState: state),
          ),
        )
        .then((_) => _reload());
  }

  void _activate(GameState state) {
    switch (_selected) {
      case 0:
        // START GAME always begins at Level 1; SELECT LEVEL is for resuming.
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GameScreen(
              selectedCat: state.selectedCat,
              initialLevel: 1,
              savedState: state,
            ),
          ),
        );
      case 1:
        _openCatSelect(state);
      case 2:
        _openShop(state);
      case 3:
        _openLevelSelect(state);
      case 4:
        Navigator.of(context)
            .push(
              MaterialPageRoute(builder: (context) => const CatFactsScreen()),
            )
            .then((_) => _reload());
      case 5:
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => const AdventureHistoryScreen(),
              ),
            )
            .then((_) => _reload());
      case 6:
        _openSettings();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.keyS) {
      setState(() => _selected = (_selected + 1) % _items.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.keyW) {
      setState(
        () => _selected = (_selected - 1 + _items.length) % _items.length,
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _activate(_cachedState);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  GameState _cachedState = GameState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: Focus(
          focusNode: _menuFocus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: FutureBuilder<GameState>(
            future: _gameStateFuture,
            builder: (context, snapshot) {
              final state = snapshot.data ?? GameState();
              _cachedState = state;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 640;
                  final double buttonWidth = min(
                    280,
                    constraints.maxWidth * 0.8,
                  );
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/cats/${state.selectedCat}'
                                '/idle_0.png',
                                width: compact ? 64 : 96,
                                height: compact ? 64 : 96,
                                filterQuality: FilterQuality.none,
                              ),
                              const SizedBox(height: 12),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        GameColors.yellow,
                                        GameColors.orange,
                                        GameColors.red,
                                      ],
                                    ).createShader(bounds),
                                child: const Text(
                                  'PAWQUEST',
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'CAT MAZE ADVENTURE',
                                style: TextStyle(
                                  color: GameColors.white,
                                  fontSize: 13,
                                  letterSpacing: 3,
                                ),
                              ),
                              SizedBox(height: compact ? 20 : 36),
                              SizedBox(
                                width: buttonWidth,
                                child: Column(
                                  children: [
                                    for (var i = 0; i < _items.length; i++) ...[
                                      if (i > 0) const SizedBox(height: 8),
                                      _MenuRow(
                                        label: _items[i],
                                        isSelected: i == _selected,
                                        onTap: () {
                                          setState(() => _selected = i);
                                          _activate(state);
                                        },
                                        buttonWidth: buttonWidth,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ArcadePanel(
                                width: 200,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'HIGH SCORE',
                                      style: TextStyle(
                                        color: GameColors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    PixelText(
                                      state.highScore.toString().padLeft(
                                        5,
                                        '0',
                                      ),
                                      height: 18,
                                      color: GameColors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.buttonWidth,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double buttonWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonWidth,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? GameColors.panelBlue : GameColors.panelDark,
          border: Border.all(
            color: isSelected ? GameColors.yellow : GameColors.border,
            width: 3,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: GameColors.yellow,
              )
            else
              const SizedBox(width: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? GameColors.yellow : GameColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
