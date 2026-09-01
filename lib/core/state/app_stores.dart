import 'package:sembast/sembast.dart';

import 'app_settings.dart';
import 'movie_library_store.dart';
import 'search_history_store.dart';

/// Aggregates every app store behind one object so `main.dart` performs the
/// async bootstrap once and widgets receive ready-to-use stores.
class AppStores {
  final Database database;
  final AppSettings settings;
  final MovieLibraryStore favorites;
  final MovieLibraryStore viewed;
  final SearchHistoryStore searchHistory;

  AppStores({
    required this.database,
    required this.settings,
    required this.favorites,
    required this.viewed,
    required this.searchHistory,
  });
}
