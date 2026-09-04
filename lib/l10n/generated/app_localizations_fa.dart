// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'Filmify';

  @override
  String get navHome => 'خانه';

  @override
  String get navSearch => 'جست‌وجو';

  @override
  String get navFavorites => 'علاقه‌مندی‌ها';

  @override
  String get navSettings => 'تنظیمات';

  @override
  String get homeTitle => 'کشف کنید';

  @override
  String get filterNewest => 'جدیدترین';

  @override
  String get filterTop => 'برترین‌های IMDb';

  @override
  String get filterByYear => 'بر اساس سال';

  @override
  String get retry => 'تلاش دوباره';

  @override
  String get errorNetwork =>
      'اتصال به سرور برقرار نشد. اینترنت خود را بررسی کنید.';

  @override
  String errorServer(int code) {
    return 'سرور خطا برگرداند ($code).';
  }

  @override
  String get errorUnexpected => 'مشکلی پیش آمد.';

  @override
  String get homeEmptyTitle => 'فیلمی پیدا نشد';

  @override
  String get homeEmptySubtitle =>
      'فیلتر دیگری را امتحان کنید یا بعداً سر بزنید.';

  @override
  String get searchHint => 'جست‌وجوی فیلم…';

  @override
  String get searchInitialTitle => 'شروع کنید';

  @override
  String get searchInitialSubtitle => 'نام هر فیلمی را جست‌وجو کنید.';

  @override
  String get searchEmptyTitle => 'نتیجه‌ای نبود';

  @override
  String searchEmptySubtitle(String query) {
    return 'چیزی برای «$query» پیدا نکردیم.';
  }

  @override
  String get searchHistory => 'جست‌وجوهای اخیر';

  @override
  String get clearHistory => 'پاک کردن';

  @override
  String get favoritesTitle => 'علاقه‌مندی‌ها';

  @override
  String get favoritesEmptyTitle => 'هنوز علاقه‌مندی نیست';

  @override
  String get favoritesEmptySubtitle =>
      'روی قلب هر فیلم بزنید تا اینجا ذخیره شود.';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get appearance => 'ظاهر';

  @override
  String get themeMode => 'پوسته';

  @override
  String get themeSystem => 'سیستم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تاریک';

  @override
  String get language => 'زبان';

  @override
  String get langSystem => 'سیستم';

  @override
  String get langEnglish => 'English';

  @override
  String get langPersian => 'فارسی';

  @override
  String get persianNumerals => 'اعداد فارسی';

  @override
  String get persianNumeralsDesc => 'نمایش ارقام با خط فارسی';

  @override
  String get apiSection => 'رابط برنامه‌نویسی';

  @override
  String get apiKey => 'کلید API';

  @override
  String get apiKeyDesc => 'برای استفاده از کلید پیش‌فرض، خالی بگذارید.';

  @override
  String get apiKeySaved => 'کلید API به‌روزرسانی شد';

  @override
  String get updatesSection => 'به‌روزرسانی';

  @override
  String get autoUpdate => 'به‌روزرسانی خودکار';

  @override
  String get autoUpdateDesc => 'بررسی نسخه جدید هنگام شروع برنامه';

  @override
  String get updateStatus => 'وضعیت';

  @override
  String get updateCheckNow => 'بررسی به‌روزرسانی';

  @override
  String get updateChecking => 'در حال بررسی…';

  @override
  String get updateCheckFailed => 'بررسی به‌روزرسانی ممکن نشد.';

  @override
  String get updateUpToDate => 'برنامه به‌روز است';

  @override
  String get updateAvailable => 'نسخه جدید موجود است';

  @override
  String updateNewVersion(String current, String latest) {
    return 'نسخه جدید $latest موجود است (نسخه فعلی $current)';
  }

  @override
  String get updateDownload => 'دانلود';

  @override
  String updateProgress(int percent) {
    return 'در حال دانلود… $percent٪';
  }

  @override
  String get updateInstall => 'نصب';

  @override
  String get updateOpenPage => 'باز کردن صفحه انتشار';

  @override
  String get updateTitle => 'به‌روزرسانی';

  @override
  String get aboutSection => 'درباره';

  @override
  String get version => 'نسخه';

  @override
  String get latestRelease => 'آخرین نسخه';

  @override
  String get shareApp => 'هم‌رسانی لینک برنامه';

  @override
  String get viewedBadge => 'دیده‌شده';

  @override
  String get markSeen => 'دیده‌شده علامت بزن';

  @override
  String get unmarkSeen => 'برداشتن علامت';

  @override
  String get addedToFavorites => 'به علاقه‌مندی‌ها اضافه شد';

  @override
  String get removedFromFavorites => 'از علاقه‌مندی‌ها حذف شد';

  @override
  String get year => 'سال';

  @override
  String get rating => 'امتیاز';

  @override
  String durationMinutes(int minutes) {
    return '$minutes دقیقه';
  }

  @override
  String get noDuration => 'نامشخص';

  @override
  String get sources => 'منابع دانلود';

  @override
  String get noDownloadLinks => 'لینک دانلودی موجود نیست.';

  @override
  String get download => 'دانلود';

  @override
  String get copyLink => 'کپی لینک';

  @override
  String get share => 'هم‌رسانی';

  @override
  String get copyAll => 'کپی همه لینک‌ها';

  @override
  String get copied => 'در حافظه کپی شد';

  @override
  String get openFailed => 'باز کردن لینک ممکن نشد.';

  @override
  String get play => 'پخش';

  @override
  String get playerFailed => 'پخش ممکن نشد. ممکن است لینک در دسترس نباشد.';

  @override
  String get description => 'داستان';

  @override
  String get noDescription => 'برای این فیلم داستانی ثبت نشده است.';

  @override
  String get countries => 'کشور';
}
