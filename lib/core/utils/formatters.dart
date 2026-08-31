import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
  );

  static String currency(num? amount) {
    if (amount == null) return '₹0.00';
    return _currencyFormat.format(amount);
  }

  static String compactCurrency(num? amount) {
    if (amount == null) return '₹0';
    return _compactCurrencyFormat.format(amount);
  }

  static String formatQuantity(num? quantity, String unit) {
    if (quantity == null) return '0 $unit';
    // If quantity is whole number, format without decimals, else with up to 3 decimals
    final formatted = (quantity % 1 == 0)
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(quantity.toString().split('.').length > 1 && quantity.toString().split('.')[1].length > 2 ? 3 : 2);
    return '$formatted $unit';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('hh:mm a').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatSaleNumber(int? number) {
    if (number == null) return '#----';
    return '#${number.toString().padLeft(4, '0')}';
  }
}
