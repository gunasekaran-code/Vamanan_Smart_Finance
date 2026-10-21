import 'package:intl/intl.dart';

/// Rupee amounts with Indian digit grouping (₹1,49,999.00).
final NumberFormat _inr2 =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final NumberFormat _inr0 =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

/// `₹1,76,998.82`
String formatInr(double amount) => _inr2.format(amount);

/// `₹1,49,999` — whole rupees drop the paise; fractional amounts keep them.
String formatInrCompact(double amount) =>
    amount == amount.roundToDouble() ? _inr0.format(amount) : _inr2.format(amount);
