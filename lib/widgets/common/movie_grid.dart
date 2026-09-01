import 'package:flutter/material.dart';

import '../../core/models/movie.dart';
import 'movie_card.dart';

/// Responsive poster grid: 2 columns on phones, more on wide screens.
class MovieGrid extends StatelessWidget {
  const MovieGrid({
    super.key,
    required this.movies,
    required this.onOpen,
    this.shrinkWrap = false,
    this.physics,
    this.padding = const EdgeInsets.all(12),
    this.controller,
  });

  final List<Movie> movies;
  final void Function(Movie) onOpen;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1000
            ? 6
            : constraints.maxWidth > 720
                ? 4
                : constraints.maxWidth > 480
                    ? 3
                    : 2;
        final aspect = constraints.maxWidth > 480 ? 0.56 : 0.52;
        return GridView.builder(
          controller: controller,
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: aspect,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) =>
              MovieCard(movie: movies[index], onOpen: () => onOpen(movies[index])),
        );
      },
    );
  }
}
