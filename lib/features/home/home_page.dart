import 'package:flutter/material.dart';

import '../../core/models/movie.dart';
import '../../core/network/movie_api_client.dart';
import '../../core/state/app_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/movie_card.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/common/status_views.dart';
import '../details/movie_details_page.dart';
import '../movies/movies_controller.dart';

/// "Home" tab: filter chips (newest / top-rated / by-year), infinite scroll,
/// shimmer skeleton on first load and pull-to-refresh.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  late final MovieApiClient _api;
  late final ScrollController _scroll = ScrollController();
  PagedMovies _listing = PagedMovies(filter: MovieApiClient.filters.first);
  bool _started = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppScope isn't reachable in initState, so bootstrap here, once.
    if (_started) return;
    _started = true;
    _api = AppScope.of(context).apiClient;
    _listing = PagedMovies(filter: MovieApiClient.filters.first);
    _listing.reload(api: _api, onChanged: () => setState(() {}));
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600) {
      _listing.loadMore(api: _api, onChanged: () => setState(() {}));
    }
  }

  Future<void> _switchFilter(String filter) async {
    if (filter == _listing.filter && _listing.movies.isNotEmpty) return;
    setState(() {
      _listing = PagedMovies(filter: filter);
    });
    await _listing.reload(api: _api, onChanged: () => setState(() {}));
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final filterLabels = {
      'created': l10n.filterNewest,
      'imdb': l10n.filterTop,
      'year': l10n.filterByYear,
    };

    final firstLoad = _listing.loading && _listing.movies.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: GradientBackground(
        child: RefreshIndicator(
          onRefresh: () =>
              _listing.reload(api: _api, onChanged: () => setState(() {})),
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final entry in filterLabels.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 12),
                        child: FilterChip(
                          selected: _listing.filter == entry.key,
                          onSelected: (_) => _switchFilter(entry.key),
                          label: Text(entry.value),
                          showCheckmark: false,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: firstLoad
                    ? const GridSkeleton()
                    : _listing.hasError && _listing.movies.isEmpty
                        ? ErrorView(
                            error: _listing.error!,
                            onRetry: () => _listing.reload(
                                api: _api, onChanged: () => setState(() {})),
                          )
                        : _listing.movies.isEmpty
                            ? StatusView(
                                icon: Icons.movie_filter_outlined,
                                title: l10n.homeEmptyTitle,
                                subtitle: l10n.homeEmptySubtitle,
                              )
                            : _buildGrid(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(AppLocalizations l10n) {
    final itemCount = _listing.movies.length + (_listing.loading ? 1 : 0);
    return CustomScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.crossAxisExtent;
              // Responsive ladder: 1 column on phones up to 6 on wide
              // desktops. The single-column tier uses a list-row aspect so
              // one card doesn't fill the whole screen height.
              final columns = switch (width) {
                > 1200 => 6,
                > 1000 => 5,
                > 820 => 4,
                > 640 => 3,
                > 380 => 2,
                _ => 1,
              };
              final aspect = switch (columns) {
                1 => 2.8,
                2 => 0.52,
                _ => 0.56,
              };
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: aspect,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _listing.movies.length) {
                      return const _FooterLoader();
                    }
                    final movie = _listing.movies[index];
                    return MovieCard(
                      movie: movie,
                      onOpen: () => _openDetails(movie),
                    );
                  },
                  childCount: itemCount,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDetails(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MovieDetailsPage(movie: movie),
      ),
    );
  }
}

class _FooterLoader extends StatelessWidget {
  const _FooterLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.6),
      ),
    );
  }
}
