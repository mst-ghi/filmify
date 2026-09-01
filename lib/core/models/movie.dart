/// Upstream movie data types with tolerant parsing.
///
/// Mirrors the a-movie Go structs (`domain/movies/movies.response.go`):
/// `duration` and `classification` come back as arbitrary JSON values, and
/// numeric fields may be sent as strings, so every field parses defensively.
library;

class MovieGenre {
  final int id;
  final String title;

  const MovieGenre({required this.id, required this.title});

  factory MovieGenre.fromJson(Map<String, dynamic> json) => MovieGenre(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: (json['title'] as String?) ?? '',
      );
}

class MovieCountry {
  final int id;
  final String title;

  const MovieCountry({required this.id, required this.title});

  factory MovieCountry.fromJson(Map<String, dynamic> json) => MovieCountry(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: (json['title'] as String?) ?? '',
      );
}

class MovieSource {
  final int id;
  final String quality;
  final String type;
  final String url;

  const MovieSource({
    required this.id,
    required this.quality,
    required this.type,
    required this.url,
  });

  factory MovieSource.fromJson(Map<String, dynamic> json) => MovieSource(
        id: (json['id'] as num?)?.toInt() ?? 0,
        quality: (json['quality'] as String?) ?? '',
        type: (json['type'] as String?) ?? '',
        url: (json['url'] as String?) ?? '',
      );
}

class Movie {
  final int id;
  final String type;
  final String title;
  final String description;
  final int year;
  final double imdb;
  final bool comment;
  final double rating;
  /// Upstream sends `duration` as string or number — kept raw, parsed via
  /// [durationMinutes].
  final Object? duration;
  final String downloadas;
  final String playas;
  final Object? classification;
  final String image;
  final String cover;
  final List<MovieGenre> genres;
  final List<MovieSource> sources;
  final List<MovieCountry> countries;

  const Movie({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.year,
    required this.imdb,
    required this.comment,
    required this.rating,
    required this.duration,
    required this.downloadas,
    required this.playas,
    required this.classification,
    required this.image,
    required this.cover,
    required this.genres,
    required this.sources,
    required this.countries,
  });

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
        id: _parseInt(json['id']) ?? 0,
        type: (json['type'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        year: _parseInt(json['year']) ?? 0,
        imdb: _parseDouble(json['imdb']) ?? 0,
        comment: json['comment'] == true,
        rating: _parseDouble(json['rating']) ?? 0,
        duration: json['duration'],
        downloadas: (json['downloadas'] as String?) ?? '',
        playas: (json['playas'] as String?) ?? '',
        classification: json['classification'],
        image: (json['image'] as String?) ?? '',
        cover: (json['cover'] as String?) ?? '',
        genres: ((json['genres'] as List<Object?>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MovieGenre.fromJson)
            .toList(),
        sources: ((json['sources'] as List<Object?>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MovieSource.fromJson)
            .toList(),
        countries: ((json['country'] as List<Object?>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MovieCountry.fromJson)
            .toList(),
      );

  int? get durationMinutes => _parseInt(duration);

  bool get hasDownloadSources =>
      sources.any((source) => source.url.isNotEmpty);

  /// Compact map persisted in favorites/viewed stores — enough to render a
  /// card offline; full details are re-fetched on demand via search/id.
  Map<String, dynamic> toSnapshot() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'year': year,
        'imdb': imdb,
        'rating': rating,
        'duration': duration,
        'image': image,
        'cover': cover,
        'genres': genres.map((g) => {'id': g.id, 'title': g.title}).toList(),
        'sources': sources
            .map((s) => {'id': s.id, 'quality': s.quality, 'type': s.type, 'url': s.url})
            .toList(),
        'country': countries
            .map((c) => {'id': c.id, 'title': c.title})
            .toList(),
        'savedAt': DateTime.now().toIso8601String(),
      };

  factory Movie.fromSnapshot(Map<String, dynamic> json) => Movie.fromJson(json);
}
