/// A record of a completed level adventure.
class HistoryEntry {
  final String id;
  final int level;
  final String levelName;
  final int score;
  final String formattedTime;
  final DateTime date;

  HistoryEntry({
    required this.level,
    required this.levelName,
    required this.score,
    required this.formattedTime,
    required this.date,
    String? id,
  }) : id = id ?? _generateId();

  /// Creates a HistoryEntry from a JSON map.
  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    level: json['level'] as int,
    levelName: json['levelName'] as String,
    score: json['score'] as int,
    formattedTime: json['formattedTime'] as String,
    date: DateTime.parse(json['date'] as String),
    id: json['id'],
  );

  /// Converts the history entry to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
    'levelName': levelName,
    'score': score,
    'formattedTime': formattedTime,
    'date': date.toIso8601String(),
  };

  /// Generates a unique id for a new history entry.
  static String _generateId() {
    // Use microseconds since epoch and a counter to avoid collisions within the same millisecond.
    return '${DateTime.now().microsecondsSinceEpoch}_${_nextId++}';
  }

  static int _nextId = 0;
}
