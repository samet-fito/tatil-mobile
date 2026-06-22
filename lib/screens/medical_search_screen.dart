import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/search_model.dart';
import '../theme/tatil_theme.dart';
import '../utils/turkish_number_input.dart';
import '../theme/custom_page_route.dart';
import 'medical_screen.dart';

/// Sağlık turizmi girişi — profilden erişilir, ana keşfet akışından ayrı.
class MedicalSearchScreen extends StatefulWidget {
  const MedicalSearchScreen({super.key});

  @override
  State<MedicalSearchScreen> createState() => _MedicalSearchScreenState();
}

class _MedicalSearchScreenState extends State<MedicalSearchScreen> {
  late SearchModel _model;
  bool _isLoading = false;
  late final TextEditingController _budgetController;

  final List<Map<String, String>> _origins = [
    {'iata': 'IST', 'city': 'İstanbul'},
    {'iata': 'AYT', 'city': 'Antalya'},
    {'iata': 'ESB', 'city': 'Ankara'},
    {'iata': 'ADB', 'city': 'İzmir'},
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _model = SearchModel();
    _budgetController = TextEditingController(
      text: formatTurkishInteger(_model.totalBudgetTL.toInt()),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  (String, String) _medicalHubForOrigin(String originIata) {
    const hubs = {
      'IST': ('IST', 'İstanbul'),
      'AYT': ('AYT', 'Antalya'),
      'ESB': ('IST', 'İstanbul'),
      'ADB': ('IST', 'İstanbul'),
    };
    return hubs[originIata] ?? ('IST', 'İstanbul');
  }

  Future<void> _search() async {
    final budget = parseTurkishInteger(_budgetController.text) ?? 0;
    if (budget >= 10000) {
      _model = _model.copyWith(totalBudgetTL: budget.toDouble());
    }
    if (!_model.isValid) {
      _showSnack('Lütfen bütçeyi girin (min 10.000 TL)', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _isLoading = false);

    final hub = _medicalHubForOrigin(_model.originIata);
    pushAppRoute(
      context,
      MedicalScreen(
        searchModel: _model,
        destinationIata: hub.$1,
        cityName: hub.$2,
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : TatilTheme.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${d.day} ${months[d.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TatilTheme.bgSoft,
      appBar: AppBar(
        backgroundColor: TatilTheme.bgSoft,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: TatilTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sağlık Turizmi',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: TatilTheme.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tedavi ve konaklama paketlerini bütçene göre keşfet.',
              style: TatilTheme.hint.copyWith(height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: TatilTheme.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOriginSelector(),
                  const SizedBox(height: 18),
                  _buildDateSelector(),
                  const SizedBox(height: 18),
                  _buildPassengerSelector(),
                  const SizedBox(height: 18),
                  _buildBudgetInput(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginSelector() {
    return _section(
      label: 'Nereden?',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TatilTheme.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _model.originIata,
            dropdownColor: Colors.white,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: TatilTheme.textMuted),
            items: _origins
                .map((o) => DropdownMenuItem(
                      value: o['iata'],
                      child: Text('${o['iata']} · ${o['city']}'),
                    ))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              final city = _origins.firstWhere((o) => o['iata'] == val)['city']!;
              setState(() => _model = _model.copyWith(originIata: val, originCity: city));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return _section(
      label: 'Ne zaman?',
      child: GestureDetector(
        onTap: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            initialDateRange: DateTimeRange(
              start: _model.departureDate,
              end: _model.returnDate,
            ),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: TatilTheme.teal,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: TatilTheme.textDark,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            setState(() {
              _model = _model.copyWith(
                departureDate: picked.start,
                returnDate: picked.end,
              );
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TatilTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gidiş', style: TatilTheme.hint),
                    Text(
                      _formatDate(_model.departureDate),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TatilTheme.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${_model.nights} gece',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TatilTheme.teal,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Dönüş', style: TatilTheme.hint),
                    Text(
                      _formatDate(_model.returnDate),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerSelector() {
    return _section(
      label: 'Kaç kişi?',
      child: Column(
        children: [
          _counterRow('Yetişkin', _model.passengers, 1, 9, (v) {
            setState(() => _model = _model.copyWith(passengers: v));
          }),
          const SizedBox(height: 12),
          _counterRow('Çocuk', _model.children, 0, 6, (v) {
            setState(() => _model = _model.copyWith(children: v));
          }),
        ],
      ),
    );
  }

  Widget _counterRow(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TatilTheme.sectionLabel.copyWith(fontSize: 13))),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(CupertinoIcons.minus_circle),
          color: TatilTheme.teal,
        ),
        Text('$value', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(CupertinoIcons.plus_circle),
          color: TatilTheme.teal,
        ),
      ],
    );
  }

  Widget _buildBudgetInput() {
    return _section(
      label: 'Bütçe',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TatilTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '30.000',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (text) {
                  final parsed = parseTurkishInteger(text);
                  if (parsed != null) {
                    setState(() => _model = _model.copyWith(totalBudgetTL: parsed.toDouble()));
                  } else if (text.isEmpty) {
                    setState(() => _model = _model.copyWith(totalBudgetTL: 0));
                  }
                },
              ),
            ),
            Text('TL', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: TatilTheme.teal)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Material(
      color: TatilTheme.teal,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _isLoading ? null : _search,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          alignment: Alignment.center,
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'Paketleri Bul',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _section({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TatilTheme.sectionLabel),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
