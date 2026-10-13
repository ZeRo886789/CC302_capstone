class ScoreManager {
  int score = 0;
  int fishCollected = 0;
  int requiredFish = 0;
  int levelNumber = 1;
  Stopwatch stopwatch = Stopwatch()..start();
  bool levelCompleting = false;
  bool _paused = false;

  void reset({required int requiredFish, required int levelNumber}) {
    score = 0;
    fishCollected = 0;
    this.requiredFish = requiredFish;
    this.levelNumber = levelNumber;
    levelCompleting = false;
    _paused = false;
    stopwatch
      ..reset()
      ..start();
  }

  void collectFish() {
    fishCollected++;
    score += 100;
  }

  /// Freezes the level timer while the pause menu is open.
  void pause() {
    if (levelCompleting || _paused) return;
    _paused = true;
    stopwatch.stop();
  }

  /// Resumes the level timer from where it stopped.
  void resume() {
    if (levelCompleting || !_paused) return;
    _paused = false;
    stopwatch.start();
  }

  void completeLevel() {
    if (levelCompleting) return;
    levelCompleting = true;
    score += 500;
    stopwatch.stop();
  }

  bool get canComplete => fishCollected >= requiredFish;

  /// True while the level clock is advancing.
  bool get timerRunning => stopwatch.isRunning;

  String get formattedTime {
    final minutes = stopwatch.elapsed.inMinutes.remainder(60);
    final seconds = stopwatch.elapsed.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get elapsedSeconds => stopwatch.elapsed.inSeconds;
}
