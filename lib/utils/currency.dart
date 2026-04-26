import 'package:intl/intl.dart';

String formatNaira(double? amount) {
  final formatter = NumberFormat.currency(locale: "en_NG", symbol: "₦");
  return formatter.format(amount ?? 0.0);
}