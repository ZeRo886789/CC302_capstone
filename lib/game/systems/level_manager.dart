import '../data/level_data.dart';
import '../data/levels.dart';

class LevelManager {
  LevelData? currentLevelData;

  void loadLevel(int levelNumber) {
    currentLevelData = Levels.getLevel(levelNumber);
  }

  LevelData? get levelData => currentLevelData;

  int get levelCount => Levels.all.length;

  LevelData getLevel(int number) => Levels.getLevel(number);

  bool hasNextLevel(int currentLevel) {
    return currentLevel < levelCount;
  }
}
