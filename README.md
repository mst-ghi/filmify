# Filmify

Bilingual (English / فارسی) movie discovery & download hub — a Flutter app for
Android, Linux and Windows. Successor to the `a-movie` project, talking to the
same upstream movie API. Project internals (architecture, release process,
build notes) live in the [wiki](https://github.com/mst-ghi/filmify/wiki).

<p align="center">
  <img src="docs/screenshots/screenshot-1.jpg" width="49%" alt="Filmify screenshot 1">
  &nbsp;
  <img src="docs/screenshots/screenshot-2.jpg" width="49%" alt="Filmify screenshot 2">
</p>

## Download

Grab the latest build for your platform from the
[Releases page](https://github.com/mst-ghi/filmify/releases/latest).
Current release: **v1.1.0**

| Platform | Package | Download |
| --- | --- | --- |
| Android (arm64-v8a) | APK | [Filmify-1.1.0-android-arm64-v8a.apk](https://github.com/mst-ghi/filmify/releases/download/v1.1.0/Filmify-1.1.0-android-arm64-v8a.apk) |
| Android (armeabi-v7a) | APK | [Filmify-1.1.0-android-armeabi-v7a.apk](https://github.com/mst-ghi/filmify/releases/download/v1.1.0/Filmify-1.1.0-android-armeabi-v7a.apk) |
| Android (x86_64) | APK | [Filmify-1.1.0-android-x86_64.apk](https://github.com/mst-ghi/filmify/releases/download/v1.1.0/Filmify-1.1.0-android-x86_64.apk) |
| Linux (Debian / Ubuntu) | deb | [Filmify-1.1.0-linux-amd64.deb](https://github.com/mst-ghi/filmify/releases/download/v1.1.0/Filmify-1.1.0-linux-amd64.deb) |
| Linux (Fedora / openSUSE) | rpm | [Filmify-1.1.0-linux-x86_64.rpm](https://github.com/mst-ghi/filmify/releases/download/v1.1.0/Filmify-1.1.0-linux-x86_64.rpm) |
| Linux (portable) | tar.gz | [Filmify-1.1.0-linux-x64.tar.gz](https://github.com/mst-ghi/filmify/releases/download/v1.1.0/Filmify-1.1.0-linux-x64.tar.gz) |
| Windows (installer) | setup.exe | [Filmify-1.1.0-windows-x64-setup.exe](https://github.com/mst-ghi/filmify/releases/download/v1.1.0/Filmify-1.1.0-windows-x64-setup.exe) |
| Windows (portable) | zip | [Filmify-1.1.0-windows-x64.zip](https://github.com/mst-ghi/filmify/releases/download/v1.1.0/Filmify-1.1.0-windows-x64.zip) |

Android APKs are split per ABI — most phones from the last ~10 years
(including the Galaxy A55) use **arm64-v8a**; pick **armeabi-v7a** only for
older 32-bit devices and **x86_64** for emulators.

The deb/rpm packages and the Windows installer register a launcher and handle
updates by reinstalling; the tar.gz/zip archives are self-contained portable
builds — just extract and run.

## Features

- **Home** — newest / top-rated / by-year filters, infinite scroll, shimmer
  skeletons, pull-to-refresh.
- **Search** — debounced live search with persisted recent-query history.
- **Details** — cover backdrop, genres, rating/duration/year, description and
  download sources with open-in-download-manager, copy and share actions.
- **Built-in player** — tap a download source to preview the video in a
  full-window player (mpv/libmpv under the hood).
- **Favorites & Viewed** — favorite movies and mark movies whose details
  you've already checked (green badge on cards). Both work offline.
- **Settings** — dark/light/system theme, English/Persian/system language,
  Persian numerals toggle, custom API key, version info.
- **Bilingual & RTL** — full Persian translation with right-to-left layout.
- **Micro-interactions** — animated gradient-mesh background, hero poster
  transitions, heart-burst on favorite, animated seen badge.
- **Native desktop feel** — frameless window with custom controls and
  draggable title bar on Linux/Windows.
- **Download-manager friendly** — direct links open via the platform handler,
  so IDM/aria2/xdm/ADM-style managers pick them up.

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
three platforms, packages them (split apks / deb / rpm / tar.gz / setup.exe /
zip) and publishes a GitHub release with the artifacts. A mismatch fails the
build, keeping versions in sync.

## API key

The app uses a built-in default key. Override it in **Settings → API**; the
key is sent as a URL path segment, mirroring the upstream API contract.

## Building from source

```sh
flutter pub get
flutter run            # debug on the connected device
flutter build apk --release --split-per-abi
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
  widgets/        shared widgets (gradient background, movie card, skeletons,
                  player modal, window controls…)
```

State is intentionally hand-rolled `ChangeNotifier` stores over a sembast
database (pure Dart — no native sqlite dependency), which keeps the same code
running on Android, Linux and Windows.
