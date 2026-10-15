import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pawquest/models/fact.dart';

/// Service to fetch cat facts from APIs.
class CatFactsService {
  static const int _timeoutSeconds = 8;
  static const String _primaryApiUrl = 'https://catfact.ninja/facts?limit=20';
  static const String _secondaryApiUrl =
      'https://meowfacts.herokuapp.com/?count=20';

  /// Fetches a list of cat facts from the primary API, falling back to the secondary.
  /// Returns a list of facts, or throws an exception if both APIs fail.
  Future<List<Fact>> fetchFacts() async {
    try {
      return await _fetchFromPrimaryApi();
    } catch (e) {
      try {
        return await _fetchFromSecondaryApi();
      } catch (e2) {
        throw Exception('Both cat facts APIs failed: $e2');
      }
    }
  }

  /// Fetches from the primary API (catfact.ninja).
  Future<List<Fact>> _fetchFromPrimaryApi() async {
    final response = await http
        .get(Uri.parse(_primaryApiUrl))
        .timeout(const Duration(seconds: _timeoutSeconds));
    if (response.statusCode != 200) {
      throw Exception('Primary API failed with status: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = json['data'] as List<dynamic>;
    return data
        .map((e) => Fact.fromCatFactNinja(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches from the secondary API (meowfacts.herokuapp.com).
  Future<List<Fact>> _fetchFromSecondaryApi() async {
    final response = await http
        .get(Uri.parse(_secondaryApiUrl))
        .timeout(const Duration(seconds: _timeoutSeconds));
    if (response.statusCode != 200) {
      throw Exception(
        'Secondary API failed with status: ${response.statusCode}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = json['data'] as List<dynamic>;
    return data.map((e) => Fact.fromMeowFacts(e as String)).toList();
  }
}
