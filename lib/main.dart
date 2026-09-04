import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/db/app_database.dart';
import 'core/network/movie_api_client.dart';
import 'core/state/app_scope.dart';
import 'core/state/app_settings.dart';
import 'core/state/app_stores.dart';
import 'core/state/movie_library_store.dart';
import 'core/state/search_history_store.dart';
import 'core/theme/app_theme.dart' show accentById, buildDarkTheme, buildLightTheme;
import 'core/update/update_service.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/shell/home_shell.dart';
import 'l10n/generated/app_localizations.dart';
import 'widgets/common/window_controls.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // libmpv runtime for the video player (media_kit).
  MediaKit.ensureInitialized();

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

  final update = UpdateService();
  // Background update check: only when the user left auto-update on.
  if (settings.autoUpdate) update.checkForUpdate();

  runApp(FilmifyApp(
    settings: settings,
    stores: stores,
    apiClient: apiClient,
    update: update,
  ));
}

class FilmifyApp extends StatelessWidget {
  const FilmifyApp({
    super.key,
    required this.settings,
    required this.stores,
    required this.apiClient,
    required this.update,
  });

  final AppSettings settings;
  final AppStores stores;
  final MovieApiClient apiClient;
  final UpdateService update;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final accent = accentById(settings.accentColor);
        return MaterialApp(
          title: 'Filmify',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(accent: accent),
          darkTheme: buildDarkTheme(accent: accent),
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Tracks open dialogs so the frameless window buttons can step
          // aside while a dialog's own close button owns the corner.
          navigatorObservers: [DialogVisibilityObserver()],
          // AppScope must live in the builder, not `home`: pushed routes
          // (movie details) are siblings of the home route under the
          // Navigator, so only a builder-level ancestor is visible to them.
          builder: (context, child) => DesktopWindowChrome(
            update: update,
            child: AppScope(
              settings: settings,
              stores: stores,
              apiClient: apiClient,
              update: update,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
          // First run shows the onboarding flow; afterwards go straight to
          // the home shell. Toggling the flag rebuilds this via AnimatedBuilder.
          home: settings.onboardingDone
              ? const HomeShell()
              : const OnboardingPage(),
        );
      },
    );
  }
}
