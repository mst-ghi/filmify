import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import 'formatting.dart';

/// Numeral-aware formatting helpers bound to the widget's [AppScope], so call
/// sites stay short and automatically respect the Persian-numerals setting.
extension LocalizedNumbers on BuildContext {
  bool get usePersianNumerals => AppScope.of(this).settings.persianNumerals;

  String numbers(int value) =>
      formatNumber(value, usePersian: usePersianNumerals);

  String year(int? value) => formatYear(value, usePersian: usePersianNumerals);

  String rating(double? value) =>
      formatRating(value, usePersian: usePersianNumerals);

  String? duration(int? minutes) =>
      formatDuration(minutes, usePersian: usePersianNumerals);

  String digits(String input) =>
      localizeDigits(input, usePersian: usePersianNumerals);
}
