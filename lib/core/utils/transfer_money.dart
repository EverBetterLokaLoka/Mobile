import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat("#,###", "vi_VN");

  static String formatVnd(dynamic value) {
    if (value == null) return "0 VND";

    int intValue = (value is double && value == value.toInt())
        ? value.toInt()
        : int.tryParse(value.toString()) ?? 0;

    return "${_formatter.format(intValue)} VND";
  }
}