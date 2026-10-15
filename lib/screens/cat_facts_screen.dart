import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fact.dart';
import '../services/cat_facts_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/fact_card.dart';

import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../game/config/game_colors.dart';

/// Screen displaying a list of cat facts with search, favorites, and delete.
class CatFactsScreen extends StatefulWidget {
  const CatFactsScreen({super.key});

  @override
  State<CatFactsScreen> createState() => _CatFactsScreenState();
}

class _CatFactsScreenState extends State<CatFactsScreen> {
  final CatFactsService _service = CatFactsService();
  List<Fact> _facts = [];
  List<Fact> _displayedFacts = [];
  String _searchQuery = '';
  Set<String> _favoriteFactIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _showFavoritesOnly = false;
  Fact? _lastDeletedFact;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _refreshFacts();
  }

  /// Loads favorite fact IDs from shared preferences.
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites =
        prefs.getStringList('cat_facts_favorites') ?? [];
    setState(() {
      _favoriteFactIds = Set.from(favorites);
    });
  }

  /// Saves favorite fact IDs to shared preferences.
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cat_facts_favorites', _favoriteFactIds.toList());
  }

  /// Toggles a fact's favorite status.
  void _toggleFavorite(Fact fact) {
    setState(() {
      final factId = fact.text; // Using text as ID for simplicity
      if (_favoriteFactIds.contains(factId)) {
        _favoriteFactIds.remove(factId);
      } else {
        _favoriteFactIds.add(factId);
      }
    });
    _saveFavorites();
    _applyFilters();
  }

  /// Refreshes the facts from the API.
  Future<void> _refreshFacts() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final facts = await _service.fetchFacts();
      setState(() {
        _facts = facts;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Applies search and favorites filters.
  void _applyFilters() {
    setState(() {
      _displayedFacts = _facts.where((fact) {
        final matchesSearch = fact.text.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final matchesFavorite = _showFavoritesOnly
            ? _favoriteFactIds.contains(fact.text)
            : true;
        return matchesSearch && matchesFavorite;
      }).toList();
    });
  }

  /// Deletes a fact from the list after confirmation.
  Future<void> _deleteFact(Fact fact) async {
    bool confirmed = await showConfirmDialog(
      context,
      title: 'Delete fact?',
      message: 'This can\'t be undone.',
      preview: fact.text,
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    );
    if (!confirmed) return;

    // Store the fact for possible undo
    setState(() {
      _lastDeletedFact = fact;
      _facts.remove(fact);
      // Remove from favorites if present
      _favoriteFactIds.remove(fact.text);
      _saveFavorites();
      _applyFilters();
    });

    // Show snackbar with undo action
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: GameColors.panelDark,
          content: const Text('Fact deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: GameColors.yellow,
            onPressed: () {
              setState(() {
                if (_lastDeletedFact != null) {
                  _facts.add(_lastDeletedFact!);
                  _saveFavorites();
                  _applyFilters();
                }
                _lastDeletedFact = null;
              });
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        title: Text(
          'CAT FACTS',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: GameColors.yellow,
          ),
        ),
        centerTitle: true,
        backgroundColor: GameColors.panel,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFacts,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'favorites') {
                  _showFavoritesOnly = !_showFavoritesOnly;
                } else if (value == 'clear') {
                  _searchQuery = '';
                }
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'favorites',
                child: Text('Favorites only'),
              ),
              const PopupMenuItem(value: 'clear', child: Text('Clear search')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search facts',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: GameColors.panel,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilters();
                  });
                },
              ),
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: GameColors.yellow,
                          ),
                        ),
                      )
                    : _errorMessage != null
                    ? ErrorState(
                        message: _errorMessage!,
                        onRetry: _refreshFacts,
                      )
                    : _displayedFacts.isEmpty
                    ? EmptyState(
                        message: _showFavoritesOnly
                            ? 'No favorite facts. Tap the heart to add some!'
                            : 'No facts found. Try a different search or refresh.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _displayedFacts.length,
                        itemBuilder: (context, index) {
                          final fact = _displayedFacts[index];
                          return FactCard(
                            fact: fact,
                            isFavorite: _favoriteFactIds.contains(fact.text),
                            onDelete: _deleteFact,
                            onToggleFavorite: _toggleFavorite,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
