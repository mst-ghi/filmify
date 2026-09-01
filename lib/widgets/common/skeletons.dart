import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmering poster-grid skeleton used while a page loads its first page of
/// data.
class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key, this.columns});

  final int? columns;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest.withValues(alpha: 0.7);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = this.columns ??
            (constraints.maxWidth > 1000
                ? 6
                : constraints.maxWidth > 720
                    ? 4
                    : constraints.maxWidth > 480
                        ? 3
                        : 2);
        final aspect = constraints.maxWidth > 480 ? 0.56 : 0.52;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: aspect,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: columns * 4,
          itemBuilder: (context, index) => Shimmer.fromColors(
            baseColor: base,
            highlightColor: scheme.surface.withValues(alpha: 0.9),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        );
      },
    );
  }
}
