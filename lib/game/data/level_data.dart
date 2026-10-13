class GridPoint {
  final int x;
  final int y;

  const GridPoint(this.x, this.y);

  @override
  String toString() => 'GridPoint($x, $y)';
}

/// Visual style for the finish line, unique per level.
enum FinishStyle {
  /// Level 1: Warm welcoming gate with gentle glow
  welcomingGate,
  /// Level 2: Magical portal with floating particles
  magicalPortal,
  /// Level 3: Crystal gate with pulsing energy
  crystalGate,
  /// Level 4: Epic archway with dramatic effects
  epicArchway,
  /// Level 5: Final destination - grand victory portal
  victoryPortal,
  /// Default fallback
  standard,
}

class LevelData {
  LevelData({
    required this.number,
    required this.name,
    required this.theme,
    required this.requiredFish,
    required this.maze,
    this.lightRadiusTiles = 5.0,
    this.finishStyle = FinishStyle.standard,
  }) {
    validate();
  }

  final int number;
  final String name;
  final String theme;
  final int requiredFish;
  final List<String> maze;

  /// Visibility radius of the player light, in tiles. Later levels get a
  /// slightly smaller circle so the maze feels gradually more atmospheric.
  final double lightRadiusTiles;

  /// Visual style for this level's finish line.
  final FinishStyle finishStyle;

  static const int expectedWidth = 15;
  static const int expectedHeight = 21;

  /// Throws [StateError] if this level is malformed. Runs at construction so a
  /// broken map can never silently reach gameplay.
  void validate() {
    if (maze.isEmpty) {
      throw StateError('Level $number ($name): maze is empty');
    }
    if (maze.length != expectedHeight) {
      throw StateError(
        'Level $number ($name): ${maze.length} rows, expected $expectedHeight',
      );
    }

    for (var i = 0; i < maze.length; i++) {
      if (maze[i].length != expectedWidth) {
        throw StateError(
          'Level $number ($name): row $i has width ${maze[i].length}, '
          'expected $expectedWidth',
        );
      }
      if (maze[i][0] != '#' || maze[i][expectedWidth - 1] != '#') {
        throw StateError(
          'Level $number ($name): row $i is missing a side wall',
        );
      }
    }

    if (maze.first[0] != '#' || maze.first[expectedWidth - 1] != '#') {
      throw StateError('Level $number ($name): missing top corner walls');
    }
    if (maze.last[0] != '#' || maze.last[expectedWidth - 1] != '#') {
      throw StateError('Level $number ($name): missing bottom corner walls');
    }

    final spawns = _count('P');
    if (spawns != 1) {
      throw StateError('Level $number ($name): found $spawns player spawns');
    }
    final exits = _count('E');
    if (exits != 1) {
      throw StateError('Level $number ($name): found $exits exits');
    }

    if (fishCount != requiredFish) {
      throw StateError(
        'Level $number ($name): $fishCount fish on the map but '
        'requiredFish is $requiredFish',
      );
    }

    const allowed = {'#', '.', 'P', 'E', 'F', 'X'};
    for (var y = 0; y < maze.length; y++) {
      for (var x = 0; x < maze[y].length; x++) {
        final symbol = maze[y][x];
        if (!allowed.contains(symbol)) {
          throw StateError(
            'Level $number ($name): invalid symbol "$symbol" at $x,$y',
          );
        }
      }
    }

    if (_count('#') == 0) {
      throw StateError('Level $number ($name): maze has no walls');
    }

    _validateReachability();
    validateFullWalkability();
    validateHazardSafety();
  }

  /// BFS from the spawn: the exit and every fish must be reachable.
  void _validateReachability() {
    final spawn = _find('P')!;
    final seen = List.generate(
      maze.length,
      (y) => List<bool>.filled(maze[y].length, false),
    );

    final queue = <List<int>>[
      [spawn.x, spawn.y],
    ];
    seen[spawn.y][spawn.x] = true;

    const steps = [
      [0, -1],
      [0, 1],
      [-1, 0],
      [1, 0],
    ];

    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      for (final step in steps) {
        final nx = cell[0] + step[0];
        final ny = cell[1] + step[1];
        if (nx < 0 || ny < 0 || ny >= maze.length) continue;
        if (nx >= maze[ny].length) continue;
        if (seen[ny][nx] || maze[ny][nx] == '#') continue;
        seen[ny][nx] = true;
        queue.add([nx, ny]);
      }
    }

    final exit = exitPosition;
    if (!seen[exit.y][exit.x]) {
      throw StateError('Level $number ($name): exit is unreachable');
    }

    for (final fish in fishPositions) {
      if (!seen[fish.y][fish.x]) {
        throw StateError(
          'Level $number ($name): fish at ${fish.x},${fish.y} is unreachable',
        );
      }
    }
  }

  void validateFullWalkability() {
    final spawn = playerStart;

    final queue = <GridPoint>[spawn];
    final visited = <String>{
      '${spawn.x},${spawn.y}',
    };

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      const directions = [
        [0, -1],
        [0, 1],
        [-1, 0],
        [1, 0],
      ];

      for (final direction in directions) {
        final nx = current.x + direction[0];
        final ny = current.y + direction[1];

        if (nx < 0 ||
            ny < 0 ||
            nx >= width ||
            ny >= height) {
          continue;
        }

        if (isWall(nx, ny)) continue;

        final key = '$nx,$ny';

        if (visited.contains(key)) continue;

        visited.add(key);

        queue.add(
          GridPoint(nx, ny),
        );
      }
    }

    var walkableCells = 0;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (!isWall(x, y)) {
          walkableCells++;
        }
      }
    }

    if (visited.length != walkableCells) {
      throw StateError(
        'Level $number ($name): '
        'not every walkable cell is reachable '
        'from the player spawn.',
      );
    }
  }

  void validateHazardSafety() {
    final spawn = playerStart;

    final queue = <GridPoint>[spawn];
    final visited = <String>{
      '${spawn.x},${spawn.y}',
    };

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      const directions = [
        [0, -1],
        [0, 1],
        [-1, 0],
        [1, 0],
      ];

      for (final direction in directions) {
        final nx = current.x + direction[0];
        final ny = current.y + direction[1];

        if (nx < 0 ||
            ny < 0 ||
            nx >= width ||
            ny >= height) {
          continue;
        }

        if (isWall(nx, ny)) continue;
        if (isHazard(nx, ny)) continue;

        final key = '$nx,$ny';

        if (visited.contains(key)) continue;

        visited.add(key);

        queue.add(
          GridPoint(nx, ny),
        );
      }
    }

    if (!visited.contains(
      '${exitPosition.x},${exitPosition.y}',
    )) {
      throw StateError(
        'Level $number ($name): '
        'exit requires stepping on a hazard.',
      );
    }

    for (final fish in fishPositions) {
      if (!visited.contains('${fish.x},${fish.y}')) {
        throw StateError(
          'Level $number ($name): '
          'fish at ${fish.x},${fish.y} requires a hazard.',
        );
      }
    }
  }

  GridPoint? _find(String marker) {
    for (var y = 0; y < maze.length; y++) {
      final x = maze[y].indexOf(marker);
      if (x != -1) return GridPoint(x, y);
    }
    return null;
  }

  int _count(String marker) {
    var total = 0;
    for (final row in maze) {
      total += marker.allMatches(row).length;
    }
    return total;
  }

  int get fishCount {
    int count = 0;
    for (final row in maze) {
      count += 'F'.allMatches(row).length;
    }
    return count;
  }

  int get width => maze.isNotEmpty ? maze.first.length : 0;

  int get height => maze.length;

  bool isWall(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return true;
    return maze[y][x] == '#';
  }

  bool isWalkable(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return false;
    return maze[y][x] != '#';
  }

  GridPoint get playerStart {
    for (int y = 0; y < maze.length; y++) {
      for (int x = 0; x < maze[y].length; x++) {
        if (maze[y][x] == 'P') return GridPoint(x, y);
      }
    }
    return const GridPoint(1, 1);
  }

  GridPoint get exitPosition {
    for (int y = 0; y < maze.length; y++) {
      for (int x = 0; x < maze[y].length; x++) {
        if (maze[y][x] == 'E') return GridPoint(x, y);
      }
    }
    return GridPoint(width - 2, height - 2);
  }

  List<GridPoint> get fishPositions {
    final positions = <GridPoint>[];
    for (int y = 0; y < maze.length; y++) {
      for (int x = 0; x < maze[y].length; x++) {
        if (maze[y][x] == 'F') positions.add(GridPoint(x, y));
      }
    }
    return positions;
  }

  int countFishAtRow(int row) {
    if (row < 0 || row >= maze.length) return 0;
    return 'F'.allMatches(maze[row]).length;
  }

  /// Obstacle cells that cost the cat a heart when stepped on. Hazards sit on
  /// ordinary floor and do not block movement, so reachability is unchanged.
  List<GridPoint> get hazardPositions {
    final positions = <GridPoint>[];
    for (var y = 0; y < maze.length; y++) {
      for (var x = 0; x < maze[y].length; x++) {
        if (maze[y][x] == 'X') positions.add(GridPoint(x, y));
      }
    }
    return positions;
  }

  int get hazardCount => hazardPositions.length;

  bool isHazard(int x, int y) {
    if (y < 0 || y >= maze.length) return false;
    if (x < 0 || x >= maze[y].length) return false;
    return maze[y][x] == 'X';
  }
}
