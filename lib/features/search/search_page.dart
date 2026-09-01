import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/movie.dart';
import '../../core/state/app_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/movie_grid.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/common/status_views.dart';
import '../details/movie_details_page.dart';

/// Search tab: debounced live search, recent-query chips (persisted), empty
/// and no-result states.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List<Movie> _results = const [];
  bool _loading = false;
  Object? _error;
  String _activeQuery = '';
  List<String> _history = const [];

  @override
  bool get wantKeepAlive => true;

  bool _historyLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppScope isn't reachable in initState, so read history here, once.
    if (_historyLoaded) return;
    _historyLoaded = true;
    _history = AppScope.of(context).stores.searchHistory.queries;
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
        _loading = false;
        _activeQuery = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(query));
  }

  Future<void> _search(String query) async {
    final scope = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
      _activeQuery = query;
    });
    try {
      final results = await scope.apiClient.search(query);
      if (!mounted) return;
      setState(() => _results = results);
      await scope.stores.searchHistory.add(query);
      if (mounted) setState(() => _history = scope.stores.searchHistory.queries);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _results = const [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.navSearch)),
      body: GradientBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _controller.clear();
                            _focus.requestFocus();
                          },
                        ),
                ),
              ),
            ),
            if (_activeQuery.isEmpty && _history.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 6),
                        child: Text(
                          l10n.searchHistory,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final scope = AppScope.of(context);
                          await scope.stores.searchHistory.clear();
                          setState(() => _history = const []);
                        },
                        child: Text(l10n.clearHistory),
                      ),
                    ],
                  ),
                ),
              ),
            if (_activeQuery.isEmpty && _history.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final query in _history)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ActionChip(
                          label: Text(query),
                          onPressed: () {
                            _controller.text = query;
                            _search(query);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: _buildBody(l10n, scheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ColorScheme scheme) {
    if (_loading) {
      return _results.isEmpty ? const GridSkeleton() : const GridSkeleton();
    }
    if (_error != null) {
      return ErrorView(
        error: _error!,
        onRetry: () => _search(_activeQuery),
      );
    }
    if (_activeQuery.isEmpty) {
      return StatusView(
        icon: Icons.manage_search_rounded,
        title: l10n.searchInitialTitle,
        subtitle: l10n.searchInitialSubtitle,
      );
    }
    if (_results.isEmpty) {
      return StatusView(
        icon: Icons.search_off_rounded,
        title: l10n.searchEmptyTitle,
        subtitle: l10n.searchEmptySubtitle(_activeQuery),
      );
    }
    return MovieGrid(
      movies: _results,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      onOpen: (movie) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MovieDetailsPage(movie: movie),
        ),
      ),
    );
  }
}
