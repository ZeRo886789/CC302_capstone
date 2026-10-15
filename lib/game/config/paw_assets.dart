class PawAssets {
  PawAssets._();

  static const double catFrameSize = 128.0;
  static const int catFramesPerRow = 4;

  static String catSheet(String catName) =>
      'cats/$catName/${catName}_spritesheet.png';

  static String catFrame(String catName, String anim, int frame) =>
      'cats/$catName/${anim}_$frame.png';

  static String catIdleFrame(String catName, int frame) =>
      'cats/$catName/idle_$frame.png';

  static const String fishSheet = 'collectibles/fish_sheet.png';

  /// Number of supplied fish animation frames (fish_0 .. fish_4).
  static const int fishFrameCount = 5;
  static String fishFrame(int i) =>
      'collectibles/fish_${i % fishFrameCount}.png';

  /// HUD icon used by the fish counter.
  static const String fishIcon = 'ui/icons/fish.png';

  /// Icon used to denote the hazard count on the level card.
  static const String hazardIcon = 'tiles/extra/crate.png';

  /// Star icon marking a cleared level on the level-select card.
  static const String star = 'ui/icons/star.png';

  static const String finishFlag = 'goal/finish_flag.png';

  static String wall(String theme) => 'tiles/$theme/wall.png';
  static String wallVariant(String theme, int i) =>
      'tiles/$theme/wall_${i % 8}.png';

  static String floor(String theme) => 'tiles/$theme/floor.png';
  static const String floorDark = 'tiles/extra/floor_dark.png';
  static const String pellet = 'tiles/extra/pellet.png';

  /// Hazard obstacle shown on cells marked 'X' in the level data.
  static const String hazard = 'tiles/extra/crate.png';

  /// Paw Coin currency icon.
  static const String coin = 'tiles/extra/coin.png';

  static String digit(int d) => 'ui/font/digits/$d.png';
  static String letter(String ch) => 'ui/font/letters/${ch.toUpperCase()}.png';

  static const String sparkleSmall = 'effects/sparkle_small.png';
  static const String sparkleBig = 'effects/sparkle_big.png';
  static const String sparkleCross = 'effects/sparkle_cross.png';
  static const String sparkleDiamond = 'effects/sparkle_diamond.png';

  static String themeForLevel(int level) {
    const themes = ['blue', 'green', 'red', 'gray', 'ice'];
    return themes[(level - 1).clamp(0, themes.length - 1).toInt()];
  }
}
