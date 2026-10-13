import '../data/level_data.dart';

class CollisionSystem {
  CollisionSystem(this.levelData);

  final LevelData levelData;

  bool canMoveTo(int x, int y) {
    return levelData.isWalkable(x, y);
  }

  bool checkWallCollision(int x, int y) {
    return levelData.isWall(x, y);
  }

  bool isValidPosition(int x, int y) {
    return x >= 0 && y >= 0 && x < levelData.width && y < levelData.height;
  }
}
