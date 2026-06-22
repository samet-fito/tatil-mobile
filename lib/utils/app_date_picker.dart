import 'package:flutter/material.dart';

/// Türkçe Material tarih seçici — `MaterialLocalizations` gerektirir.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    locale: const Locale('tr', 'TR'),
    helpText: 'Tarih seçin',
    cancelText: 'İptal',
    confirmText: 'Tamam',
  );
}
