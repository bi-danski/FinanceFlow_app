import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount, BuildContext context, {String? symbol}) {
    // Using Intl.NumberFormat for locale-aware currency formatting.
    // You might want to fetch the locale from the context or a global setting.
    final format = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(), 
      symbol: symbol ?? NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString()).currencySymbol,
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  static String formatDate(DateTime date, {String format = 'MMM d, yyyy'}) {
    return DateFormat(format).format(date);
  }

  // Add other formatters as needed
}
