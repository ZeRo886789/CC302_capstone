class CatData {
  const CatData({
    required this.name,
    required this.assetFolder,
    required this.unlockLevel,
    required this.price,
  });

  final String name;
  final String assetFolder;

  /// Level that must be completed before this cat becomes available for purchase.
  /// 0 = available from start (Kuro).
  final int unlockLevel;

  /// Paw Coins required to purchase this cat. 0 = free (Kuro).
  final int price;

  /// Human-readable unlock requirement, shown when a cat is still locked.
  String get requirementText =>
      unlockLevel <= 0 ? 'AVAILABLE' : 'COMPLETE LEVEL $unlockLevel';
}

/// The three playable cats with proper progression.
class CatSkins {
  CatSkins._();

  /// Display order on the cat select screen.
  static const List<String> names = ['kuro', 'luna', 'mochi'];

  static const CatData kuro = CatData(
    name: 'kuro',
    assetFolder: 'kuro',
    unlockLevel: 0,
    price: 0,
  );

  static const CatData luna = CatData(
    name: 'luna',
    assetFolder: 'luna',
    unlockLevel: 2,
    price: 250,
  );

  static const CatData mochi = CatData(
    name: 'mochi',
    assetFolder: 'mochi',
    unlockLevel: 4,
    price: 500,
  );

  static List<CatData> all() => [kuro, luna, mochi];

  static CatData fromIndex(int index) {
    switch (index) {
      case 1:
        return luna;
      case 2:
        return mochi;
      default:
        return kuro;
    }
  }

  static CatData byName(String name) {
    for (final cat in all()) {
      if (cat.name == name) return cat;
    }
    return kuro;
  }
}
