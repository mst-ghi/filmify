import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_version.dart';

/// Releases API for the GitHub repo that publishes all platform artifacts.
const kReleaseRepo = 'mst-ghi/filmify';
const kReleaseApiUrl = 'https://api.github.com/repos/$kReleaseRepo/releases/latest';
const kReleasePageUrl = 'https://github.com/$kReleaseRepo/releases/latest';

/// One GitHub release as far as the updater cares — tag + downloadable assets.
class UpdateRelease {
  const UpdateRelease({
    required this.tagName,
    required this.version,
    required this.htmlUrl,
    required this.assets,
  });

  final String tagName;
  final AppVersion version;
  final String htmlUrl;
  final List<UpdateAsset> assets;

  factory UpdateRelease.fromJson(Map<String, dynamic> json) {
    final assets = (json['assets'] as List<Object?>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(UpdateAsset.fromJson)
        .toList();
    return UpdateRelease(
      tagName: (json['tag_name'] as String?) ?? '',
      version: AppVersion.tryParse((json['tag_name'] as String?) ?? '') ??
          const AppVersion(0, 0, 0),
      htmlUrl: (json['html_url'] as String?) ?? kReleasePageUrl,
      assets: assets,
    );
  }
}

class UpdateAsset {
  const UpdateAsset({required this.name, required this.url, required this.size});

  final String name;
  final String url;
  final int size;

  factory UpdateAsset.fromJson(Map<String, dynamic> json) => UpdateAsset(
        name: (json['name'] as String?) ?? '',
        url: (json['browser_download_url'] as String?) ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
      );
}

/// Checks GitHub for newer releases, downloads the platform asset and (on
/// Android/Windows) hands the file to the OS installer. All state is exposed
/// as a [ChangeNotifier] so both the desktop icon and the Settings page stay
/// in sync.
class UpdateService extends ChangeNotifier {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _methodChannel = MethodChannel('filmify/updates');

  UpdateState _state = const UpdateState.idle();
  UpdateState get state => _state;

  /// 0..1 while a download is in flight; null otherwise.
  double? get downloadProgress => _state.downloadProgress;

  /// Non-null once a download finished and is ready to install.
  String? get downloadedPath => _state.downloadedPath;

  double _lastProgress = 0;
  Future<void>? _installFuture;

  /// Fetches the latest release and compares against the running version.
  Future<UpdateRelease?> checkForUpdate({AppVersion? current}) async {
    current ??= await _currentVersion();
    _state = UpdateState.checking(current: current);
    notifyListeners();
    try {
      final response = await _client
          .get(Uri.parse(kReleaseApiUrl))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw StateError('GitHub returned ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final release = UpdateRelease.fromJson(json);
      if (!release.version.isNewerThan(current)) {
        _state = UpdateState.upToDate(
          current: current,
          latest: release.version,
          latestTag: release.tagName,
        );
      } else {
        _state = UpdateState.available(release: release, current: current);
      }
      notifyListeners();
      return release;
    } catch (error) {
      _state = UpdateState.error(current: current, message: error.toString());
      notifyListeners();
      return null;
    }
  }

  Future<AppVersion> _currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return AppVersion.tryParse(info.version) ?? const AppVersion(0, 0, 0);
  }

  AppVersion? get currentVersion => _state.currentVersion;
  AppVersion? get latestVersion => _state.latestVersion;
  String? get errorMessage => _state.errorMessage;

  /// Downloads the platform-specific asset into the app-support dir with
  /// progress reporting. Returns the downloaded file path, or null when the
  /// release has nothing to download for this platform (e.g. Linux).
  Future<String?> downloadUpdate() async {
    final state = _state;
    if (state is! UpdateStateAvailable) return null;
    final asset = _selectAsset(state.release);
    if (asset == null) return null;
    final dir = await getApplicationSupportDirectory();
    final target = p.join(dir.path, 'updates', asset.name);
    await Directory(p.dirname(target)).create(recursive: true);
    await _downloadToFile(asset.url, target);
    _state = UpdateState.downloaded(
      release: state.release,
      current: state.current,
    );
    notifyListeners();
    return target;
  }

  Future<void> _downloadToFile(String url, String path) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw StateError('Download returned ${response.statusCode}');
    }
    final total = response.contentLength ?? 0;
    final file = File(path);
    final sink = file.openWrite();
    var received = 0;
    final subscription = response.stream.listen(
      (chunk) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) {
          final progress = received / total;
          if (progress - _lastProgress >= 0.01 || progress >= 1.0) {
            _lastProgress = progress;
            final st = _state;
            if (st is UpdateStateAvailable) {
              _state = UpdateState.downloading(
                release: st.release,
                current: st.current,
                progress: progress,
              );
              notifyListeners();
            }
          }
        }
      },
      onError: (Object error) {
        sink.close();
        file.deleteSync();
        _lastProgress = 0;
      },
      onDone: () async {
        await sink.flush();
        await sink.close();
      },
      cancelOnError: true,
    );
    await subscription.asFuture<void>();
  }

  /// Installs the downloaded update. Android: FileProvider + ACTION_VIEW.
  /// Windows: run the Inno Setup installer. Linux: open the release page
  /// (the user installs via their package manager).
  Future<void> installUpdate() async {
    final path = downloadedPath;
    if (path == null) return;
    if (_installFuture != null) return _installFuture!;
    _installFuture = _doInstall(path);
    try {
      await _installFuture;
    } finally {
      _installFuture = null;
    }
  }

  Future<void> _doInstall(String path) async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      await _methodChannel.invokeMethod<void>('installApk', {'path': path});
    } else if (Platform.isWindows) {
      final process = await Process.start(path, const []);
      await process.exitCode;
    } else {
      await launchUrl(Uri.parse(kReleasePageUrl),
          mode: LaunchMode.externalApplication);
    }
  }

  /// Returns the asset to download for the current platform, or null when the
  /// release has nothing installable here (e.g. Linux — we open the page).
  UpdateAsset? _selectAsset(UpdateRelease release) {
    if (kIsWeb) return null;
    if (Platform.isAndroid) {
      // Matches the split-per-ABI artifact names the release publishes.
      const patterns = [
        'android-arm64-v8a.apk',
        'android-x86_64.apk',
        'android-armeabi-v7a.apk',
      ];
      for (final pattern in patterns) {
        for (final asset in release.assets) {
          if (asset.name.endsWith(pattern)) return asset;
        }
      }
      return null;
    }
    if (Platform.isWindows) {
      for (final asset in release.assets) {
        if (asset.name.endsWith('setup.exe')) return asset;
      }
      for (final asset in release.assets) {
        if (asset.name.endsWith('.zip')) return asset;
      }
      return null;
    }
    return null;
  }
}

/// State machine for the updater.
sealed class UpdateState {
  const UpdateState();
  const factory UpdateState.idle() = UpdateStateIdle;
  const factory UpdateState.checking({required AppVersion current}) = UpdateStateChecking;
  const factory UpdateState.upToDate({
    required AppVersion current,
    required AppVersion latest,
    required String latestTag,
  }) = UpdateStateUpToDate;
  const factory UpdateState.available({
    required UpdateRelease release,
    required AppVersion current,
  }) = UpdateStateAvailable;
  const factory UpdateState.downloading({
    required UpdateRelease release,
    required AppVersion current,
    required double progress,
  }) = UpdateStateDownloading;
  const factory UpdateState.downloaded({
    required UpdateRelease release,
    required AppVersion current,
  }) = UpdateStateDownloaded;
  const factory UpdateState.error({
    required AppVersion current,
    required String message,
  }) = UpdateStateError;

  AppVersion? get currentVersion => switch (this) {
        UpdateStateIdle() => null,
        UpdateStateChecking(current: final c) => c,
        UpdateStateUpToDate(current: final c, latest: _, latestTag: _) => c,
        UpdateStateAvailable(current: final c, release: _) => c,
        UpdateStateDownloading(current: final c, release: _, progress: _) => c,
        UpdateStateDownloaded(current: final c, release: _) => c,
        UpdateStateError(current: final c, message: _) => c,
      };

  AppVersion? get latestVersion => switch (this) {
        UpdateStateIdle() => null,
        UpdateStateChecking(current: _) => null,
        UpdateStateUpToDate(current: _, latest: final l, latestTag: _) => l,
        UpdateStateAvailable(current: _, release: final r) => r.version,
        UpdateStateDownloading(current: _, release: final r, progress: _) => r.version,
        UpdateStateDownloaded(current: _, release: final r) => r.version,
        UpdateStateError(current: _, message: _) => null,
      };

  UpdateRelease? get release => switch (this) {
        UpdateStateIdle() => null,
        UpdateStateChecking(current: _) => null,
        UpdateStateUpToDate(current: _, latest: _, latestTag: _) => null,
        UpdateStateAvailable(current: _, release: final r) => r,
        UpdateStateDownloading(current: _, release: final r, progress: _) => r,
        UpdateStateDownloaded(current: _, release: final r) => r,
        UpdateStateError(current: _, message: _) => null,
      };

  double? get downloadProgress => switch (this) {
        UpdateStateIdle() => null,
        UpdateStateChecking(current: _) => null,
        UpdateStateUpToDate(current: _, latest: _, latestTag: _) => null,
        UpdateStateAvailable(current: _, release: _) => null,
        UpdateStateDownloading(current: _, release: _, progress: final p) => p,
        UpdateStateDownloaded(current: _, release: _) => null,
        UpdateStateError(current: _, message: _) => null,
      };

  String? get downloadedPath => switch (this) {
        UpdateStateIdle() => null,
        UpdateStateChecking(current: _) => null,
        UpdateStateUpToDate(current: _, latest: _, latestTag: _) => null,
        UpdateStateAvailable(current: _, release: _) => null,
        UpdateStateDownloading(current: _, release: _, progress: _) => null,
        UpdateStateDownloaded(current: _, release: _) => null,
        UpdateStateError(current: _, message: _) => null,
      };

  String? get errorMessage => switch (this) {
        UpdateStateIdle() => null,
        UpdateStateChecking(current: _) => null,
        UpdateStateUpToDate(current: _, latest: _, latestTag: _) => null,
        UpdateStateAvailable(current: _, release: _) => null,
        UpdateStateDownloading(current: _, release: _, progress: _) => null,
        UpdateStateDownloaded(current: _, release: _) => null,
        UpdateStateError(current: _, message: final m) => m,
      };
}

class UpdateStateIdle extends UpdateState {
  const UpdateStateIdle();
}

class UpdateStateChecking extends UpdateState {
  const UpdateStateChecking({required this.current});
  final AppVersion current;
}

class UpdateStateUpToDate extends UpdateState {
  const UpdateStateUpToDate({
    required this.current,
    required this.latest,
    required this.latestTag,
  });
  final AppVersion current;
  final AppVersion latest;
  final String latestTag;
}

class UpdateStateAvailable extends UpdateState {
  const UpdateStateAvailable({required this.release, required this.current});
  @override
  final UpdateRelease release;
  final AppVersion current;
}

class UpdateStateDownloading extends UpdateState {
  const UpdateStateDownloading({
    required this.release,
    required this.current,
    required this.progress,
  });
  @override
  final UpdateRelease release;
  final AppVersion current;
  final double progress;
}

class UpdateStateDownloaded extends UpdateState {
  const UpdateStateDownloaded({required this.release, required this.current});
  @override
  final UpdateRelease release;
  final AppVersion current;
}

class UpdateStateError extends UpdateState {
  const UpdateStateError({required this.current, required this.message});
  final AppVersion current;
  final String message;
}