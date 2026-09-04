import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/models/movie.dart';
import '../../core/network/movie_api_client.dart';

/// Load-more state machine shared by Home (paged listing) and Search.
class PagedMovies {
  PagedMovies({required this.filter});

  /// One of [MovieApiClient.filters].
  final String filter;

  final List<Movie> movies = [];
  int _nextPage = 0; // upstream pages are 0-based
  bool _loading = false;
  bool _exhausted = false;
  Object? _error;

  bool get loading => _loading;
  bool get exhausted => _exhausted;
  Object? get error => _error;
  bool get hasError => _error != null;

  /// First load or filter switch; clears everything.
  Future<void> reload({
    required MovieApiClient api,
    required VoidCallback onChanged,
  }) async {
    _nextPage = 0;
    _exhausted = false;
    _error = null;
    movies.clear();
    await _fetchPage(api: api, onChanged: onChanged);
  }

  /// Appends the next page; no-op while loading or exhausted.
  Future<void> loadMore({
    required MovieApiClient api,
    required VoidCallback onChanged,
  }) async {
    if (_loading || _exhausted) return;
    await _fetchPage(api: api, onChanged: onChanged);
  }

  Future<void> _fetchPage({
    required MovieApiClient api,
    required VoidCallback onChanged,
  }) async {
    _loading = true;
    _error = null;
    onChanged();
    try {
      final page = await api.list(filter: filter, page: _nextPage);
      // Keep only movies with at least one downloadable source.
      final withSources = page.where((m) => m.hasDownloadSources);
      // Dedupe: upstream pages occasionally repeat items across pages.
      final known = movies.map((m) => m.id).toSet();
      movies.addAll(withSources.where((m) => known.add(m.id)));
      _nextPage += 1;
      if (page.isEmpty) _exhausted = true;
    } on ApiException catch (error) {
      _error = error;
    } finally {
      _loading = false;
      onChanged();
    }
  }
}

/// One-shot search run: fires the query, exposes loading/error/result state.
class SearchRun extends ChangeNotifier {
  SearchRun(this._api);

  final MovieApiClient _api;

  List<Movie> results = const [];
  bool loading = false;
  Object? error;
  String query = '';

  Future<void> run(String rawQuery) async {
    query = rawQuery;
    loading = true;
    error = null;
    notifyListeners();
    try {
      results = await _api.search(rawQuery);
    } on ApiException catch (e) {
      error = e;
      results = const [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void reset() {
    results = const [];
    error = null;
    loading = false;
    notifyListeners();
  }
}
