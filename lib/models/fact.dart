/// A single cat fact.
class Fact {
  final String text;
  final int length;

  const Fact({required this.text, required this.length});

  /// Creates a Fact from the primary API (catfact.ninja) JSON.
  factory Fact.fromCatFactNinja(Map<String, dynamic> json) =>
      Fact(text: json['fact'] as String, length: json['length'] as int);

  /// Creates a Fact from the secondary API (meowfacts.herokuapp.com) JSON.
  /// The secondary API returns a list of strings, so we need to know the index.
  /// This factory is not used directly; the service handles the conversion.
  factory Fact.fromMeowFacts(String text) =>
      Fact(text: text, length: text.length);

  /// Converts the fact to a JSON-like map for potential caching.
  Map<String, dynamic> toJson() => {'text': text, 'length': length};
}
