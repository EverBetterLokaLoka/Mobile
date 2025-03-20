import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat("#,###", "vi_VN");

  static String formatVnd(dynamic value) {
    if (value == null) return "0 VNĐ";

    double doubleValue;
    if (value is String) {
      String cleanedValue = value.replaceAll(RegExp(r'[^\d.]'), '');
      doubleValue = double.parse(cleanedValue);
    } else {
      doubleValue = double.tryParse(value.toString()) ?? 0.0;
    }

    int intValue = doubleValue.round();

    return "${_formatter.format(intValue)} VNĐ";
  }
}