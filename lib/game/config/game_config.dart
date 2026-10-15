class GameConfig {
  GameConfig._();

  // ------------------------------------------------------------
  // WORLD / TILE
  // ------------------------------------------------------------

  static const double tileSize = 24;

  static const double playerVisualSize = 31.2;
  static const double fishVisualSize = 26.4;
  static const double flagVisualSize = 31.2;
  static const double hazardVisualSize = 24.0;

  static const int mazeColumns = 15;
  static const int mazeRows = 21;

  static const double boardWidth = mazeColumns * tileSize;

  static const double boardHeight = mazeRows * tileSize;

  // ------------------------------------------------------------
  // CAMERA
  // ------------------------------------------------------------

  /// Logical camera viewport.
  ///
  /// This is intentionally smaller than the entire maze.
  /// The camera will move with the player.
  static const double cameraWidth = 240;

  static const double cameraHeight = 320;

  // ------------------------------------------------------------
  // PLAYER
  // ------------------------------------------------------------

  static const double playerMoveSpeed = 80.0;

  static const int startingHp = 3;

  static const double invulnerabilitySeconds = 1.2;

  // ------------------------------------------------------------
  // SCORE
  // ------------------------------------------------------------

  static const int fishScore = 100;
  static const int levelCompleteScore = 500;

  /// Awarded once, the first time a level is cleared.
  static const int firstClearBonus = 50;

  /// Each collected fish is worth this many Paw Coins.
  static const int fishCoinReward = 10;

  static const String saveKey = 'pawquest_save';

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  static double cellCenterX(int column) => column * tileSize + tileSize / 2;

  static double cellCenterY(int row) => row * tileSize + tileSize / 2;
}
