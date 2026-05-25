import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/search_model.dart';
import '../theme/app_theme.dart';
import '../widgets/continent_selector.dart';
import '../widgets/holiday_type_selector.dart';
import '../widgets/budget_slider.dart';
import '../widgets/date_range_picker.dart' as drp;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late SearchModel _model;
  late AnimationController _healthAnimController;
  late Animation<double> _healthAnim;
  bool _isLoading = false;

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
    _healthAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _healthAnim = CurvedAnimation(
      parent: _healthAnimController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _healthAnimController.dispose();
    super.dispose();
  }

  void _onHolidayTypeChanged(String? type) {
    setState(() {
      _model = _model.copyWith(holidayType: type);
    });
    if (type == 'health') {
      _healthAnimController.forward();
    } else {
      _healthAnimController.reverse();
    }
  }

  Future<void> _search() async {
    if (!_model.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: API çağrısı burada yapılacak
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚀 Paketler aranıyor... (Backend bağlantısı yakında!)'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHealth = _model.holidayType == 'health';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: isHealth ? AppTheme.health : AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isHealth
                        ? [AppTheme.health, const Color(0xFF5B21B6)]
                        : [AppTheme.primary, const Color(0xFF1D3461)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isHealth ? '🏥' : '✈️',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Tatil Bulucu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isHealth
                              ? 'Sağlık & Güzellik Turizmi 🌟'
                              : 'Selam! Tatil planını yapmaya hazır mısın?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          isHealth
                              ? 'Dünya standartlarında sağlık hizmeti'
                              : 'Bütçeni söyle, rüya rotanı çıkaralım.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // İçerik
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kalkış Şehri
                  _SectionLabel(label: '🛫 Nereden Gidiyorsun?'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.black.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _model.originIata,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _origins.map((o) {
                          return DropdownMenuItem(
                            value: o['iata'],
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    o['iata']!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  o['city']!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final city = _origins
                                .firstWhere((o) => o['iata'] == val)['city']!;
                            setState(() {
                              _model = _model.copyWith(
                                originIata: val,
                                originCity: city,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Kıta Seçimi
                  _SectionLabel(label: '🌍 Nereye Gitmek İstiyorsun?'),
                  const SizedBox(height: 8),
                  ContinentSelector(
                    selected: _model.continent,
                    onChanged: (val) =>
                        setState(() => _model = _model.copyWith(continent: val)),
                  ),

                  const SizedBox(height: 20),

                  // Tatil Türü
                  _SectionLabel(label: '🎯 Nasıl Bir Tatil İstiyorsun?'),
                  const SizedBox(height: 8),
                  HolidayTypeSelector(
                    selected: _model.holidayType,
                    onChanged: _onHolidayTypeChanged,
                  ),

                  const SizedBox(height: 20),

                  // Tarih Seçici
                  _SectionLabel(label: '📅 Ne Zaman Gidiyorsun?'),
                  const SizedBox(height: 8),
                  drp.DateRangePicker(
                    departureDate: _model.departureDate,
                    returnDate: _model.returnDate,
                    onChanged: (dep, ret) => setState(() {
                      _model = _model.copyWith(
                        departureDate: dep,
                        returnDate: ret,
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Yolcu Sayısı
                  _SectionLabel(label: '👥 Kaç Kişi?'),
                  const SizedBox(height: 8),
                  Row(
                    children: [1, 2, 3, 4].map((n) {
                      final isSelected = _model.passengers == n;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _model = _model.copyWith(passengers: n)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accent
                                  : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accent
                                    : Colors.black.withOpacity(0.08),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$n',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  n == 1 ? 'kişi' : 'kişi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.8)
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Bütçe Slider
                  _SectionLabel(label: '💰 Toplam Bütçen Ne Kadar?'),
                  const SizedBox(height: 8),
                  BudgetSlider(
                    value: _model.totalBudgetTL,
                    maxValue: _model.budgetSliderMax,
                    isHealthMode: isHealth,
                    onChanged: (val) => setState(
                        () => _model = _model.copyWith(totalBudgetTL: val)),
                  ),

                  const SizedBox(height: 32),

                  // Ana Buton
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isHealth
                              ? [AppTheme.health, const Color(0xFF5B21B6)]
                              : [AppTheme.accent, const Color(0xFF0F6E56)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isHealth ? AppTheme.health : AppTheme.accent)
                                .withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _search,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                isHealth
                                    ? '🏥 Sağlık Paketi Bul!'
                                    : '🚀 Beni Şaşırt ve Paketle!',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}