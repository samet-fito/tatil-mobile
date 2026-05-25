import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/search_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const TatilBulucuApp());
}

class TatilBulucuApp extends StatelessWidget {
  const TatilBulucuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tatil Bulucu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SearchScreen(),
    );
  }
}