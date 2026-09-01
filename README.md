# Filmify

Bilingual (English / فارسی) movie discovery & download hub — a Flutter app for
Android, Linux and Windows. Successor to the `a-movie` project, talking to the
same upstream movie API.

## Features

- **Home** — newest / top-rated / by-year filters, infinite scroll, shimmer
  skeletons, pull-to-refresh.
- **Search** — debounced live search with persisted recent-query history.
- **Details** — cover backdrop, genres, rating/duration/year, description and
  download sources with open-in-download-manager, copy and share actions.
- **Favorites & Viewed** — favorite movies and mark movies whose details
  you've already checked (green badge on cards). Both work offline.
- **Settings** — dark/light/system theme, English/Persian/system language,
  Persian numerals toggle, custom API key, version info.
- **Bilingual & RTL** — full Persian translation with right-to-left layout.
- **Micro-interactions** — animated gradient-mesh background, hero poster
  transitions, heart-burst on favorite, animated seen badge.
- **Download-manager friendly** — direct links open via the platform handler,
  so IDM/aria2/xdm/ADM-style managers pick them up.

## Install

Grab the latest build for your platform from
[Releases](https://github.com/mst-ghi/filmify/releases):

- `Filmify-<version>-android.apk`
- `Filmify-<version>-linux-x64.tar.gz`
- `Filmify-<version>-windows-x64.zip`

## Releases & versioning

`pubspec.yaml`'s `version:` (e.g. `1.2.0+3`) is the source of truth. To
release:

```sh
# 1. bump version in pubspec.yaml
# 2. commit, then tag (must match the pubspec version without the +build)
git tag v1.2.0
git push origin main --tags
```

The `Release` workflow verifies the tag matches `pubspec.yaml`, builds all
three platforms and publishes a GitHub release with the artifacts. A mismatch
fails the build, keeping versions in sync.

## API key

The app uses a built-in default key. Override it in **Settings → API**; the
key is sent as a URL path segment, mirroring the upstream API contract.

## Building from source

```sh
flutter pub get
flutter run            # debug on the connected device
flutter build apk --release
flutter build linux --release
flutter build windows --release
```

Requires Flutter (stable channel) with Android SDK / Linux GTK dev packages /
Visual Studio Toolchain respectively.

## Project layout

```
lib/
  core/           config-free building blocks: models, API client, DB (sembast),
                  stores (ChangeNotifier), theme, formatting utils
  features/       one folder per tab + details: shell, home, search,
                  favorites, details, settings, shared controllers
  l10n/           ARB translation sources + generated classes
  widgets/        shared widgets (gradient background, movie card, skeletons…)
```

State is intentionally hand-rolled `ChangeNotifier` stores over a sembast
database (pure Dart — no native sqlite dependency), which keeps the same code
running on Android, Linux and Windows.
