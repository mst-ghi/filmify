import 'package:flutter/material.dart';

import '../../core/models/movie.dart';
import '../../core/state/app_scope.dart';
import '../../core/utils/localized_numbers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'poster_image.dart';

/// Poster card with favorite heart (burst micro-interaction) and the green
/// "seen" checkmark for movies whose details were viewed. Opens the details
/// page on tap via [onOpen].
class MovieCard extends StatefulWidget {
  const MovieCard({super.key, required this.movie, required this.onOpen});

  final Movie movie;
  final VoidCallback onOpen;

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _pulse = Tween(begin: 1.0, end: 1.45).animate(
    CurvedAnimation(
      parent: _burst,
      curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
    ),
  );

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _toggleFavorite(Movie movie, AppLocalizations l10n) {
    final scope = AppScope.of(context);
    final added = scope.stores.favorites.toggle(movie);
    if (added) {
      _burst
        ..reset()
        ..forward();
    }
    showAppSnackbar(
      context,
      added ? l10n.addedToFavorites : l10n.removedFromFavorites,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);

    // Rebuild on favorites/viewed changes so heart + seen badge stay live
    // everywhere the card is shown (home, search, favorites grid).
    return AnimatedBuilder(
      animation: Listenable.merge([
        scope.stores.favorites,
        scope.stores.viewed,
      ]),
      builder: (context, _) {
        final movie = widget.movie;
        final isSaved = scope.stores.favorites.isSaved(movie.id);
        final isSeen = scope.stores.viewed.isSaved(movie.id);

    return Card(
      child: InkWell(
        onTap: widget.onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'movie-${movie.id}',
                    child: PosterImage(movie: movie, borderRadius: 0),
                  ),
                  Positioned(
                    top: 8,
                    right: 4,
                    child: _FavoriteHeart(
                      active: isSaved,
                      pulse: _pulse,
                      onTap: () => _toggleFavorite(movie, l10n),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: SeenBadge(seen: isSeen),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (movie.rating > 0) ...[
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          context.rating(movie.rating),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (movie.year > 0)
                        Text(
                          context.year(movie.year),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

class _FavoriteHeart extends StatelessWidget {
  const _FavoriteHeart({
    required this.active,
    required this.pulse,
    required this.onTap,
  });

  final bool active;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: ScaleTransition(
          scale: pulse,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(active),
                size: 19,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Green checkmark pill shown on cards whose details the user has marked
/// viewed; animates in/out on change.
class SeenBadge extends StatelessWidget {
  const SeenBadge({super.key, required this.seen});

  final bool seen;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: seen ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 13,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Floating snackbar helper with the app's styling.
void showAppSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}
