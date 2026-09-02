import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/movie.dart';
import '../../core/state/app_scope.dart';
import '../../core/utils/localized_numbers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common/gradient_background.dart';
// The shared showAppSnackbar helper lives next to MovieCard.
import '../../widgets/common/movie_card.dart';
import '../../widgets/common/player_modal.dart';
import '../../widgets/common/poster_image.dart';
import '../../widgets/common/status_views.dart';

/// Cinematic details screen: full-bleed cover with the poster and title
/// anchored over its scrim, then a centered content column with the story,
/// metadata and download sources.
class MovieDetailsPage extends StatefulWidget {
  const MovieDetailsPage({super.key, required this.movie});

  final Movie movie;

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  static const _contentMaxWidth = 880.0;

  bool _descriptionExpanded = false;

  bool get _hasLongDescription => movie.description.length > 220;

  Movie get movie => widget.movie;

  Future<void> _download(String url, AppLocalizations l10n) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) showAppSnackbar(context, l10n.openFailed);
    }
  }

  void _copy(String text, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: text));
    showAppSnackbar(context, l10n.copied);
  }

  Future<void> _shareLink(AppLocalizations l10n) async {
    final links = movie.sources
        .where((s) => s.url.isNotEmpty)
        .map((s) => s.url)
        .join('\n');
    await SharePlus.instance.share(
      ShareParams(text: '${movie.title}\n$links'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final scope = AppScope.of(context);
    final isSeen = scope.stores.viewed.isSaved(movie.id);
    final isFavorite = scope.stores.favorites.isSaved(movie.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            // Transparent pinned bar: just the back button, floating over the
            // hero. First sliver paints on top, so it survives the scroll.
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsetsDirectional.only(start: 12),
                child: _BackButton(),
              ),
            ),
            SliverToBoxAdapter(child: _hero(context)),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _contentMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 52, 24, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _actionRow(l10n, scheme, scope, isSeen, isFavorite),
                        if (movie.genres.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final genre in movie.genres)
                                _TagPill(label: genre.title),
                            ],
                          ),
                        ],
                        if (movie.countries.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          _SectionHeader(
                            icon: Icons.public_rounded,
                            title: l10n.countries,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final country in movie.countries)
                                _TagPill(label: country.title),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),
                        _SectionHeader(
                          icon: Icons.menu_book_rounded,
                          title: l10n.description,
                        ),
                        const SizedBox(height: 12),
                        _description(context, l10n, scheme),
                        const SizedBox(height: 32),
                        _SectionHeader(
                          icon: Icons.download_rounded,
                          title: l10n.sources,
                        ),
                        const SizedBox(height: 12),
                        if (!movie.hasDownloadSources)
                          StatusView(
                            icon: Icons.download_done_rounded,
                            title: l10n.noDownloadLinks,
                            subtitle: '',
                          )
                        else ...[
                          for (final source in movie.sources.where(
                              (s) => s.url.isNotEmpty))
                            _SourceTile(
                              source: source,
                              onPlay: () => showMoviePlayer(
                                context,
                                title: movie.title,
                                subtitle: sourceLabel(source),
                                url: source.url,
                              ),
                              onDownload: () => _download(source.url, l10n),
                              onCopy: () => _copy(source.url, l10n),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _copy(
                                    movie.sources
                                        .where((s) => s.url.isNotEmpty)
                                        .map((s) => s.url)
                                        .join('\n'),
                                    l10n,
                                  ),
                                  icon: const Icon(Icons.copy_all_rounded,
                                      size: 18),
                                  label: Text(l10n.copyAll),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _shareLink(l10n),
                                  icon:
                                      const Icon(Icons.share_rounded, size: 18),
                                  label: Text(l10n.share),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-bleed cover with the poster and title block anchored over the
  /// scrim; the poster hangs slightly below the cover edge for depth.
  Widget _hero(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final durationText = context.duration(movie.durationMinutes);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          height: 330,
          child: movie.cover.isNotEmpty
              ? PosterImage(movie: movie, useCover: true, borderRadius: 0)
              : PosterImage(movie: movie, borderRadius: 0),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.55, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.40),
                  Colors.black.withValues(alpha: 0.05),
                  scheme.surface.withValues(alpha: 0.98),
                ],
              ),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: 0,
          start: 24,
          end: 24,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 26),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'movie-${movie.id}',
                        child: PosterImage(
                          movie: movie,
                          width: 132,
                          height: 198,
                          borderRadius: 18,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: 20, bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (movie.rating > 0)
                                _MetaPill(
                                  icon: Icons.star_rounded,
                                  text: context.rating(movie.rating),
                                  accent: true,
                                ),
                              if (movie.year > 0)
                                _MetaPill(
                                  icon: Icons.calendar_today_rounded,
                                  text: context.year(movie.year),
                                ),
                              if (durationText != null)
                                _MetaPill(
                                  icon: Icons.schedule_rounded,
                                  text: durationText,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionRow(
    AppLocalizations l10n,
    ColorScheme scheme,
    AppScope scope,
    bool isSeen,
    bool isFavorite,
  ) {
    const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(
        Radius.circular(14)));
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 50),
              shape: shape,
              backgroundColor: isFavorite
                  ? scheme.primary.withValues(alpha: 0.14)
                  : null,
              foregroundColor: isFavorite ? scheme.primary : null,
            ),
            onPressed: () {
              final added = scope.stores.favorites.toggle(movie);
              setState(() {});
              showAppSnackbar(
                context,
                added ? l10n.addedToFavorites : l10n.removedFromFavorites,
              );
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
              ),
            ),
            label: Text(
              isFavorite ? l10n.removedFromFavorites : l10n.addedToFavorites,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 50),
              shape: shape,
              backgroundColor:
                  isSeen ? scheme.secondary.withValues(alpha: 0.16) : null,
              foregroundColor: isSeen ? scheme.secondary : null,
            ),
            onPressed: () {
              final added = scope.stores.viewed.toggle(movie);
              setState(() {});
              showAppSnackbar(
                context,
                added ? l10n.markSeen : l10n.unmarkSeen,
              );
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSeen
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                key: ValueKey(isSeen),
              ),
            ),
            label: Text(isSeen ? l10n.unmarkSeen : l10n.markSeen),
          ),
        ),
      ],
    );
  }

  Widget _description(BuildContext context, AppLocalizations l10n,
      ColorScheme scheme) {
    final body = Theme.of(context).textTheme.bodyMedium!.copyWith(height: 1.75);
    return InkWell(
      onTap: _hasLongDescription
          ? () => setState(
              () => _descriptionExpanded = !_descriptionExpanded)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectionArea(
            child: Text(
              movie.description.isEmpty
                  ? l10n.noDescription
                  : movie.description,
              maxLines: _descriptionExpanded ? null : 5,
              overflow: _descriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: movie.description.isEmpty
                  ? body.copyWith(
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurfaceVariant)
                  : body,
            ),
          ),
          if (_hasLongDescription)
            AnimatedRotation(
              turns: _descriptionExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Frosted circular back button, legible over any cover art.
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return Center(
      child: Material(
        color: scheme.surface.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          child: Tooltip(
            message: MaterialLocalizations.of(context).backButtonTooltip,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                rtl
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_back_rounded,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Accent bar + section title.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Small rounded metadata pill; [accent] tints it with the secondary (green).
class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text, this.accent = false});

  final IconData icon;
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ? scheme.secondary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent
            ? scheme.secondary.withValues(alpha: 0.14)
            : scheme.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/// Outlined tag used for genres and countries.
class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// "quality • type" caption for a source, e.g. "1080p • download".
String sourceLabel(MovieSource source) => [
      if (source.quality.isNotEmpty) source.quality,
      if (source.type.isNotEmpty) source.type,
    ].join(' • ');

/// One download source: quality badge, url, copy and open actions on a
/// rounded hoverable tile.
class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.onPlay,
    required this.onDownload,
    required this.onCopy,
  });

  final MovieSource source;
  final VoidCallback onPlay;
  final VoidCallback onDownload;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = sourceLabel(source);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          hoverColor: scheme.surfaceContainerHigh.withValues(alpha: 0.9),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
                start: 12, end: 6, top: 10, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.download_rounded,
                    size: 20,
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.isEmpty ? source.url : label,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (label.isNotEmpty)
                        Text(
                          source.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).play,
                  onPressed: onPlay,
                  icon: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 26,
                    color: scheme.secondary,
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context)
                      .copyButtonLabel
                      .toUpperCase(),
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 20),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context)
                      .moreButtonTooltip,
                  onPressed: onDownload,
                  icon: Icon(
                    Icons.open_in_new_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
