import 'package:sembast/sembast.dart';

/// Recent search queries, capped, newest first. Stored as a single record so
/// reads/writes are one-shot. Keeps an in-memory copy so widgets can read it
/// synchronously.
class SearchHistoryStore {
  static const _recordKey = 'recent';
  static const _maxEntries = 20;

  final Database _db;
  final StoreRef<String, Map<String, dynamic>> _store =
      stringMapStoreFactory.store('search_history');

  List<String> _queries = const [];

  SearchHistoryStore(this._db);

  /// In-memory copy, newest first; empty until [load] completes.
  List<String> get queries => List.unmodifiable(_queries);

  Future<List<String>> load() async {
    final record = await _store.record(_recordKey).get(_db);
    final stored = (record?['queries'] as List<Object?>?) ?? const [];
    _queries = stored.whereType<String>().toList();
    return queries;
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final updated = List.of(_queries)
      ..removeWhere(
          (existing) => existing.toLowerCase() == trimmed.toLowerCase())
      ..insert(0, trimmed);
    _queries = updated;
    await _save(updated.take(_maxEntries).toList());
  }

  Future<void> remove(String query) async {
    final updated = List.of(_queries)..remove(query);
    _queries = updated;
    await _save(updated);
  }

  Future<void> clear() async {
    _queries = const [];
    await _store.record(_recordKey).delete(_db);
  }

  Future<void> _save(List<String> queries) async {
    if (queries.isEmpty) {
      await clear();
    } else {
      await _store.record(_recordKey).put(_db, {'queries': queries});
    }
  }
}
