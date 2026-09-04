import 'package:flutter/material.dart';

import '../../core/state/app_settings.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common/gradient_background.dart';
import '../shell/home_shell.dart';

/// First-run onboarding: a warm welcome plus quick setup (language, accent
/// color, theme, Persian numerals, automatic updates). Each choice applies
/// live because the whole app rebuilds on settings changes; Finish lands on
/// the home shell.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _steps = 4;

  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final settings = AppScope.of(context).settings;
    await settings.setOnboardingDone(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppScope.of(context).settings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    _WelcomeStep(
                      onGetStarted: () => _goTo(1),
                    ),
                    const _LanguageStep(),
                    const _ColorStep(),
                    _LooksStep(settings: settings),
                  ],
                ),
              ),
              _footer(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _index == _steps - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          // Back (hidden on the first step).
          if (_index > 0)
            IconButton(
              tooltip: l10n.onbBack,
              onPressed: () => _goTo(_index - 1),
              icon: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_back_rounded,
              ),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          // Step dots.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _steps; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Next / Finish.
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: isLast ? _finish : () => _goTo(_index + 1),
              icon: Icon(
                isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: Text(isLast ? l10n.onbFinish : l10n.onbNext),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared scaffolding for a setup step: centered, max-width content with an
/// icon chip, title and subtitle.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: 0.16),
                        scheme.secondary.withValues(alpha: 0.16),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, size: 32, color: scheme.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall!
                    .copyWith(fontWeight: FontWeight.w800, height: 1.3),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium!
                    .copyWith(color: scheme.onSurfaceVariant, height: 1.6),
              ),
              const SizedBox(height: 32),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 0 — animated welcome.
class _WelcomeStep extends StatefulWidget {
  const _WelcomeStep({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  State<_WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<_WelcomeStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(_fade);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [scheme.primary, scheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 32,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.movie_filter_rounded,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    l10n.onbWelcomeTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall!
                        .copyWith(fontWeight: FontWeight.w900, height: 1.15),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.onbWelcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge!
                        .copyWith(color: scheme.onSurfaceVariant, height: 1.7),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: widget.onGetStarted,
                      icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                      label: Text(l10n.onbGetStarted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 1 — language choice (mirrors the Settings control).
class _LanguageStep extends StatelessWidget {
  const _LanguageStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppScope.of(context).settings;
    return _StepScaffold(
      icon: Icons.language_rounded,
      title: l10n.onbLanguageTitle,
      subtitle: l10n.onbLanguageSubtitle,
      child: Center(
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'system', label: Text('A')),
            ButtonSegment(value: 'en', label: Text('EN')),
            ButtonSegment(value: 'fa', label: Text('FA')),
          ],
          selected: {settings.localeTag},
          onSelectionChanged: (selection) =>
              settings.setLocaleTag(selection.first),
        ),
      ),
    );
  }
}

/// Step 2 — accent color picker.
class _ColorStep extends StatelessWidget {
  const _ColorStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppScope.of(context).settings;
    return _StepScaffold(
      icon: Icons.palette_rounded,
      title: l10n.onbColorTitle,
      subtitle: l10n.onbColorSubtitle,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 18,
        runSpacing: 18,
        children: [
          for (final accent in appAccents)
            _AccentSwatch(
              accent: accent,
              selected: settings.accentColor == accent.id,
              label: _accentLabel(l10n, accent.id),
              onTap: () => settings.setAccentColor(accent.id),
            ),
        ],
      ),
    );
  }
}

/// Step 3 — theme, Persian numerals, automatic updates.
class _LooksStep extends StatelessWidget {
  const _LooksStep({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = settings;
    return _StepScaffold(
      icon: Icons.tune_rounded,
      title: l10n.onbLooksTitle,
      subtitle: l10n.onbLooksSubtitle,
      child: Column(
        children: [
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                label: Text(l10n.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_rounded, size: 18),
                label: Text(l10n.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_rounded, size: 18),
                label: Text(l10n.themeDark),
              ),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (selection) => s.setThemeMode(selection.first),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.tag_rounded),
            title: Text(l10n.persianNumerals),
            subtitle: Text(l10n.persianNumeralsDesc),
            value: s.persianNumerals,
            onChanged: s.setPersianNumerals,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.sync_rounded),
            title: Text(l10n.autoUpdate),
            subtitle: Text(l10n.autoUpdateDesc),
            value: s.autoUpdate,
            onChanged: s.setAutoUpdate,
          ),
        ],
      ),
    );
  }
}

/// Circular accent swatch with label; highlight ring + check when selected.
class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final AppAccent accent;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accent.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? accent.bright : Colors.transparent,
                width: 3,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.primary.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: selected
                ? Icon(
                    Icons.check_rounded,
                    color: _swatchCheckColor(accent),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Color _swatchCheckColor(AppAccent accent) {
    // Keep the check readable on the palette swatch.
    return accent.id == 'green' ? const Color(0xFF0F172A) : Colors.white;
  }
}

String _accentLabel(AppLocalizations l10n, String id) => switch (id) {
      'blue' => l10n.accentBlue,
      'green' => l10n.accentGreen,
      'orange' => l10n.accentOrange,
      'rose' => l10n.accentRose,
      'teal' => l10n.accentTeal,
      _ => l10n.accentPurple,
    };