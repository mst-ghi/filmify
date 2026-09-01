import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../favorites/favorites_page.dart';
import '../home/home_page.dart';
import '../search/search_page.dart';
import '../settings/settings_page.dart';

/// Adaptive navigation shell: NavigationBar on compact (phones) and a
/// NavigationRail on wide (desktop/tablet) surfaces. Each destination keeps
/// its own Navigator state via [IndexedStack].
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      (icon: Icons.home_outlined, selected: Icons.home_rounded, label: l10n.navHome),
      (icon: Icons.search_outlined, selected: Icons.search_rounded, label: l10n.navSearch),
      (icon: Icons.favorite_outline_rounded,
          selected: Icons.favorite_rounded,
          label: l10n.navFavorites),
      (icon: Icons.settings_outlined,
          selected: Icons.settings_rounded,
          label: l10n.navSettings),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;

        final pages = const [
          HomePage(),
          SearchPage(),
          FavoritesPage(),
          SettingsPage(),
        ];

        final body = IndexedStack(index: _index, children: pages);

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: 0,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selected),
                        label: Text(d.label),
                      ),
                  ],
                ),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
