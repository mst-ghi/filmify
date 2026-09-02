import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native window chrome for the frameless Linux desktop build.
///
/// The GTK runner removes the WM title bar, so the app draws its own
/// minimize/maximize/close buttons and reports a draggable top strip to the
/// runner via the `filmify/window` method channel. The runner starts the
/// window move synchronously inside the button-press handler — Wayland
/// ignores move requests that arrive after the press grab has ended.
class DesktopWindowChrome extends StatefulWidget {
  const DesktopWindowChrome({super.key, required this.child});

  final Widget child;

  static bool get enabled => !kIsWeb && Platform.isLinux;

  /// Height of the draggable strip, and the leading/trailing zones excluded
  /// from it (back button on one side, window buttons on the other).
  static const double stripHeight = 44;
  static const double leadingExclusion = 70;
  static const double trailingExclusion = 120;

  @override
  State<DesktopWindowChrome> createState() => _DesktopWindowChromeState();
}

/// Whether a modal dialog is open above the shell. The desktop window
/// buttons hide while it is, so the dialog's own close button owns the
/// top-right corner instead of floating over it.
final ValueNotifier<bool> windowDialogOpen = ValueNotifier(false);

/// Navigator observer feeding [windowDialogOpen]; register it in
/// [MaterialApp.navigatorObservers].
class DialogVisibilityObserver extends NavigatorObserver {
  int _dialogDepth = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is RawDialogRoute) windowDialogOpen.value = ++_dialogDepth > 0;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is RawDialogRoute) windowDialogOpen.value = --_dialogDepth > 0;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is RawDialogRoute) windowDialogOpen.value = --_dialogDepth > 0;
  }
}

class _DesktopWindowChromeState extends State<DesktopWindowChrome> {
  Rect? _sentRegion;

  @override
  Widget build(BuildContext context) {
    if (!DesktopWindowChrome.enabled) return widget.child;
    // The MaterialApp.builder context may lack Directionality; fall back to
    // the resolved locale so the exclusion zones match the real layout.
    final textDirection = Directionality.maybeOf(context) ??
        ((Localizations.maybeLocaleOf(context)?.languageCode == 'fa')
            ? TextDirection.rtl
            : TextDirection.ltr);

    final region = _dragRegion(context, textDirection);
    if (region != _sentRegion) {
      _sentRegion = region;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) WindowChannel.setDragRegion(region);
      });
    }

    return Directionality(
      textDirection: textDirection,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // The runner makes the window surface transparent; clipping the
          // app to a rounded rect is what gives the window its corners.
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: widget.child,
          ),
          // Hidden while a dialog (e.g. the player modal) is open — the
          // dialog draws its own close button in that corner.
          ValueListenableBuilder<bool>(
            valueListenable: windowDialogOpen,
            builder: (context, dialogOpen, _) => dialogOpen
                ? const SizedBox.shrink()
                : const PositionedDirectional(
                    top: 7,
                    end: 10,
                    child: WindowControlButtons(),
                  ),
          ),
        ],
      ),
    );
  }

  /// Top strip minus the back-button and control-button zones, in Flutter
  /// logical pixels. The native side consumes presses here to move the
  /// window, so anything interactive must stay outside this rect.
  Rect _dragRegion(BuildContext context, TextDirection direction) {
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 0;
    final rtl = direction == TextDirection.rtl;
    final start = rtl ? DesktopWindowChrome.trailingExclusion
        : DesktopWindowChrome.leadingExclusion;
    final end = rtl ? width - DesktopWindowChrome.leadingExclusion
        : width - DesktopWindowChrome.trailingExclusion;
    return Rect.fromLTRB(
      start,
      0,
      end > start ? end : start,
      DesktopWindowChrome.stripHeight,
    );
  }
}

/// Dart side of the runner's `filmify/window` channel.
class WindowChannel {
  WindowChannel._();

  static const _channel = MethodChannel('filmify/window');

  static Future<void> _invoke(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Runner without window support: ignore.
    }
  }

  static Future<void> close() => _invoke('close');
  static Future<void> minimize() => _invoke('minimize');
  static Future<void> toggleMaximize() => _invoke('toggleMaximize');

  static Future<void> setDragRegion(Rect rect) => _invoke('setDragRegion', {
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
      });
}

class WindowControlButtons extends StatelessWidget {
  const WindowControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background =
        scheme.surfaceContainerHigh.withValues(alpha: 0.85);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlButton(
          icon: Icons.remove_rounded,
          onTap: WindowChannel.minimize,
          background: background,
        ),
        const SizedBox(width: 6),
        _ControlButton(
          icon: Icons.crop_square_rounded,
          onTap: WindowChannel.toggleMaximize,
          background: background,
        ),
        const SizedBox(width: 6),
        _ControlButton(
          icon: Icons.close_rounded,
          onTap: WindowChannel.close,
          background: background,
          hoverColor: const Color(0xFFE81123),
          hoverIconColor: Colors.white,
        ),
      ],
    );
  }
}

class _ControlButton extends StatefulWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.background,
    this.hoverColor,
    this.hoverIconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color? hoverColor;
  final Color? hoverIconColor;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered
            ? (widget.hoverColor ?? widget.background)
            : widget.background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered && widget.hoverIconColor != null
                  ? widget.hoverIconColor
                  : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
