import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cat_data.dart';
import '../data/levels.dart';
import '../../models/history_entry.dart';

class SaveManager {
  SaveManager._();

  static const String _highestLevelKey = 'highest_unlocked_level';
  static const String _lunaOwnedKey = 'luna_owned';
  static const String _mochiOwnedKey = 'mochi_owned';
  static const String _selectedCatKey = 'selected_cat';
  static const String _highScoreKey = 'high_score';
  static const String _pawCoinsKey = 'paw_coins';
  static const String _completedLevelsKey = 'completed_levels';
  static const String _adventureHistoryKey = 'adventure_history';

  /// Kuro is the default protagonist, so a fresh save always has him unlocked.
  static const String defaultCat = 'kuro';

  static Future<GameState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final state = GameState(
      highestUnlockedLevel: prefs.getInt(_highestLevelKey) ?? 1,
      lunaOwned: prefs.getBool(_lunaOwnedKey) ?? false,
      mochiOwned: prefs.getBool(_mochiOwnedKey) ?? false,
      selectedCat: prefs.getString(_selectedCatKey) ?? SaveManager.defaultCat,
      highScore: prefs.getInt(_highScoreKey) ?? 0,
      pawCoins: prefs.getInt(_pawCoinsKey) ?? 0,
      completedLevels: _readCompletedLevels(prefs),
      adventureHistory: _readAdventureHistory(prefs),
    );

    // A save written by an older build may name a cat that is now locked.
    // Fall back to the default so the player never starts as a locked cat.
    if (!state.canSelectCat(state.selectedCat)) {
      state.selectedCat = SaveManager.defaultCat;
      await save(state);
    }

    return state;
  }

  static Set<int> _readCompletedLevels(SharedPreferences prefs) {
    final raw = prefs.getString(_completedLevelsKey);
    if (raw == null || raw.isEmpty) return {};
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toSet();
  }

  static List<HistoryEntry> _readAdventureHistory(SharedPreferences prefs) {
    final raw = prefs.getString(_adventureHistoryKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highestLevelKey, state.highestUnlockedLevel);
    await prefs.setBool(_lunaOwnedKey, state.lunaOwned);
    await prefs.setBool(_mochiOwnedKey, state.mochiOwned);
    await prefs.setString(_selectedCatKey, state.selectedCat);
    await prefs.setInt(_highScoreKey, state.highScore);
    await prefs.setInt(_pawCoinsKey, state.pawCoins);
    await prefs.setString(
      _completedLevelsKey,
      state.completedLevels.map((e) => e.toString()).join(','),
    );
    await prefs.setString(
      _adventureHistoryKey,
      jsonEncode(state.adventureHistory.map((e) => e.toJson()).toList()),
    );
  }

  /// Wipes all progression, returning the player to a fresh save.
  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_highestLevelKey);
    await prefs.remove(_lunaOwnedKey);
    await prefs.remove(_mochiOwnedKey);
    await prefs.remove(_selectedCatKey);
    await prefs.remove(_highScoreKey);
    await prefs.remove(_pawCoinsKey);
    await prefs.remove(_completedLevelsKey);
    await prefs.remove(_adventureHistoryKey);
  }

  /// Loads the adventure history from shared preferences.
  /// Assigns a fresh unique id to any old entries missing an id and re-saves.
  static Future<List<HistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_adventureHistoryKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    List<HistoryEntry> history = decoded
        .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    // Check if any entry had a missing id in the JSON (so we assigned a new one)
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    bool needsSave = false;
    for (final map in jsonList) {
      if (map is! Map<String, dynamic> || !map.containsKey('id')) {
        needsSave = true;
        break;
      }
    }
    if (needsSave) {
      await saveHistory(history);
    }
    return history;
  }

  /// Saves the given adventure history to shared preferences.
  static Future<void> saveHistory(List<HistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _adventureHistoryKey,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }

  /// Adds a history entry to the adventure history.
  static Future<void> addHistoryEntry(HistoryEntry entry) async {
    final history = await loadHistory();
    history.add(entry);
    await saveHistory(history);
  }

  /// Deletes the history entry with the given id from the adventure history.
  static Future<void> deleteHistoryEntryById(String id) async {
    final history = await loadHistory();
    history.removeWhere((entry) => entry.id == id);
    await saveHistory(history);
  }
}

/// Authoritative player progression model.
///
/// The three cat states are kept distinct:
///
/// LOCKED   — level requirement not yet met (catIsAvailable returns false).
/// AVAILABLE — level requirement met, cat can be purchased (catIsAvailable
///             returns true, isCatUnlocked returns false).
/// OWNED    — purchased (isCatUnlocked returns true).
///
/// Buying a cat is an atomic transaction inside [buyCat]; UI code must never
/// modify ownership or coins directly.
class GameState extends ChangeNotifier {
  static int get maxLevel => Levels.all.length;

  static int _clampLevel(int level) => level.clamp(1, maxLevel).toInt();

  int _highestUnlockedLevel;
  bool _lunaOwned;
  bool _mochiOwned;
  String _selectedCat;
  int _highScore;
  int _pawCoins;

  /// Levels the player has cleared at least once. Drives the first-clear
  /// Paw Coin bonus and cat availability.
  final Set<int> _completedLevels;
  final List<HistoryEntry> _adventureHistory;

  /// Resolves which cat the player may actually select. If the requested cat
  /// is not both owned and available (level requirement met), falls back to
  /// the default cat (Kuro). This prevents stale save files from leaving the
  /// player on a cat they cannot actually use.
  static String _resolveSelectedCat(
    String? selectedCat,
    bool lunaOwned,
    bool mochiOwned,
    Set<int> completedLevels,
  ) {
    final cat = selectedCat ?? SaveManager.defaultCat;
    // Kuro is always owned and available (unlockLevel = 0).
    if (cat == 'kuro') return cat;
    // Luna / Mochi require both ownership and level completion.
    final catData = CatSkins.byName(cat);
    final owned = catData.name == 'luna'
        ? lunaOwned
        : catData.name == 'mochi'
        ? mochiOwned
        : false;
    final available =
        catData.unlockLevel <= 0 ||
        completedLevels.contains(catData.unlockLevel);
    return (owned && available) ? cat : SaveManager.defaultCat;
  }

  GameState({
    int highestUnlockedLevel = 1,
    bool lunaOwned = false,
    bool mochiOwned = false,
    String selectedCat = SaveManager.defaultCat,
    int highScore = 0,
    int pawCoins = 0,
    Set<int>? completedLevels,
    List<HistoryEntry>? adventureHistory,
  }) : _completedLevels = completedLevels ?? {},
       _adventureHistory = adventureHistory ?? [],
       _highestUnlockedLevel = _clampLevel(highestUnlockedLevel),
       _selectedCat = _resolveSelectedCat(
         selectedCat,
         lunaOwned,
         mochiOwned,
         completedLevels ?? {},
       ),
       _lunaOwned = lunaOwned,
       _mochiOwned = mochiOwned,
       // ignore: prefer_initializing_formals
       _highScore = highScore,
       // ignore: prefer_initializing_formals
       _pawCoins = pawCoins;

  // ------------------------------------------------------------------
  // Ownership helpers
  // ------------------------------------------------------------------

  /// Returns true when the cat has been purchased.
  ///
  /// Kuro is always owned on a fresh save; Luna and Mochi must be bought.
  bool isCatOwned(String catName) {
    if (catName == 'kuro') return true;
    if (catName == 'luna') return _lunaOwned;
    if (catName == 'mochi') return _mochiOwned;
    return false;
  }

  /// Alias for [isCatOwned], used by the Shop UI which historically called
  /// `isCatUnlocked`. Both names describe the same concept: whether the player
  /// has purchased the cat.
  bool isCatUnlocked(String catName) => isCatOwned(catName);

  /// Returns true when the cat's level requirement has been met, making it
  /// purchasable. This is independent of whether the cat has been bought.
  bool catIsAvailable(String catName) {
    final cat = CatSkins.byName(catName);
    if (cat.unlockLevel <= 0) return true;
    return _completedLevels.contains(cat.unlockLevel);
  }

  /// Returns true when the cat is both owned and available.
  bool canSelectCat(String catName) =>
      isCatOwned(catName) && catIsAvailable(catName);

  /// Convenience getters for UI.
  bool get lunaOwned => _lunaOwned;
  bool get mochiOwned => _mochiOwned;
  bool get kuroOwned => true;
  bool get lunaAvailable => catIsAvailable('luna');
  bool get mochiAvailable => catIsAvailable('mochi');
  bool get kuroAvailable => true;

  /// Number of purchased cats.
  int get ownedCatCount => (lunaOwned ? 1 : 0) + (mochiOwned ? 1 : 0) + 1;

  /// Alias kept for callers that historically used `unlockedCatCount`.
  /// Semantically identical to [ownedCatCount].
  int get unlockedCatCount => ownedCatCount;

  // ------------------------------------------------------------------
  // Level progression
  // ------------------------------------------------------------------

  int get highestUnlockedLevel => _highestUnlockedLevel;

  set highestUnlockedLevel(int value) {
    final capped = _clampLevel(value);
    if (capped == _highestUnlockedLevel) return;
    _highestUnlockedLevel = capped;
    notifyListeners();
  }

  bool isLevelUnlocked(int level) {
    return level >= 1 && level <= _highestUnlockedLevel && level <= maxLevel;
  }

  void unlockLevel(int level) {
    final cappedLevel = _clampLevel(level);
    if (cappedLevel > _highestUnlockedLevel) {
      _highestUnlockedLevel = cappedLevel;
      notifyListeners();
    }
  }

  /// Backwards-compatible alias for callers that mean "unlock up to [level]".
  void updateLevelUnlock(int level) => unlockLevel(level);

  /// Records that [completedLevel] was cleared, unlocks the next level, and
  /// awards the first-clear Paw Coin bonus exactly once.
  void onLevelCompleted(int completedLevel) {
    final level = _clampLevel(completedLevel);
    final isFirstClear = !_completedLevels.contains(level);
    _completedLevels.add(level);
    unlockLevel(level + 1);
    if (isFirstClear) {
      _pawCoins += 50;
      notifyListeners();
    }
  }

  /// Records a completed level in the adventure history.
  void addAdventureHistoryEntry(HistoryEntry entry) {
    _adventureHistory.add(entry);
  }

  // ------------------------------------------------------------------
  // Cat selection & purchase
  // ------------------------------------------------------------------

  /// The currently selected cat. The setter refuses names that are not
  /// selectable (not owned or not available) and notifies listeners.
  String get selectedCat => _selectedCat;

  set selectedCat(String value) {
    if (value == _selectedCat) return;
    if (!canSelectCat(value)) return;
    _selectedCat = value;
    notifyListeners();
  }

  /// Purchases the named cat. Returns true only if the transaction succeeded;
  /// a failed purchase leaves coins, ownership, and selection unchanged.
  bool buyCat(String catName) {
    final cat = CatSkins.byName(catName);

    // 1. The cat must exist (not the default fallback).
    if (cat.name != catName) return false;

    // 2. Not already owned.
    if (isCatOwned(catName)) return false;

    // 3. Required level must be completed (cat is available).
    if (!catIsAvailable(catName)) return false;

    // 4. Enough Paw Coins.
    if (_pawCoins < cat.price) return false;

    // 5-6. Deduct exact price and mark ownership.
    _pawCoins -= cat.price;
    if (catName == 'luna') _lunaOwned = true;
    if (catName == 'mochi') _mochiOwned = true;

    // 7. Notify listeners so the Shop / Cat Select UI rebuilds.
    notifyListeners();
    // 8. Success.
    return true;
  }

  /// Directly marks a cat as owned. Used by save-migration codepaths only.
  void unlockCat(String catName) {
    if (catName == 'luna') _lunaOwned = true;
    if (catName == 'mochi') _mochiOwned = true;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Score & currency
  // ------------------------------------------------------------------

  int get highScore => _highScore;

  void addScore(int points) {
    if (points > _highScore) {
      _highScore = points;
      notifyListeners();
    }
  }

  int get pawCoins => _pawCoins;

  set pawCoins(int value) {
    if (value == _pawCoins) return;
    _pawCoins = value;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Serialization
  // ------------------------------------------------------------------

  Set<int> get completedLevels => Set.unmodifiable(_completedLevels);
  List<HistoryEntry> get adventureHistory =>
      List.unmodifiable(_adventureHistory);

  Map<String, dynamic> toJson() => {
    'highestUnlockedLevel': _highestUnlockedLevel,
    'lunaOwned': _lunaOwned,
    'mochiOwned': _mochiOwned,
    'selectedCat': _selectedCat,
    'highScore': _highScore,
    'pawCoins': _pawCoins,
    'completedLevels': _completedLevels.toList()..sort(),
    'adventureHistory': _adventureHistory.map((e) => e.toJson()).toList(),
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final rawCompleted = json['completedLevels'];
    final completed = rawCompleted is List
        ? rawCompleted.map((e) => e as int).toSet()
        : <int>{};
    final rawHistory = json['adventureHistory'];
    final history = rawHistory is List
        ? rawHistory
              .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList()
        : <HistoryEntry>[];
    return GameState(
      highestUnlockedLevel: json['highestUnlockedLevel'] as int? ?? 1,
      lunaOwned: json['lunaOwned'] as bool? ?? false,
      mochiOwned: json['mochiOwned'] as bool? ?? false,
      selectedCat: json['selectedCat'] as String? ?? SaveManager.defaultCat,
      highScore: json['highScore'] as int? ?? 0,
      pawCoins: json['pawCoins'] as int? ?? 0,
      completedLevels: completed,
      adventureHistory: history,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
