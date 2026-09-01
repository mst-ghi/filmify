import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// App-wide image cache backed by a JSON metadata repository instead of the
/// sqflite default, so poster caching works identically on Android, Linux and
/// Windows without any native sqlite dependency.
class FilmifyImageCache extends CacheManager with ImageCacheManager {
  static final FilmifyImageCache instance = FilmifyImageCache._internal();

  factory FilmifyImageCache() => instance;

  FilmifyImageCache._internal()
      : super(Config(
          'filmifyImageCache',
          repo: JsonCacheInfoRepository(databaseName: 'filmifyImageCache'),
        ));
}
