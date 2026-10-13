import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/game/systems/save_manager.dart';
import 'package:pawquest/game/components/player.dart';
import 'package:pawquest/screens/cat_select.dart';
import 'package:pawquest/screens/game_screen.dart';
import 'package:pawquest/screens/level_select.dart';
import 'package:pawquest/screens/main_menu.dart';
import 'package:pawquest/screens/pause_screen.dart';
import 'package:pawquest/screens/settings_screen.dart';
import 'package:pawquest/widgets/mobile_dpad.dart';
import 'package:pawquest/widgets/pixel_text.dart';

import 'helpers/test_image_cache.dart';

/// Viewport sizes from the target device list, plus desktop Chrome.
const viewports = <String, Size>{
  '360x800': Size(360, 800),
  '375x812': Size(375, 812),
  '390x844': Size(390, 844),
  '412x915': Size(412, 915),
  '430x932': Size(430, 932),
  '1280x720': Size(1280, 720),
  '1366x768': Size(1366, 768),
  '1440x900': Size(1440, 900),
  '1920x1080': Size(1920, 1080),
  'narrow 320x568': Size(320, 568),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(preseedTestSprites);

  setUp(() {
    SharedPreferencesTestValues();
  });

  for (final entry in viewports.entries) {
    final label = entry.key;
    final size = entry.value;

    testWidgets('MainMenuScreen has no overflow at $label', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: MainMenuScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('CatSelectScreen has no overflow at $label', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: CatSelectScreen(savedState: GameState()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('LevelSelectScreen has no overflow at $label', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: LevelSelectScreen(savedState: GameState()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('GameScreen has no overflow at $label', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            selectedCat: 'mochi',
            initialLevel: 1,
            savedState: GameState(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  }

  group('settings and pause', () {
    testWidgets('SettingsScreen has no overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('RESET PROGRESS'), findsOneWidget);
      expect(find.text('BACK'), findsOneWidget);
    });
  });

  group('cat select flow', () {
    testWidgets('Continue starts a fresh campaign at level 1', (tester) async {
      final state = GameState(
        highestUnlockedLevel: 5,
        lunaOwned: true,
        mochiOwned: true,
        selectedCat: 'mochi',
        completedLevels: {1, 2, 3, 4, 5},
      );

      await tester.pumpWidget(
        MaterialApp(home: CatSelectScreen(savedState: state)),
      );

      await tester.tap(find.text('CONTINUE'));
      await tester.pump(const Duration(milliseconds: 200));

      final screenFinder =
          find.byType(GameScreen, skipOffstage: false);
      expect(screenFinder, findsOneWidget);
      final screen = tester.widget<GameScreen>(screenFinder);
      expect(screen.initialLevel, 1);
      expect(screen.selectedCat, 'mochi');
      expect(tester.takeException(), isNull);
    });

    testWidgets('locked cats cannot be selected on a fresh save', (tester) async {
      final state = GameState();

      await tester.pumpWidget(
        MaterialApp(home: CatSelectScreen(savedState: state)),
      );

      // Kuro is the default and is owned.
      expect(find.text('SELECTED'), findsNWidgets(2));

      // Tapping Luna does nothing — it is locked.
      final lunaCard = find.ancestor(
        of: find.text('LUNA'),
        matching: find.byType(GestureDetector),
      ).first;
      await tester.tap(lunaCard);
      await tester.pump();

      expect(state.selectedCat, 'kuro',
          reason: 'locked cat selection must be silently rejected');
      expect(find.textContaining('LOCKED'), findsWidgets,
          reason: 'locked label must be visible');
    });

    testWidgets('owned cats can be selected and selection persists',
        (tester) async {
      final state = GameState(
        lunaOwned: true,
        mochiOwned: true,
        completedLevels: {1, 2, 3, 4, 5},
      );
      // Select Luna via setter (both owned and available).
      state.selectedCat = 'luna';

      await tester.pumpWidget(
        MaterialApp(home: CatSelectScreen(savedState: state)),
      );

      expect(state.selectedCat, 'luna');
      expect(find.text('SELECTED'), findsNWidgets(2));

      // Tap Mochi — should update the selection.
      final mochiCard = find.ancestor(
        of: find.text('MOCHI'),
        matching: find.byType(GestureDetector),
      ).first;
      await tester.tap(mochiCard);
      await tester.pump();

      expect(state.selectedCat, 'mochi');

      // Force a rebuild — selection must persist.
      await tester.pump();
      expect(state.selectedCat, 'mochi');
    });

    testWidgets('all three cat cards are present with correct lock states',
        (tester) async {
      final state = GameState();

      await tester.pumpWidget(
        MaterialApp(home: CatSelectScreen(savedState: state)),
      );

      // All three cards exist.
      expect(
        find.ancestor(
          of: find.text('KURO'),
          matching: find.byType(GestureDetector),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('LUNA'),
          matching: find.byType(GestureDetector),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('MOCHI'),
          matching: find.byType(GestureDetector),
        ),
        findsOneWidget,
      );

      // Kuro is owned (no lock), Luna and Mochi are locked.
      expect(find.textContaining('LOCKED'), findsWidgets,
          reason: 'at least Luna and Mochi should show LOCKED');
      expect(find.textContaining('SELECTED'), findsWidgets,
          reason: 'Kuro card should show SELECTED');
    });
  });

  group('pause menu', () {
    testWidgets('offers every option required by the spec', (tester) async {
      var resumed = 0;
      var retried = 0;
      var toLevelSelect = 0;
      var toMenu = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseScreen(
              onResume: () => resumed++,
              onRetry: () => retried++,
              onLevelSelect: () => toLevelSelect++,
              onMainMenu: () => toMenu++,
            ),
          ),
        ),
      );

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('RESUME'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.text('LEVEL SELECT'), findsOneWidget);
      expect(find.text('MAIN MENU'), findsOneWidget);

      await tester.tap(find.text('LEVEL SELECT'));
      await tester.pump();
      expect(toLevelSelect, 1);
      expect(tester.takeException(), isNull);
      expect(resumed, 0);
      expect(retried, 0);
      expect(toMenu, 0);
    });
  });

  group('D-pad', () {
    testWidgets('renders all four direction buttons plus a pause center pad',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MobileDPad(onDirectionPressed: (_) {})),
        ),
      );

      for (final label in ['UP', 'DOWN', 'LEFT', 'RIGHT', 'PAUSE']) {
        expect(find.bySemanticsLabel(label), findsOneWidget,
            reason: '$label button must exist');
      }
    });

    testWidgets('hold path drives held-direction and release callbacks',
        (tester) async {
      final held = <PlayerDirection>[];
      var released = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileDPad(
              onDirectionPressed: (_) {},
              onDirectionHeld: held.add,
              onDirectionReleased: (_) => released++,
            ),
          ),
        ),
      );

      for (final label in ['UP', 'DOWN', 'LEFT', 'RIGHT']) {
        await tester.tap(find.bySemanticsLabel(label));
        await tester.pump();
      }

      expect(held.toSet(), PlayerDirection.values.toSet(),
          reason: 'all four directions reach movePlayer');
      expect(released, 4, reason: 'release clears the held direction');
    });

    testWidgets('tap path drives the movement callback for all four',
        (tester) async {
      final fired = <PlayerDirection>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MobileDPad(onDirectionPressed: fired.add)),
        ),
      );

      for (final label in ['UP', 'DOWN', 'LEFT', 'RIGHT']) {
        await tester.tap(find.bySemanticsLabel(label));
        await tester.pump();
      }

      expect(fired.toSet(), PlayerDirection.values.toSet());
    });

    testWidgets('DOWN specifically calls the movement callback',
        (tester) async {
      final fired = <PlayerDirection>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MobileDPad(onDirectionPressed: fired.add)),
        ),
      );

      await tester.tap(find.bySemanticsLabel('DOWN'));
      await tester.pump();

      expect(fired, contains(PlayerDirection.down));
    });

    testWidgets('center pad invokes onPause', (tester) async {
      var pauses = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileDPad(
              onDirectionPressed: (_) {},
              onPause: () => pauses++,
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('PAUSE'));
      await tester.pump();

      expect(pauses, 1);
    });
  });

    group('PixelText', () {
      testWidgets('maps characters to the supplied glyph sheets',
          (tester) async {
        expect(
          PixelText.glyphFor('0'),
          'assets/images/ui/font/digits/0.png',
        );
        expect(
          PixelText.glyphFor('9'),
          'assets/images/ui/font/digits/9.png',
        );
        expect(
          PixelText.glyphFor('a'),
          'assets/images/ui/font/letters/A.png',
          reason: 'lowercase maps to the uppercase sheet',
        );
        expect(PixelText.glyphFor(' '), isNull);
        expect(PixelText.glyphFor('!'), isNull);
      });

      testWidgets('renders every character of a string', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: PixelText('SCORE 4200', height: 12)),
          ),
        );
        // 9 characters, 8 gaps between them.
        expect(find.byType(Image), findsNWidgets(9));
        expect(tester.takeException(), isNull);
      });

      testWidgets('draws a shadow copy when a shadow colour is given',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PixelText('PAW', height: 12, shadowColor: Colors.black),
            ),
          ),
        );
        expect(find.byType(Image), findsNWidgets(6));
      });
    });
}

class SharedPreferencesTestValues {
  SharedPreferencesTestValues();
}
