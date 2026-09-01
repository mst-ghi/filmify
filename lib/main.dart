import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/db/app_database.dart';
import 'core/network/movie_api_client.dart';
import 'core/state/app_scope.dart';
import 'core/state/app_settings.dart';
import 'core/state/app_stores.dart';
import 'core/state/movie_library_store.dart';
import 'core/state/search_history_store.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/home_shell.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final db = await openAppDatabase();

  final settings = AppSettings(prefs);
  final stores = AppStores(
    database: db,
    settings: settings,
    favorites: MovieLibraryStore(db, storeName: 'favorites'),
    viewed: MovieLibraryStore(db, storeName: 'viewed'),
    searchHistory: SearchHistoryStore(db),
  );
  await stores.searchHistory.load();

  final apiClient = MovieApiClient(
    apiKey: () {
      final custom = settings.apiKey;
      return custom.isEmpty ? MovieApiClient.defaultApiKey : custom;
    },
  );

  runApp(FilmifyApp(settings: settings, stores: stores, apiClient: apiClient));
}

class FilmifyApp extends StatelessWidget {
  const FilmifyApp({
    super.key,
    required this.settings,
    required this.stores,
    required this.apiClient,
  });

  final AppSettings settings;
  final AppStores stores;
  final MovieApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Filmify',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppScope(
            settings: settings,
            stores: stores,
            apiClient: apiClient,
            child: const HomeShell(),
          ),
        );
      },
    );
  }
}
