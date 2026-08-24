import 'package:intl/intl.dart';

class AppFormatters {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final NumberFormat _currencyFormat = NumberFormat('#,##0');

  static const List<String> _monthsFr = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatMonthYear(DateTime date) {
    if (date.month >= 1 && date.month <= 12) {
      return '${_monthsFr[date.month - 1]} ${date.year}';
    }
    return '${date.month}/${date.year}';
  }

  static String formatLongDate(DateTime date) {
    if (date.month >= 1 && date.month <= 12) {
      return '${date.day} ${_monthsFr[date.month - 1]} ${date.year}';
    }
    return _dateFormat.format(date);
  }

  static String formatAmount(double amount, [String currency = 'FCFA']) {
    return '${_currencyFormat.format(amount)} $currency';
  }

  static String formatCurrency(double amount, [String currency = 'FCFA']) {
    return formatAmount(amount, currency);
  }
}
