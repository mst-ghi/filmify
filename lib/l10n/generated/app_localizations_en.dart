// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Filmify';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeTitle => 'Discover';

  @override
  String get filterNewest => 'Newest';

  @override
  String get filterTop => 'Top IMDb';

  @override
  String get filterByYear => 'By Year';

  @override
  String get retry => 'Retry';

  @override
  String get errorNetwork =>
      'Couldn\'t reach the server. Check your connection.';

  @override
  String errorServer(int code) {
    return 'The server returned an error ($code).';
  }

  @override
  String get errorUnexpected => 'Something went wrong.';

  @override
  String get homeEmptyTitle => 'No movies found';

  @override
  String get homeEmptySubtitle => 'Try a different filter or check back later.';

  @override
  String get searchHint => 'Search movies…';

  @override
  String get searchInitialTitle => 'Start exploring';

  @override
  String get searchInitialSubtitle => 'Search for any movie by its title.';

  @override
  String get searchEmptyTitle => 'No results';

  @override
  String searchEmptySubtitle(String query) {
    return 'We couldn\'t find anything for “$query”.';
  }

  @override
  String get searchHistory => 'Recent searches';

  @override
  String get clearHistory => 'Clear';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptySubtitle =>
      'Tap the heart on any movie to keep it here.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get langSystem => 'System';

  @override
  String get langEnglish => 'English';

  @override
  String get langPersian => 'فارسی';

  @override
  String get persianNumerals => 'Persian numerals';

  @override
  String get persianNumeralsDesc => 'Show digits in Persian script';

  @override
  String get apiSection => 'API';

  @override
  String get apiKey => 'API key';

  @override
  String get apiKeyDesc => 'Leave empty to use the built-in default key.';

  @override
  String get apiKeySaved => 'API key updated';

  @override
  String get updatesSection => 'Updates';

  @override
  String get autoUpdate => 'Automatic updates';

  @override
  String get autoUpdateDesc => 'Check for new versions on startup';

  @override
  String get updateStatus => 'Status';

  @override
  String get updateCheckNow => 'Check for updates';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateCheckFailed => 'Couldn\'t check for updates.';

  @override
  String get updateUpToDate => 'You\'re up to date';

  @override
  String get updateAvailable => 'New version available';

  @override
  String updateNewVersion(String current, String latest) {
    return 'New version $latest available (you have $current)';
  }

  @override
  String get updateDownload => 'Download';

  @override
  String updateProgress(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get updateInstall => 'Install';

  @override
  String get updateOpenPage => 'Open releases page';

  @override
  String get updateTitle => 'Update';

  @override
  String get aboutSection => 'About';

  @override
  String get version => 'Version';

  @override
  String get latestRelease => 'Latest release';

  @override
  String get shareApp => 'Share app link';

  @override
  String get viewedBadge => 'Seen';

  @override
  String get markSeen => 'Mark as seen';

  @override
  String get unmarkSeen => 'Mark as unseen';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get onbWelcomeTitle => 'Welcome to Filmify';

  @override
  String get onbWelcomeSubtitle =>
      'Discover, browse and download movies in English or Persian — all in one beautiful app.';

  @override
  String get onbGetStarted => 'Get started';

  @override
  String get onbNext => 'Next';

  @override
  String get onbBack => 'Back';

  @override
  String get onbFinish => 'Finish';

  @override
  String get onbLanguageTitle => 'Choose your language';

  @override
  String get onbLanguageSubtitle => 'You can change this anytime in Settings.';

  @override
  String get onbColorTitle => 'Pick your color';

  @override
  String get onbColorSubtitle => 'Choose the accent that looks best to you.';

  @override
  String get onbLooksTitle => 'Make it yours';

  @override
  String get onbLooksSubtitle =>
      'Tune a few last details — you can always change them later.';

  @override
  String get accentColor => 'Accent color';

  @override
  String get accentPurple => 'Purple';

  @override
  String get accentBlue => 'Blue';

  @override
  String get accentGreen => 'Green';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentRose => 'Rose';

  @override
  String get accentTeal => 'Teal';

  @override
  String get showWelcomeAgain => 'Show welcome again';

  @override
  String get showWelcomeAgainDesc =>
      'Play the onboarding screens on next launch';

  @override
  String get showWelcomeAgainDone => 'Onboarding will show on next launch';

  @override
  String get year => 'Year';

  @override
  String get rating => 'Rating';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get noDuration => 'Unknown';

  @override
  String get sources => 'Download sources';

  @override
  String get noDownloadLinks => 'No download links available.';

  @override
  String get download => 'Download';

  @override
  String get copyLink => 'Copy link';

  @override
  String get share => 'Share';

  @override
  String get copyAll => 'Copy all links';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get openFailed => 'Couldn\'t open the link.';

  @override
  String get play => 'Play';

  @override
  String get playerFailed => 'Playback failed. The link may be unavailable.';

  @override
  String get description => 'Story';

  @override
  String get noDescription => 'No story available for this title.';

  @override
  String get countries => 'Country';
}
