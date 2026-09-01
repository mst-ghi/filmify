# Filmify — Design Document

Date: 2026-09-01
Author: Mostafa Gholami (with ZCode)
Status: Approved-by-brief (spec provided directly by user; technical choices delegated)

## 1. Purpose

Filmify is a cross-platform (Android, Linux, Windows) movie browsing and download-link
app, the successor to the `a-movie` project. Where a-movie was a Go proxy + Vue SPA,
Filmify is a standalone Flutter client that talks to the same upstream movie API
directly, with a modern bilingual UI, local persistence, and GitHub-based builds.

## 2. Feature Set (from the brief + improvements)

Carried over from a-movie:
- Browse movies with sort filters (`created` (latest), `imdb`, `year`) and infinite pagination.
- Search by title.
- Movie details: poster, cover, title, year, IMDb rating, user rating, duration,
  genres, countries, description, per-quality download sources.
- Direct download links compatible with mainstream download managers (IDM, FDM, ADM,
  aria2, etc.) — links are plain HTTPS URLs; the app offers open-with / copy / share.

New in Filmify:
- Favorites stored locally (SQLite), working offline; each favorite keeps the full
  movie JSON so details can be re-opened without network.
- "Viewed" tracking: opening a movie's details marks it as seen; every card shows a
  green "seen" badge, so the user knows they already checked that movie.
- Search history (with recent-search chips).
- Offline fallback: details of previously viewed/favorited movies render from cache.
- Bilingual English/Persian with automatic RTL/LTR.
- Dark/light/system themes with orange+green brand palette.
- Configurable upstream base URL and API key (defaults baked in).
- GitHub Actions builds & releases with version sync (see §8).

## 3. Tech Stack & Why

| Choice | Decision | Rationale |
|---|---|---|
| Framework | Flutter 3.44 stable (Dart 3.12) | Single codebase for Android/Linux/Windows; user preference. |
| State management | `provider` + `ChangeNotifier` | Small app, no codegen, easy to read. |
| HTTP | `http` package | Only two GET endpoints; no need for dio. |
| Database | `sqflite` + `sqflite_common_ffi` + `sqlite3_flutter_libs` | Real SQLite as the user suggested; ffi variant covers Linux/Windows. |
| Settings | `shared_preferences` | Key-value settings (theme, locale, API config). |
| Images | `cached_network_image` | Poster caching on all platforms. |
| Links | `url_launcher` + `share_plus` | Open / share download links. |
| i18n | `flutter_localizations` + `gen-l10n` (ARB) | Standard, compile-safe, RTL aware. |
| Font | Vazirmatn (bundled TTF) | Excellent Persian + Latin rendering, open source. |
| Version/about | `package_info_plus` | Show version in Settings/About. |

Deliberately excluded: tests (per user request, revisit later), CI test job,
dio/flutter_animate (hand-rolled animations keep deps lean).

## 4. Architecture

Layered feature-first structure:

```
lib/
  main.dart               # bootstrap: DB init, ffi factory, providers, runApp
  app.dart                # MaterialApp: theme + locale wiring, home shell
  core/
    config/app_config.dart     # default API URL/key; read/write overrides
    db/app_database.dart       # SQLite open + migrations; favorites/viewed/history
    network/movie_api.dart     # upstream client (list, search), typed errors
    theme/app_theme.dart       # light+dark ColorSchemes, typography, gradients
    utils/formatters.dart      # localized numbers, duration, date
  features/
    movies/
      models/movie.dart        # Movie + Source + fromJson (matches upstream tags)
      providers/movies_provider.dart   # per-filter pagination, search, errors
      pages/home_page.dart
      pages/movie_details_page.dart
      widgets/ (movie_card, shimmer_grid, source_tile, rating_badge, …)
    favorites/favorites_provider.dart, favorites_page.dart
    viewed/viewed_provider.dart
    search/search_page.dart (+ search history access)
    settings/settings_provider.dart, settings_page.dart
  widgets/common/          # AppLogo, gradient background, empty states, nav shell
```

Navigation: adaptive shell — `NavigationBar` on phones, `NavigationRail` on wide
screens (Linux/Windows desktop) — 4 destinations: Home, Search, Favorites, Settings.
Details is pushed as a full-screen route with hero poster transition.

### Data flow

- `MoviesProvider` → `MovieApi` (list/search) → upstream; exposes
  loading/error/refresh states per filter; pagination appends pages.
- `FavoritesProvider` / `ViewedProvider` → `AppDatabase` (SQLite); expose
  `isFavorite(id)` / `isViewed(id)` sets for badges on cards.
- `SettingsProvider` → `SharedPreferences`; notifies on locale/theme/API changes.
- Details page marks the movie viewed on open; favorites store full JSON.

### SQLite schema

```sql
CREATE TABLE favorites (
  id INTEGER PRIMARY KEY, title TEXT, poster TEXT, year INTEGER,
  imdb REAL, json TEXT NOT NULL, created_at INTEGER NOT NULL);
CREATE TABLE viewed (
  id INTEGER PRIMARY KEY, viewed_at INTEGER NOT NULL, json TEXT NOT NULL);
CREATE TABLE search_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT, query TEXT UNIQUE NOT NULL,
  searched_at INTEGER NOT NULL);
```

## 5. Upstream API Contract (verified from a-movie source)

Base URL default: `https://server-hi-speed-iran.info`
API key default: `4F5A9C3D9A86FA54EACEDDD635185` (user-configurable in Settings).

- List: `GET {base}/api/movie/by/filtres/0/{filter}/{page}/{key}`
  → bare JSON array of movies. Filters: `created|imdb|year`; pages start at 0.
- Search: `GET {base}/api/search/{query}/{key}` → `{"posters": [movie…]}`.
- Movie JSON: `id, type, title, description, year, imdb, comment, rating, duration,
  downloadas, playas, classification, image, cover, genres[{id,title}],
  sources[{id,quality,type,url}], country[{id,title}]`.
- Tolerant parsing (duration/classification are `any`, may be string or number).

## 6. UI/UX & Micro-interactions

- Material 3; hand-tuned light & dark `ColorScheme`s: orange primary, green
  secondary/tertiary; dark = deep neutral surfaces with orange/green accents.
- Brand logo: the word "Filmify" only — gradient text (orange→green) over a
  subtle film-stripe motif; no icon marks.
- Backgrounds: soft animated gradient mesh (slow drifting radial blobs) behind
  content; gradient used sparingly on logo, primary buttons, active nav states.
- Micro-interactions: shimmer skeleton grid while loading; staggered card entrance;
  hero poster → details transition; heart-burst animation on favorite;
  springy filter chips; animated empty states; expandable description;
  pull-to-refresh; ink ripples everywhere; localized Persian numerals option.
- States: loading (shimmer), error (illustrated retry), empty (per page),
  offline-cache banner when rendering from local data.
- RTL: full mirror support via locale-driven directionality; posters/links stay LTR.

## 7. Download-manager compatibility

All `sources[].url` values are direct HTTPS file URLs. For each quality the app
provides: (1) tap = open in default handler (browser / installed download manager),
(2) copy to clipboard (universal path into IDM/FDM/aria2), (3) system share sheet.
Details page also has "copy all links". No server-side rewriting needed.

## 8. Build, Versioning & GitHub Sync

- `pubspec.yaml` `version: 1.0.0+1` is the single source of truth.
- `.github/workflows/ci.yml`: on push/PR to main → `flutter analyze` (no tests per brief).
- `.github/workflows/release.yml`: on tag push `v*`:
  1. Verify tag matches `pubspec.yaml` version (fail = version out of sync).
  2. Job matrix: Android APK (ubuntu), Linux tar.gz (ubuntu + GTK deps),
     Windows zip (windows-latest).
  3. Create GitHub Release with `Filmify-<version>-<platform>` artifacts.
- Release flow: bump `pubspec.yaml` → commit → `git tag v1.0.0 && git push --tags`.
- Remote: `git@github.com:mst-ghi/filmify.git`.

## 9. Error handling

- Network layer throws typed errors (`ApiException`: network / status / empty) and
  surfaces localized messages; every async screen has retry affordances.
- DB layer is local-only and cannot fail from network; failures surface as snackbars.
- API URL/key edits validate non-empty URL format before saving; reset-to-default
  restores baked-in values.

## 10. Explicitly out of scope (for now)

- Tests (user request), in-app download engine, streaming playback, translations
  beyond en/fa, iOS/macOS/Web targets.
