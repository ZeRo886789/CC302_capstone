import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';
import '../game/config/paw_assets.dart';
import '../game/data/cat_data.dart';
import '../game/systems/save_manager.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/pixel_lock.dart';
import '../widgets/pixel_text.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.savedState});

  final GameState savedState;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late GameState _state;
  String? _message;

  @override
  void initState() {
    super.initState();
    _state = widget.savedState;
  }

  Future<void> _buy(CatData cat) async {
    if (cat.price <= 0) return;
    final purchased = _state.buyCat(cat.name);
    if (!purchased) {
      setState(() => _message = 'NOT ENOUGH PAW COINS');
      return;
    }
    await SaveManager.save(_state);
    setState(() => _message = '${cat.name.toUpperCase()} PURCHASED!');
  }

  void _select(CatData cat) {
    _state.selectedCat = cat.name;
    SaveManager.save(_state);
    setState(() => _message = '${cat.name.toUpperCase()} SELECTED');
  }

  @override
  Widget build(BuildContext context) {
    final cats = CatSkins.all();
    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const PixelText('PAW SHOP', height: 16, color: GameColors.yellow),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/${PawAssets.coin}',
                  width: 20,
                  height: 20,
                  filterQuality: FilterQuality.none,
                ),
                const SizedBox(width: 8),
                Text(
                  _state.pawCoins.toString().padLeft(5, '0'),
                  style: const TextStyle(
                    color: GameColors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  for (final cat in cats) _buildCatCard(cat),
                  const SizedBox(height: 16),
                  ArcadeMenuOption(
                    label: 'BACK',
                    onPressed: () => Navigator.of(context).pop(),
                    isSelected: true,
                  ),
                ],
              ),
            ),
            if (_message != null) ...[
              Text(
                _message!,
                style: const TextStyle(
                  color: GameColors.yellow,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCatCard(CatData cat) {
    final owned = _state.isCatUnlocked(cat.name);
    final selected = _state.selectedCat == cat.name;
    final available = _state.catIsAvailable(cat.name);

    Widget label;
    if (selected) {
      label = const Text(
        'SELECTED',
        style: TextStyle(
          color: GameColors.yellow,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      );
    } else if (owned) {
      label = const Text(
        'OWNED',
        style: TextStyle(
          color: GameColors.green,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      );
    } else if (available) {
      label = Text(
        '${cat.price} PAW COINS',
        style: const TextStyle(
          color: GameColors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      );
    } else {
      label = Text(
        cat.requirementText,
        style: const TextStyle(color: GameColors.gray, fontSize: 11),
      );
    }

    Widget action;
    if (!owned && available && cat.price > 0) {
      action = ArcadeMenuOption(
        label: 'BUY',
        onPressed: () => _buy(cat),
        isSelected: true,
      );
    } else if (owned && !selected) {
      action = ArcadeMenuOption(
        label: 'SELECT',
        onPressed: () => _select(cat),
        isSelected: true,
      );
    } else if (owned && selected) {
      action = const Text(
        'READY',
        style: TextStyle(
          color: GameColors.green,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      action = const SizedBox.shrink();
    }

    return ArcadePanel(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cat.name.toUpperCase(),
            style: const TextStyle(
              color: GameColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              if (!owned)
                Opacity(
                  opacity: 0.40,
                  child: Image.asset(
                    'assets/images/cats/${cat.name}/idle_0.png',
                    width: 72,
                    height: 72,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              if (owned)
                Image.asset(
                  'assets/images/cats/${cat.name}/idle_0.png',
                  width: 72,
                  height: 72,
                  filterQuality: FilterQuality.none,
                ),
              if (!owned && !available) const PixelLock(size: 26),
            ],
          ),
          const SizedBox(height: 8),
          label,
          const SizedBox(height: 10),
          action,
        ],
      ),
    );
  }
}
