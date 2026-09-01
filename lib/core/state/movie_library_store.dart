import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import '../models/movie.dart';

/// ChangeNotifier store over a sembast record store keyed by movie id.
///
/// State updates are synchronous (instant UI feedback); persistence happens
/// in the background without blocking callers.
class MovieLibraryStore extends ChangeNotifier {
  final String storeName;
  final Database _db;
  final StoreRef<String, Map<String, dynamic>> _store;

  List<Movie> _items = const [];
  Set<int> _ids = const {};
  bool _loaded = false;

  MovieLibraryStore(this._db, {required this.storeName})
      : _store = stringMapStoreFactory.store(storeName) {
    _load();
  }

  /// Newest-saved first once loaded; empty until then.
  List<Movie> get items {
    if (!_loaded) return const [];
    return List.unmodifiable(_items);
  }

  bool isSaved(int movieId) => _ids.contains(movieId);

  bool get loaded => _loaded;

  Future<void> _load() async {
    final snapshots = await _store.find(_db);
    final loaded = <(Movie, DateTime)>[];
    for (final snapshot in snapshots) {
      try {
        final movie = Movie.fromSnapshot(snapshot.value);
        loaded.add((movie, _parseSavedAt(snapshot.value['savedAt'])));
      } catch (_) {
        // Corrupt record: drop it rather than break the library.
        await _store.record(snapshot.key).delete(_db);
      }
    }
    // Newest-saved first.
    loaded.sort((a, b) => b.$2.compareTo(a.$2));
    _items = loaded.map((entry) => entry.$1).toList();
    _ids = _items.map((movie) => movie.id).toSet();
    _loaded = true;
    notifyListeners();
  }

  static DateTime _parseSavedAt(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime(1970);
    return DateTime(1970);
  }

  void add(Movie movie) {
    if (_ids.contains(movie.id)) return;
    _items = [movie, ..._items];
    _ids = {..._ids, movie.id};
    notifyListeners();
    unawaited(_store.record(movie.id.toString()).put(
          _db,
          movie.toSnapshot(),
        ));
  }

  void remove(int movieId) {
    if (!_ids.contains(movieId)) return;
    _items = List.of(_items)..removeWhere((movie) => movie.id == movieId);
    _ids = {..._ids}..remove(movieId);
    notifyListeners();
    unawaited(_store.record(movieId.toString()).delete(_db));
  }

  /// Returns true when the movie is saved after the call.
  bool toggle(Movie movie) {
    if (isSaved(movie.id)) {
      remove(movie.id);
      return false;
    }
    add(movie);
    return true;
  }

  Future<void> clear() async {
    await _store.delete(_db);
    await _load();
  }
}
