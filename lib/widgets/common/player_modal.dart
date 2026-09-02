import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../l10n/generated/app_localizations.dart';

/// Opens the video player modal for a movie source link.
///
/// The player runs on libmpv (media_kit), which handles the direct video
/// files and streams the API hands out.
Future<void> showMoviePlayer(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String url,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => _PlayerDialog(title: title, subtitle: subtitle, url: url),
  );
}

class _PlayerDialog extends StatefulWidget {
  const _PlayerDialog({
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String title;
  final String subtitle;
  final String url;

  @override
  State<_PlayerDialog> createState() => _PlayerDialogState();
}

class _PlayerDialogState extends State<_PlayerDialog> {
  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _error = null);
    // Errors surface through the stream, not the open() future.
    _player.stream.error.listen((message) {
      if (mounted) setState(() => _error = message);
    });
    _player.open(Media(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: const Color(0xFF14111B),
      // Fill the whole window; the video stage takes everything below the
      // header (black bars letterbox the stream itself).
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.expand(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Video(controller: _controller),
                  if (_error != null) _errorOverlay(context, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 18, end: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.play_arrow_rounded, size: 22,
                color: scheme.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                ),
                if (widget.subtitle.isNotEmpty)
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.white70,
                        ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _errorOverlay(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF14111B)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: scheme.error),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l10n.playerFailed,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _open,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
