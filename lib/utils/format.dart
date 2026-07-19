import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(symbol: '\$');
final _date = DateFormat('MMM d, y · h:mm a');

String formatCurrency(num value) => _currency.format(value);

String formatDate(DateTime dt) => _date.format(dt.toLocal());

String formatPercent(double rate) => '${(rate * 100).toStringAsFixed(rate * 100 == (rate * 100).roundToDouble() ? 0 : 1)}%';
