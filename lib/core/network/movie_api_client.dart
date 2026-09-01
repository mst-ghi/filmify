import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';

/// Typed failures so the UI can distinguish retryable network problems from
/// server-side errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException.network(this.message) : statusCode = null;
  const ApiException.server(this.message, this.statusCode);
  const ApiException.parsing(this.message) : statusCode = null;

  @override
  String toString() => message;
}

/// Client for the upstream movie API.
///
/// Endpoints mirror a-movie's Go service (`domain/movies/movies.service.go`):
///  - list:  GET {base}/api/movie/by/filtres/0/{filter}/{page}/{key}  (pages start at 0)
///  - search: GET {base}/api/search/{query}/{key}  → {"posters": [...]}
class MovieApiClient {
  static const defaultApiKey = '4F5A9C3D9A86FA54EACEDDD635185';
  static const defaultBaseUrl = 'https://server-hi-speed-iran.info';
  static const _timeout = Duration(seconds: 10);

  /// Filters accepted upstream; anything else falls back to `created`.
  static const filters = <String>['created', 'imdb', 'year'];

  final http.Client _client;
  final String Function() _apiKey;

  MovieApiClient({
    http.Client? client,
    String Function()? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? (() => defaultApiKey);

  Uri _uri(String path) => Uri.parse('$defaultBaseUrl$path');

  Future<Object?> _getJson(String path) async {
    late final http.Response response;
    try {
      response = await _client
          .get(_uri(path), headers: {'Accept': 'application/json'})
          .timeout(_timeout);
    } on TimeoutException {
      throw const ApiException.network('Request timed out');
    } catch (error) {
      throw ApiException.network(error.toString());
    }

    if (response.statusCode != 200) {
      throw ApiException.server(
        'Upstream returned status ${response.statusCode}',
        response.statusCode,
      );
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (error) {
      throw ApiException.parsing('Invalid JSON: $error');
    }
  }

  /// [page] is 0-based, matching upstream.
  Future<List<Movie>> list({
    required String filter,
    required int page,
  }) async {
    final key = Uri.encodeComponent(_apiKey());
    final safeFilter = filters.contains(filter) ? filter : 'created';
    final data = await _getJson(
      '/api/movie/by/filtres/0/$safeFilter/$page/$key',
    );

    if (data is! List) {
      throw const ApiException.parsing('Expected a list of movies');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(Movie.fromJson)
        .toList();
  }

  Future<List<Movie>> search(String query) async {
    final key = Uri.encodeComponent(_apiKey());
    final encodedQuery = Uri.encodeComponent(query.trim());
    if (encodedQuery.isEmpty) return const [];

    final data = await _getJson('/api/search/$encodedQuery/$key');
    final posters = (data is Map<String, dynamic>)
        ? data['posters']
        : null;

    if (posters is! List) return const [];
    return posters
        .whereType<Map<String, dynamic>>()
        .map(Movie.fromJson)
        .toList();
  }

  void close() => _client.close();
}
