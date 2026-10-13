// CLI validation script: stdout is the intended output channel.
// ignore_for_file: avoid_print

import 'package:pawquest/game/data/levels.dart';

void main() {
  for (final level in Levels.all) {
    level.validate();
    print(
      'Level ${level.number} (${level.name}): '
      '${level.fishCount} fish, ${level.hazardCount} hazards - OK',
    );
  }

  print('\nAll ${Levels.all.length} levels are valid and beatable!');
}
