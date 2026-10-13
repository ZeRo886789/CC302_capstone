// CLI validation script: stdout is the intended output channel.
// ignore_for_file: avoid_print

import 'dart:collection';

import 'lib/game/data/levels.dart';

const int mazeCols = 15;
const int mazeRows = 21;

bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < mazeCols && y < mazeRows;

List<List<bool>> reachableFrom(String startChar, List<String> maze) {
  final seen = List.generate(
    maze.length,
    (y) => List<bool>.filled(maze[y].length, false),
  );

  var startX = -1;
  var startY = -1;
  for (var y = 0; y < maze.length; y++) {
    final x = maze[y].indexOf(startChar);
    if (x != -1) {
      startX = x;
      startY = y;
      break;
    }
  }
  if (startX == -1) return seen;

  final queue = Queue<List<int>>()..add([startX, startY]);
  seen[startY][startX] = true;

  const dirs = [
    [0, -1],
    [0, 1],
    [-1, 0],
    [1, 0],
  ];

  while (queue.isNotEmpty) {
    final cell = queue.removeFirst();
    for (final d in dirs) {
      final nx = cell[0] + d[0];
      final ny = cell[1] + d[1];
      if (!inBounds(nx, ny)) continue;
      if (ny >= maze.length || nx >= maze[ny].length) continue;
      if (seen[ny][nx]) continue;
      if (maze[ny][nx] == '#') continue;
      seen[ny][nx] = true;
      queue.add([nx, ny]);
    }
  }
  return seen;
}

void main() {
  var errors = 0;

  for (final level in Levels.all) {
    final fishCount = level.fishCount;
    final pCount = level.maze
        .fold(0, (sum, row) => sum + 'P'.allMatches(row).length);
    final eCount = level.maze
        .fold(0, (sum, row) => sum + 'E'.allMatches(row).length);

    if (level.maze.length != mazeRows) {
      print('Level ${level.number}: ${level.maze.length} rows '
          '(expected $mazeRows)');
      errors++;
    }

    for (var i = 0; i < level.maze.length; i++) {
      if (level.maze[i].length != mazeCols) {
        print('Level ${level.number} Row $i: length=${level.maze[i].length} '
            '(expected $mazeCols): "${level.maze[i]}"');
        errors++;
      }
      if (level.maze[i][0] != '#' ||
          level.maze[i][level.maze[i].length - 1] != '#') {
        print('Level ${level.number} Row $i: missing side wall: '
            '"${level.maze[i]}"');
        errors++;
      }
    }
    if (level.maze.first[0] != '#' ||
        level.maze.first[level.maze.first.length - 1] != '#' ||
        level.maze.last[0] != '#' ||
        level.maze.last[level.maze.last.length - 1] != '#') {
      print('Level ${level.number}: missing top/bottom corner walls');
      errors++;
    }

    if (pCount != 1) {
      print('Level ${level.number}: has $pCount players (expected 1)');
      errors++;
    }
    if (eCount != 1) {
      print('Level ${level.number}: has $eCount exits (expected 1)');
      errors++;
    }
    if (fishCount != level.requiredFish) {
      print('Level ${level.number}: has $fishCount fish '
          '(expected ${level.requiredFish})');
      errors++;
    }

    if (pCount == 1) {
      final seen = reachableFrom('P', level.maze);

      var unreachableFish = 0;
      for (final p in level.fishPositions) {
        if (!seen[p.y][p.x]) unreachableFish++;
      }
      if (unreachableFish > 0) {
        print('Level ${level.number}: $unreachableFish fish unreachable '
            'from P');
        errors++;
      }

      final exit = level.exitPosition;
      if (!seen[exit.y][exit.x]) {
        print('Level ${level.number}: exit unreachable from P');
        errors++;
      }
    }

    final status = errors == 0 ? 'OK' : 'ERRORS';
    print('Level ${level.number} (${level.name}): $fishCount fish, '
        '$pCount P, $eCount E - $status');
  }

  if (errors == 0) {
    print('\nAll levels valid and solvable!');
  } else {
    print('\n$errors error(s) found. Fix before running.');
  }
}
