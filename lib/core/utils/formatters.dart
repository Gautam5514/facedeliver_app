import 'package:intl/intl.dart';

/// Display helpers. The product is India-first (INR pricing, en-IN grouping),
/// which is why the locale is pinned rather than taken from the device.
class Format {
  const Format._();

  static final NumberFormat _grouped = NumberFormat.decimalPattern('en_IN');
  static final DateFormat _day = DateFormat('d MMM yyyy');
  static final DateFormat _dayShort = DateFormat('d MMM');
  static final DateFormat _weekday = DateFormat('EEE');

  static String count(num? value) => _grouped.format(value ?? 0);

  static String date(DateTime? value) =>
      value == null ? '—' : _day.format(value.toLocal());

  static String shortDate(DateTime? value) =>
      value == null ? '—' : _dayShort.format(value.toLocal());

  static String weekdayFromIso(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    return parsed == null ? '' : _weekday.format(parsed).substring(0, 1);
  }

  /// Razorpay amounts are in the smallest unit — paise for INR.
  static String money(int minorUnits, String currency) {
    final major = minorUnits / 100;
    final symbol = switch (currency.toUpperCase()) {
      'INR' => '₹',
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      _ => '${currency.toUpperCase()} ',
    };
    final formatter = NumberFormat.decimalPattern('en_IN')
      ..maximumFractionDigits = major == major.roundToDouble() ? 0 : 2;
    return '$symbol${formatter.format(major)}';
  }

  static String relative(DateTime? value) {
    if (value == null) return '—';
    final diff = DateTime.now().difference(value.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(value);
  }

  static String plural(int count, String singular, [String? plural]) =>
      count == 1 ? '$count $singular' : '$count ${plural ?? '${singular}s'}';

  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
