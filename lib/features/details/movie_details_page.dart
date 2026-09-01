import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/movie.dart';
import '../../core/state/app_scope.dart';
import '../../core/utils/localized_numbers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/movie_card.dart';
import '../../widgets/common/poster_image.dart';
import '../../widgets/common/status_views.dart';

/// Full-screen details: cover backdrop, hero poster, metadata, description,
/// download sources (open / copy / share) and the seen toggle.
class MovieDetailsPage extends StatefulWidget {
  const MovieDetailsPage({super.key, required this.movie});

  final Movie movie;

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  bool _descriptionExpanded = false;

  Movie get movie => widget.movie;

  Future<void> _download(String url, AppLocalizations l10n) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
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
    final durationText = context.duration(movie.durationMinutes);
    final isSeen = scope.stores.viewed.isSaved(movie.id);
    final isFavorite = scope.stores.favorites.isSaved(movie.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (movie.cover.isNotEmpty)
                      PosterImage(movie: movie, useCover: true, borderRadius: 0)
                    else
                      PosterImage(movie: movie, borderRadius: 0),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.2, 1],
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            scheme.surface.withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'movie-${movie.id}',
                        child: PosterImage(movie: movie, width: 108),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 14,
                              runSpacing: 6,
                              children: [
                                if (movie.year > 0)
                                  _Meta(
                                    icon: Icons.calendar_today_rounded,
                                    text: context.year(movie.year),
                                  ),
                                if (movie.rating > 0)
                                  _Meta(
                                    icon: Icons.star_rounded,
                                    text: context.rating(movie.rating),
                                  ),
                                if (durationText != null)
                                  _Meta(
                                    icon: Icons.schedule_rounded,
                                    text: durationText,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isFavorite
                                ? scheme.primary.withValues(alpha: 0.14)
                                : null,
                            foregroundColor:
                                isFavorite ? scheme.primary : null,
                          ),
                          onPressed: () {
                            final added = scope.stores.favorites.toggle(movie);
                            setState(() {});
                            showAppSnackbar(
                              context,
                              added
                                  ? l10n.addedToFavorites
                                  : l10n.removedFromFavorites,
                            );
                          },
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                                    scale: animation, child: child),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              key: ValueKey(isFavorite),
                            ),
                          ),
                          label: Text(
                            isFavorite
                                ? l10n.removedFromFavorites
                                : l10n.addedToFavorites,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isSeen
                                ? scheme.secondary.withValues(alpha: 0.16)
                                : null,
                            foregroundColor:
                                isSeen ? scheme.secondary : null,
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
                                ScaleTransition(
                                    scale: animation, child: child),
                            child: Icon(
                              isSeen
                                  ? Icons.check_circle_rounded
                                  : Icons.check_circle_outline_rounded,
                              key: ValueKey(isSeen),
                            ),
                          ),
                          label: Text(
                            isSeen ? l10n.unmarkSeen : l10n.markSeen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (movie.genres.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final genre in movie.genres)
                          Chip(
                            label: Text(genre.title),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                  if (movie.countries.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.countries,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.countries.map((c) => c.title).join('، '),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    l10n.description,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () =>
                        setState(() => _descriptionExpanded =
                            !_descriptionExpanded),
                    child: Text(
                      movie.description.isEmpty
                          ? l10n.noDescription
                          : movie.description,
                      maxLines: _descriptionExpanded ? null : 5,
                      overflow: _descriptionExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(height: 1.7),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.sources,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (!movie.hasDownloadSources)
                    StatusView(
                      icon: Icons.download_done_rounded,
                      title: l10n.noDownloadLinks,
                      subtitle: '',
                    )
                  else
                    for (final source in movie.sources.where(
                        (s) => s.url.isNotEmpty))
                      _SourceTile(
                        source: source,
                        onDownload: () => _download(source.url, l10n),
                        onCopy: () => _copy(source.url, l10n),
                      ),
                  if (movie.hasDownloadSources)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _copy(
                              movie.sources
                                  .where((s) => s.url.isNotEmpty)
                                  .map((s) => s.url)
                                  .join('\n'),
                              l10n,
                            ),
                            icon: const Icon(Icons.copy_all_rounded, size: 18),
                            label: Text(l10n.copyAll),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _shareLink(l10n),
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: Text(l10n.share),
                          ),
                        ],
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.onDownload,
    required this.onCopy,
  });

  final MovieSource source;
  final VoidCallback onDownload;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = [
      if (source.quality.isNotEmpty) source.quality,
      if (source.type.isNotEmpty) source.type,
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.download_rounded,
            size: 20,
            color: scheme.secondary,
          ),
        ),
        title: Text(
          label.isEmpty ? source.url : label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: label.isEmpty
            ? null
            : Text(
                source.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context)
                  .copyButtonLabel
                  .toUpperCase(),
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 20),
            ),
            const SizedBox(width: 4),
            IconButton(
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
    );
  }
}
