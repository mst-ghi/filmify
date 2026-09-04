import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Filmify'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get homeTitle;

  /// No description provided for @filterNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get filterNewest;

  /// No description provided for @filterTop.
  ///
  /// In en, this message translates to:
  /// **'Top IMDb'**
  String get filterTop;

  /// No description provided for @filterByYear.
  ///
  /// In en, this message translates to:
  /// **'By Year'**
  String get filterByYear;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The server returned an error ({code}).'**
  String errorServer(int code);

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorUnexpected;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No movies found'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or check back later.'**
  String get homeEmptySubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search movies…'**
  String get searchHint;

  /// No description provided for @searchInitialTitle.
  ///
  /// In en, this message translates to:
  /// **'Start exploring'**
  String get searchInitialTitle;

  /// No description provided for @searchInitialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search for any movie by its title.'**
  String get searchInitialSubtitle;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find anything for “{query}”.'**
  String searchEmptySubtitle(String query);

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchHistory;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearHistory;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any movie to keep it here.'**
  String get favoritesEmptySubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get langSystem;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langPersian.
  ///
  /// In en, this message translates to:
  /// **'فارسی'**
  String get langPersian;

  /// No description provided for @persianNumerals.
  ///
  /// In en, this message translates to:
  /// **'Persian numerals'**
  String get persianNumerals;

  /// No description provided for @persianNumeralsDesc.
  ///
  /// In en, this message translates to:
  /// **'Show digits in Persian script'**
  String get persianNumeralsDesc;

  /// No description provided for @apiSection.
  ///
  /// In en, this message translates to:
  /// **'API'**
  String get apiSection;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKey;

  /// No description provided for @apiKeyDesc.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the built-in default key.'**
  String get apiKeyDesc;

  /// No description provided for @apiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API key updated'**
  String get apiKeySaved;

  /// No description provided for @updatesSection.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesSection;

  /// No description provided for @autoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Automatic updates'**
  String get autoUpdate;

  /// No description provided for @autoUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Check for new versions on startup'**
  String get autoUpdateDesc;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get updateStatus;

  /// No description provided for @updateCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheckNow;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updateChecking;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates.'**
  String get updateCheckFailed;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get updateUpToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get updateAvailable;

  /// No description provided for @updateNewVersion.
  ///
  /// In en, this message translates to:
  /// **'New version {latest} available (you have {current})'**
  String updateNewVersion(String current, String latest);

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updateDownload;

  /// No description provided for @updateProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String updateProgress(int percent);

  /// No description provided for @updateInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get updateInstall;

  /// No description provided for @updateOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Open releases page'**
  String get updateOpenPage;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateTitle;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @latestRelease.
  ///
  /// In en, this message translates to:
  /// **'Latest release'**
  String get latestRelease;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share app link'**
  String get shareApp;

  /// No description provided for @viewedBadge.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get viewedBadge;

  /// No description provided for @markSeen.
  ///
  /// In en, this message translates to:
  /// **'Mark as seen'**
  String get markSeen;

  /// No description provided for @unmarkSeen.
  ///
  /// In en, this message translates to:
  /// **'Mark as unseen'**
  String get unmarkSeen;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @noDuration.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get noDuration;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Download sources'**
  String get sources;

  /// No description provided for @noDownloadLinks.
  ///
  /// In en, this message translates to:
  /// **'No download links available.'**
  String get noDownloadLinks;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all links'**
  String get copyAll;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link.'**
  String get openFailed;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @playerFailed.
  ///
  /// In en, this message translates to:
  /// **'Playback failed. The link may be unavailable.'**
  String get playerFailed;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get description;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No story available for this title.'**
  String get noDescription;

  /// No description provided for @countries.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countries;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
