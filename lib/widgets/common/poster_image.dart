import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/models/movie.dart';
import '../../core/network/filmify_image_cache.dart';

/// Poster image with cache manager, fade-in and a soft placeholder that works
/// offline (shows an icon + gradient while loading or on failure).
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    required this.movie,
    this.width,
    this.height,
    this.borderRadius = 14,
    this.useCover = false,
  });

  final Movie movie;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool useCover;

  String get _url => (useCover && movie.cover.isNotEmpty)
      ? movie.cover
      : (movie.image.isNotEmpty
          ? movie.image
          : (movie.cover.isNotEmpty ? movie.cover : ''));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = _url;

    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.55),
            scheme.secondaryContainer.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: (width ?? 120) * 0.28,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: url.isEmpty
            ? placeholder
            : CachedNetworkImage(
                imageUrl: url,
                cacheManager: FilmifyImageCache(),
                fadeInDuration: const Duration(milliseconds: 260),
                fit: BoxFit.cover,
                width: width,
                height: height,
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
