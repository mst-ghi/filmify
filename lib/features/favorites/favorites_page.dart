import 'package:flutter/material.dart';

import '../../core/state/app_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/movie_grid.dart';
import '../../widgets/common/status_views.dart';
import '../details/movie_details_page.dart';

/// Favorites tab with a Favorites / Viewed (seen) segmented toggle, both fed
/// live from their stores.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

enum _LibraryTab { favorites, viewed }

class _FavoritesPageState extends State<FavoritesPage> {
  _LibraryTab _tab = _LibraryTab.favorites;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final favorites = scope.stores.favorites;
    final viewed = scope.stores.viewed;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: GradientBackground(
        child: AnimatedBuilder(
          animation: Listenable.merge([favorites, viewed]),
          builder: (context, _) {
            final movies = _tab == _LibraryTab.favorites
                ? favorites.items
                : viewed.items;
            final emptyTitle = _tab == _LibraryTab.favorites
                ? l10n.favoritesEmptyTitle
                : l10n.favoritesEmptyTitle;
            final emptySubtitle = _tab == _LibraryTab.favorites
                ? l10n.favoritesEmptySubtitle
                : l10n.favoritesEmptySubtitle;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: SegmentedButton<_LibraryTab>(
                    segments: [
                      ButtonSegment(
                        value: _LibraryTab.favorites,
                        icon: const Icon(Icons.favorite_rounded, size: 18),
                        label: Text(l10n.navFavorites),
                      ),
                      ButtonSegment(
                        value: _LibraryTab.viewed,
                        icon: const Icon(Icons.visibility_rounded, size: 18),
                        label: Text(l10n.viewedBadge),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (selection) =>
                        setState(() => _tab = selection.first),
                  ),
                ),
                Expanded(
                  child: movies.isEmpty
                      ? StatusView(
                          icon: _tab == _LibraryTab.favorites
                              ? Icons.favorite_border_rounded
                              : Icons.visibility_outlined,
                          title: emptyTitle,
                          subtitle: emptySubtitle,
                        )
                      : MovieGrid(
                          movies: movies,
                          onOpen: (movie) => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MovieDetailsPage(movie: movie),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
