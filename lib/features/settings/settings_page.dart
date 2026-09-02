import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/movie_api_client.dart';
import '../../core/state/app_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/movie_card.dart';

/// Settings tab: appearance (theme mode), language, Persian numerals, API key
/// override, about (version).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _releaseUrl = 'https://github.com/mst-ghi/filmify/releases/latest';

  TextEditingController? _apiKey;
  PackageInfo? _info;
  bool _obscureKey = true;

  void _copyReleaseLink(AppLocalizations l10n) {
    Clipboard.setData(const ClipboardData(text: _releaseUrl));
    showAppSnackbar(context, l10n.copied);
  }

  Future<void> _shareReleaseLink() async {
    await SharePlus.instance.share(
      ShareParams(text: _releaseUrl, title: 'Filmify'),
    );
  }

  Future<void> _openReleasePage() async {
    final uri = Uri.tryParse(_releaseUrl);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        showAppSnackbar(context, AppLocalizations.of(context).openFailed);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppScope isn't reachable in initState, so seed the controller here.
    _apiKey ??= TextEditingController(
      text: AppScope.of(context).settings.apiKey,
    );
  }

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  @override
  void dispose() {
    _apiKey?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppScope.of(context).settings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: GradientBackground(
        child: AnimatedBuilder(
          animation: settings,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _Section(title: l10n.appearance, children: [
                  // Theme mode.
                  ListTile(
                    leading: const Icon(Icons.brightness_6_rounded),
                    title: Text(l10n.themeMode),
                    subtitle: Text(switch (settings.themeMode) {
                      ThemeMode.light => l10n.themeLight,
                      ThemeMode.dark => l10n.themeDark,
                      ThemeMode.system => l10n.themeSystem,
                    }),
                    trailing: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.settings_suggest_rounded,
                              size: 18),
                          tooltip: l10n.themeSystem,
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_rounded, size: 18),
                          tooltip: l10n.themeLight,
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_rounded, size: 18),
                          tooltip: l10n.themeDark,
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (selection) =>
                          settings.setThemeMode(selection.first),
                    ),
                  ),
                  // Language.
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: Text(l10n.language),
                    subtitle: Text(switch (settings.localeTag) {
                      'en' => l10n.langEnglish,
                      'fa' => l10n.langPersian,
                      _ => l10n.langSystem,
                    }),
                    trailing: SegmentedButton<String>(
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
                  SwitchListTile(
                    secondary: const Icon(Icons.tag_rounded),
                    title: Text(l10n.persianNumerals),
                    subtitle: Text(l10n.persianNumeralsDesc),
                    value: settings.persianNumerals,
                    onChanged: settings.setPersianNumerals,
                  ),
                ]),
                const SizedBox(height: 16),
                _Section(title: l10n.apiSection, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      l10n.apiKeyDesc,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.key_rounded),
                    title: Text(l10n.apiKey),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: _apiKey!,
                        obscureText: _obscureKey,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(_obscureKey
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _obscureKey = !_obscureKey),
                              ),
                            ],
                          ),
                          hintText: MovieApiClient.defaultApiKey,
                        ),
                        onSubmitted: (value) async {
                          await settings.setApiKey(value);
                          if (!context.mounted) return;
                          showAppSnackbar(context, l10n.apiKeySaved);
                        },
                      ),
                    ),
                    isThreeLine: true,
                  ),
                ]),
                const SizedBox(height: 16),
                _Section(title: l10n.aboutSection, children: [
                  ListTile(
                    leading: const Icon(Icons.verified_rounded),
                    title: Text(l10n.version),
                    trailing: Text(
                      _info?.version ?? '…',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const ListTile(
                    leading: Icon(Icons.movie_filter_rounded),
                    title: Text('Filmify'),
                    subtitle: Text('Bilingual movie discovery & download hub'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.new_releases_rounded),
                    title: Text(l10n.latestRelease),
                    subtitle: const Text(
                      'github.com/mst-ghi/filmify/releases/latest',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.copyLink,
                          onPressed: () => _copyReleaseLink(l10n),
                          icon: const Icon(Icons.copy_rounded, size: 20),
                        ),
                        IconButton(
                          tooltip: l10n.share,
                          onPressed: _shareReleaseLink,
                          icon: const Icon(Icons.share_rounded, size: 20),
                        ),
                        IconButton(
                          tooltip: l10n.download,
                          onPressed: _openReleasePage,
                          icon: Icon(
                            Icons.open_in_new_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.ios_share_rounded),
                    title: Text(l10n.shareApp),
                    onTap: _shareReleaseLink,
                  ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Rounded card grouping related settings rows.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}
