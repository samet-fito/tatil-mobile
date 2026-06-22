import 'package:flutter/services.dart';

/// Türkçe para formatı: binlik ayraç nokta (30.000).
class TurkishThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = formatTurkishInteger(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String formatTurkishInteger(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

int? parseTurkishInteger(String text) {
  final digits = text.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}
