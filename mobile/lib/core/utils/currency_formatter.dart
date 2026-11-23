import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format as standard Indian Rupee string without decimals, e.g. ₹320 (even if amount is 320.26)
  static String format(num amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _inrWithDecimals.format(amount);
    }
    return _inrFormat.format(amount.truncate());
  }

  /// Format with explicit + or - sign, e.g. +₹500 or -₹200
  static String formatSigned(num amount, {bool isCredit = true, bool showDecimals = false}) {
    final formatted = format(amount.abs(), showDecimals: showDecimals);
    return isCredit ? '+$formatted' : '-$formatted';
  }

  /// Compact representation for charts or small badges, e.g., ₹24.5K or ₹1.8L
  static String formatCompact(num amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}k';
    }
    return format(amount);
  }
}
