import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/state/app_scope.dart';
import '../../core/update/update_service.dart';
import '../../l10n/generated/app_localizations.dart';
import 'movie_card.dart' show showAppSnackbar;

/// Floating button that shows the updater state — a system-update icon with a
/// circular progress ring + percent while a download runs, and a badge when a
/// new release is ready. Tapping opens the update dialog.
class UpdateIconButton extends StatelessWidget {
  const UpdateIconButton({super.key, this.service});

  /// Explicit updater. Defaults to [AppScope]'s — pass it when the widget is
  /// rendered above the scope (e.g. the desktop window chrome).
  final UpdateService? service;

  @override
  Widget build(BuildContext context) {
    final resolved = service ?? AppScope.of(context).update;
    return ListenableBuilder(
      listenable: resolved,
      builder: (context, _) {
        final state = resolved.state;
        final progress = state.downloadProgress;
        final hasUpdate = state.latestVersion != null &&
            state.currentVersion != null &&
            state.latestVersion!.isNewerThan(state.currentVersion!);
        final isDownloading = progress != null;
        final isDownloaded = state is UpdateStateDownloaded;

        final Widget content;
        if (isDownloading) {
          content = _ProgressRing(
            value: progress,
            child: Text('${(progress * 100).round()}'),
          );
        } else {
          content = Icon(
            hasUpdate || isDownloaded
                ? Icons.system_update_alt_rounded
                : Icons.system_update_alt_outlined,
            size: 21,
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.85),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _openDialog(context, state),
                child: Padding(padding: const EdgeInsets.all(7), child: content),
              ),
            ),
            if (hasUpdate && !isDownloading && !isDownloaded)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openDialog(BuildContext context, UpdateState state) {
    showUpdateDialog(context, service: service ?? AppScope.of(context).update);
  }

  static Future<void> show(BuildContext context) {
    return showUpdateDialog(
      context,
      service: AppScope.of(context).update,
    );
  }
}

/// Circular determinate ring with the percentage centered.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, required this.child});

  final double value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _RingPainter(value: value.clamp(0, 1), color: scheme.primary),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, bg);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

/// Popup with the update status: current → latest versions, an inline progress
/// bar + percentage while downloading, and Download / Cancel / Install actions.
Future<void> showUpdateDialog(
  BuildContext context, {
  required UpdateService service,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _UpdateDialog(service: service),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.service});

  final UpdateService service;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  UpdateService get service => widget.service;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    // Kick a check if the app never ran one (e.g. user opened it directly).
    if (service.state is UpdateStateIdle || service.errorMessage != null) {
      service.checkForUpdate();
    }
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final path = await service.downloadUpdate();
      if (!mounted) return;
      if (path == null) {
        setState(() => _downloading = false);
        await _openReleasePage();
      } else {
        setState(() => _downloading = false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _downloading = false);
      showAppSnackbar(context, error.toString());
    }
  }

  Future<void> _openReleasePage() async {
    final uri = Uri.parse(kReleasePageUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _install() async {
    try {
      await service.installUpdate();
    } catch (error) {
      if (!mounted) return;
      showAppSnackbar(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Icon(Icons.system_update_alt_rounded, color: scheme.primary),
          const SizedBox(width: 10),
          Text(l10n.updateTitle),
        ],
      ),
      content: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final state = service.state;
          final current = state.currentVersion;

          if (state is UpdateStateChecking) {
            return _StatusRow(
              icon: Icons.hourglass_top_rounded,
              message: l10n.updateChecking,
              showSpinner: true,
            );
          }

          if (state is UpdateStateError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.updateCheckFailed),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: service.checkForUpdate,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ],
            );
          }

          if (state is UpdateStateUpToDate) {
            return _StatusRow(
              icon: Icons.check_circle_rounded,
              message:
                  '${l10n.updateUpToDate} — ${current?.toString() ?? ''}',
            );
          }

          if (state is UpdateStateAvailable || state is UpdateStateDownloading ||
              state is UpdateStateDownloaded) {
            final release = state.release!;
            final progress = state.downloadProgress;
            final isDownloaded = state is UpdateStateDownloaded;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.updateNewVersion('${current ?? ''}', '${release.version}'),
                ),
                const SizedBox(height: 16),
                if (progress != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.updateProgress((progress * 100).round()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                if (isDownloaded)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _install,
                          icon: const Icon(Icons.install_desktop_rounded, size: 18),
                          label: Text(l10n.updateInstall),
                        ),
                      ),
                    ],
                  ),
                if (progress != null && !isDownloaded)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openReleasePage,
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(l10n.updateOpenPage),
                        ),
                      ),
                    ],
                  ),
                if (progress == null && !isDownloaded)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _downloading ? null : _download,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(l10n.updateDownload),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonTooltip),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  final IconData icon;
  final String message;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSpinner)
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: scheme.primary),
          )
        else
          Icon(icon, color: scheme.primary, size: 22),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}