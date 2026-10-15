import 'package:flutter/material.dart';

import '../game/config/game_colors.dart';
import '../game/data/cat_data.dart';
import '../game/systems/save_manager.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/pixel_lock.dart';
import '../widgets/pixel_text.dart';
import 'game_screen.dart';

/// Pixel-art cat select. The currently selected cat (Kuro on a fresh
/// save) is shown large at the top; the other two sit below as smaller
/// cards so all three are always visible at a glance.
///
/// Cats that are not owned are shown dimmed with a PixelLock overlay and
/// a "LOCKED" label; tapping them displays the unlock requirement instead
/// of silently failing.
class CatSelectScreen extends StatefulWidget {
  const CatSelectScreen({super.key, required this.savedState});

  final GameState savedState;

  @override
  State<CatSelectScreen> createState() => _CatSelectScreenState();
}

class _CatSelectScreenState extends State<CatSelectScreen> {
  String? _lockedMessage;

  GameState get _saved => widget.savedState;

  void _choose(CatData cat) {
    final owned = _saved.isCatUnlocked(cat.name);
    if (!owned) {
      setState(() => _lockedMessage = cat.requirementText);
      return;
    }
    setState(() => _lockedMessage = null);
    _saved.selectedCat = cat.name;
    SaveManager.save(_saved);
  }

  void _continue() {
    final selectedCatName = _saved.selectedCat;

    // Safety net: if the saved selection is somehow not owned, fall back
    // to Kuro. This should never happen in normal flow because the
    // selectedCat setter rejects unowned cats, but a stale save that
    // predates this check could still name a locked cat.
    if (!_saved.isCatUnlocked(selectedCatName)) {
      _saved.selectedCat = SaveManager.defaultCat;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          selectedCat: _saved.isCatUnlocked(selectedCatName)
              ? selectedCatName
              : SaveManager.defaultCat,
          initialLevel: 1,
          savedState: _saved,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 12.0 : 16.0;
            final contentWidth = constraints.maxWidth - horizontalPadding * 2;
            final cardGap = constraints.maxWidth < 380 ? 8.0 : 12.0;

            final cardWidth = ((contentWidth - cardGap * 2) / 3)
                .clamp(92.0, 116.0)
                .toDouble();

            final heroWidth = constraints.maxWidth < 380
                ? (contentWidth * 0.75).clamp(180.0, 220.0).toDouble()
                : 240.0;

            final continueWidth = constraints.maxWidth < 380
                ? (contentWidth * 0.8).clamp(180.0, 220.0).toDouble()
                : 220.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: ListenableBuilder(
                  listenable: _saved,
                  builder: (context, _) {
                    final selectedCatName = _saved.selectedCat;
                    final selectedCat = CatSkins.byName(selectedCatName);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        SizedBox(
                          width: contentWidth,
                          child: PixelText(
                            'SELECT YOUR CAT',
                            height: constraints.maxWidth < 380 ? 12 : 14,
                            color: GameColors.yellow,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildHero(selectedCat, heroWidth),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: cardGap,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final cat in CatSkins.all())
                              _CatCard(
                                key: ValueKey('cat-card-${cat.name}'),
                                cat: cat,
                                width: cardWidth,
                                selected: selectedCatName == cat.name,
                                owned: _saved.isCatUnlocked(cat.name),
                                available: _saved.catIsAvailable(cat.name),
                                onTap: () => _choose(cat),
                              ),
                          ],
                        ),
                        if (_lockedMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _lockedMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: GameColors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: continueWidth,
                          child: ArcadeMenuOption(
                            label: 'CONTINUE',
                            onPressed: _continue,
                            isSelected: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero(CatData cat, double width) {
    final owned = _saved.isCatUnlocked(cat.name);
    return ArcadePanel(
      width: width,
      borderColor: owned ? GameColors.yellow : GameColors.gray,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cat.name.toUpperCase(),
            style: TextStyle(
              color: owned ? GameColors.white : GameColors.gray,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: owned ? 1.0 : 0.4,
            child: Image.asset(
              'assets/images/cats/${cat.name}/idle_0.png',
              width: 112,
              height: 112,
              filterQuality: FilterQuality.none,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            owned ? 'SELECTED' : 'LOCKED',
            style: TextStyle(
              color: owned ? GameColors.yellow : GameColors.gray,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatCard extends StatelessWidget {
  const _CatCard({
    super.key,
    required this.cat,
    required this.width,
    required this.selected,
    required this.owned,
    required this.available,
    required this.onTap,
  });

  final CatData cat;
  final double width;
  final bool selected;
  final bool owned;
  final bool available;
  final VoidCallback onTap;

  String get _label {
    if (selected) return 'SELECTED';
    if (owned) return 'OWNED';
    if (available) return '${cat.price} PAW COINS';
    return 'LOCKED';
  }

  @override
  Widget build(BuildContext context) {
    final canInteract = owned || available;

    return Semantics(
      button: canInteract,
      label: canInteract
          ? cat.name.toUpperCase()
          : 'LOCKED - ${cat.name.toUpperCase()}',
      onTap: canInteract ? onTap : null,
      child: GestureDetector(
        onTap: canInteract ? onTap : null,
        child: Opacity(
          opacity: owned ? 1.0 : 0.4,
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: GameColors.panel,
              border: Border.all(
                color: selected
                    ? GameColors.yellow
                    : (owned ? GameColors.green : GameColors.border),
                width: 3,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat.name.toUpperCase(),
                      style: TextStyle(
                        color: selected
                            ? GameColors.yellow
                            : (owned ? GameColors.white : GameColors.gray),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Image.asset(
                      'assets/images/cats/${cat.name}/idle_0.png',
                      width: 72,
                      height: 72,
                      filterQuality: FilterQuality.none,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _label,
                      style: TextStyle(
                        color: selected
                            ? GameColors.yellow
                            : (owned ? GameColors.green : GameColors.gray),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                if (!owned)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: PixelLock(size: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
