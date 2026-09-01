/// Locale-aware number formatting, including the optional Persian-numeral
/// display mode. All user-facing numbers in the app go through here.
library;

const _persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// Converts ASCII digits in [input] to Persian numerals when [usePersian]
/// is true; otherwise returns the input unchanged.
String localizeDigits(String input, {required bool usePersian}) {
  if (!usePersian) return input;
  final buffer = StringBuffer();
  for (final code in input.codeUnits) {
    final index = code - 0x30; // '0'
    if (index >= 0 && index < 10) {
      buffer.write(_persianDigits[index]);
    } else {
      buffer.writeCharCode(code);
    }
  }
  return buffer.toString();
}

String formatNumber(
  int value, {
  required bool usePersian,
}) {
  return localizeDigits(
    value.toString(),
    usePersian: usePersian,
  );
}

String formatYear(int? year, {required bool usePersian}) {
  if (year == null || year <= 0) return '';
  return formatNumber(year, usePersian: usePersian);
}

String formatRating(double? rating, {required bool usePersian}) {
  if (rating == null || rating <= 0) return '';
  var text = rating.toStringAsFixed(1);
  if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
  return localizeDigits(text, usePersian: usePersian);
}

/// Formats a duration in minutes as a compact clock form, e.g. "1:47" /
/// "۱:۴۷". Returns null when [minutes] is missing or non-positive.
String? formatDuration(int? minutes, {required bool usePersian}) {
  if (minutes == null || minutes <= 0) return null;
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  final text = hours > 0 ? '$hours:${rest.toString().padLeft(2, '0')}' : '$rest';
  return localizeDigits(text, usePersian: usePersian);
}
