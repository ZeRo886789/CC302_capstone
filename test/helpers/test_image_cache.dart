import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Seeds Flame's global image cache with lightweight synthetic images for
/// every asset the game loads.
///
/// Under `flutter test` the real `decodeImageFromList` codec is unavailable
/// and, critically, any *second* call to it (or an `await` after one) deadlocks
/// the test event loop. A single `Future.wait` batch of decodes can complete,
/// but sequential awaits cannot.
///
/// The game constructs sprites via `await Sprite.load(path)` during `onLoad`,
/// which would trigger those deadlocking decodes. By pre-populating Flame's
/// cache with [Flame.images.add] entries keyed exactly like the real assets,
/// every `Sprite.load` becomes a cache hit and returns a completed
/// `Future.value` immediately — no codec, no decode, no deadlock.
///
/// The synthetic images are produced with `Picture.toImageSync`, which rasterizes
/// directly on the CPU without any codec involvement.
Future<void> preseedTestSprites() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Flame.images.prefix = 'assets/images/';

  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assetPaths = manifest
      .listAssets()
      .where((p) => p.startsWith('assets/images/'));
  for (final assetPath in assetPaths) {
    final key = assetPath.substring('assets/images/'.length);
    if (Flame.images.containsKey(key)) continue;
    Flame.images.add(key, _syntheticImage(32, 32));
  }
}

ui.Image _syntheticImage(int width, int height) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF888888),
  );
  final picture = recorder.endRecording();
  return picture.toImageSync(width, height);
}
