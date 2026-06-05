import 'package:flutter/cupertino.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/search_model.dart';
import '../theme/app_theme.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'route_results_screen.dart';
import 'medical_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late SearchModel _model;
  bool _isLoading = false;
  bool _isMedicalMode = false;
  List<Map<String, dynamic>> _flashDeals = [];

  final List<Map<String, String>> _origins = [
    {'iata': 'IST', 'city': 'İstanbul'},
    {'iata': 'AYT', 'city': 'Antalya'},
    {'iata': 'ESB', 'city': 'Ankara'},
    {'iata': 'ADB', 'city': 'İzmir'},
  ];

  final List<Map<String, dynamic>> _continents = [
    {'value': null, 'label': 'Tümü', 'emoji': '🌍'},
    {'value': 'domestic', 'label': 'Yurtiçi', 'emoji': '🇹🇷'},
    {'value': 'europe', 'label': 'Avrupa', 'emoji': '🏰'},
    {'value': 'asia', 'label': 'Asya', 'emoji': '🌏'},
    {'value': 'middleeast', 'label': 'Orta Doğu', 'emoji': '🕌'},
    {'value': 'america', 'label': 'Amerika', 'emoji': '🗽'},
  ];

  final List<Map<String, dynamic>> _holidayTypes = [
    {'value': null, 'label': 'Hepsi', 'emoji': '✨'},
    {'value': 'beach', 'label': 'Deniz', 'emoji': '🏖️'},
    {'value': 'culture', 'label': 'Kültür', 'emoji': '🏛️'},
    {'value': 'nature', 'label': 'Doğa', 'emoji': '🌿'},
    {'value': 'city', 'label': 'Şehir', 'emoji': '🏙️'},
  ];

  String? _selectedContinent;
  String? _selectedHolidayType;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _model = SearchModel();
    _loadFlashDeals();
  }

  Future<void> _loadFlashDeals() async {
    final deals = await ApiService.getFlashDeals();
    if (mounted) setState(() => _flashDeals = deals);
  }

  Future<void> _search() async {
    if (!_model.isValid) {
      _showSnack('Lütfen bütçeyi girin (min 10.000 TL)', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() => _isLoading = false);
    if (!mounted) return;

    if (_isMedicalMode) {
      Navigator.push(context, MaterialPageRoute(
        builder: (ctx) => MedicalScreen(
          searchModel: _model,
          destinationIata: _model.originIata == 'IST' ? 'IST' : 'AYT',
          cityName: _model.originIata == 'IST' ? 'İstanbul' : 'Antalya',
          flightCostTL: _model.totalBudgetTL * 0.10,
        ),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (ctx) => RouteResultsScreen(searchModel: _model),
      ));
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.accent : AppTheme.teal,
    ));
  }

  String _formatBudget(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M TL';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K TL';
    return '${v.toInt()} TL';
  }

  String _formatDate(DateTime d) {
    const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
        'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${d.day} ${months[d.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildModeToggle(),
                    const SizedBox(height: 28),
                    _buildOriginSelector(),
                    const SizedBox(height: 20),
                    _buildDateSelector(),
                    const SizedBox(height: 20),
                    if (!_isMedicalMode) ...[
                      _buildContinentSelector(),
                      const SizedBox(height: 20),
                      _buildHolidayTypeSelector(),
                      const SizedBox(height: 20),
                    ],
                    _buildPassengerSelector(),
                    const SizedBox(height: 20),
                    _buildBudgetSlider(),
                    const SizedBox(height: 24),
                    if (_flashDeals.isNotEmpty) ...[
                      _buildFlashDealsSection(),
                      const SizedBox(height: 20),
                    ],
                    _buildSearchButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isMedicalMode ? 'Sağlık Turizmi' : 'Tatil Bulucu',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                _isMedicalMode
                    ? 'Dünya standartlarında tedavi'
                    : 'Bütçene göre rüya rotanı bul',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined,
                color: AppTheme.textMuted, size: 22),
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user == null) {
                _showSnack('Admin için Google ile giriş yapın', isError: true);
                return;
              }
              if (user == null) {
  _showSnack('Admin için giriş yapmanız gerekiyor', isError: true);
  return;
}
              final isAdmin = await AdminService.isAdmin();
              if (isAdmin && mounted) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (ctx) => const AdminScreen(),
                ));
              } else {
                _showSnack('Erişim yetkiniz yok', isError: true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined,
                color: AppTheme.textMuted, size: 22),
            onPressed: () async {
              await AuthService.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (ctx) => const LoginScreen(),
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(child: _modeBtn('Seyahat', false)),
          Expanded(child: _modeBtn('Sağlık', true)),
        ],
      ),
    );
  }

  Widget _modeBtn(String label, bool isMedical) {
    final isSelected = _isMedicalMode == isMedical;
    return GestureDetector(
      onTap: () => setState(() => _isMedicalMode = isMedical),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isMedical ? AppTheme.teal : AppTheme.accent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginSelector() {
    return _section(
      label: 'Nereden kalkıyorsun?',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _model.originIata,
            dropdownColor: AppTheme.bgSecondary,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted),
            items: _origins.map((o) => DropdownMenuItem(
              value: o['iata'],
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(o['iata']!,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accent)),
                  ),
                  const SizedBox(width: 10),
                  Text(o['city']!,
                      style: const TextStyle(
                          fontSize: 15, color: AppTheme.textPrimary)),
                ],
              ),
            )).toList(),
            onChanged: (val) {
              if (val != null) {
                final city = _origins.firstWhere((o) => o['iata'] == val)['city']!;
                setState(() {
                  _model = _model.copyWith(originIata: val, originCity: city);
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return _section(
      label: 'Ne zaman gidiyorsun?',
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
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.accent,
                  surface: AppTheme.bgSecondary,
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
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gidiş',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text(_formatDate(_model.departureDate),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('${_model.nights} gece',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accent)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Dönüş',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text(_formatDate(_model.returnDate),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinentSelector() {
    return _section(
      label: 'Nereye gitmek istiyorsun?',
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _continents.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final item = _continents[i];
            final isSelected = _selectedContinent == item['value'];
            return GestureDetector(
              onTap: () => setState(() {
                _selectedContinent = item['value'];
                _model = _model.copyWith(continent: item['value']);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accent : AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isSelected ? AppTheme.accent : AppTheme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Text(item['emoji'], style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(item['label'],
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : AppTheme.textMuted)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHolidayTypeSelector() {
    return _section(
      label: 'Nasıl bir tatil istiyorsun?',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _holidayTypes.map((item) {
          final isSelected = _selectedHolidayType == item['value'];
          return GestureDetector(
            onTap: () => setState(() {
              _selectedHolidayType = item['value'];
              _model = _model.copyWith(holidayType: item['value']);
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.teal.withOpacity(0.2) : AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected ? AppTheme.teal : AppTheme.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item['emoji'], style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(item['label'],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppTheme.teal : AppTheme.textMuted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPassengerSelector() {
  return _section(
    label: 'Kac kisi?',
    child: Column(
      children: [
        // Yetişkin
        Row(
          children: [
            const Icon(CupertinoIcons.person, color: AppTheme.textMuted, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yetiskin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  Text('12 yas ve uzeri', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            _counterWidget(
              value: _model.passengers,
              min: 1,
              max: 9,
              onChanged: (val) => setState(() => _model = _model.copyWith(passengers: val)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Çocuk
        Row(
          children: [
            const Icon(CupertinoIcons.person_2, color: AppTheme.textMuted, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cocuk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                 Text('2-11 yas arasi', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            _counterWidget(
              value: _model.children,
              min: 0,
              max: 6,
              onChanged: (val) => setState(() => _model = _model.copyWith(children: val)),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _counterWidget({required int value, required int min, required int max, required Function(int) onChanged}) {
  return Row(
    children: [
      GestureDetector(
        onTap: value > min ? () => onChanged(value - 1) : null,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: value > min ? AppTheme.accent.withOpacity(0.1) : AppTheme.bgTertiary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: value > min ? AppTheme.accent.withOpacity(0.3) : AppTheme.border),
          ),
          child: Icon(CupertinoIcons.minus, size: 14, color: value > min ? AppTheme.accent : AppTheme.textMuted),
        ),
      ),
      Container(
        width: 36,
        alignment: Alignment.center,
        child: Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ),
      GestureDetector(
        onTap: value < max ? () => onChanged(value + 1) : null,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: value < max ? AppTheme.accent.withOpacity(0.1) : AppTheme.bgTertiary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: value < max ? AppTheme.accent.withOpacity(0.3) : AppTheme.border),
          ),
          child: Icon(CupertinoIcons.plus, size: 14, color: value < max ? AppTheme.accent : AppTheme.textMuted),
        ),
      ),
    ],
  );
}

  Widget _buildBudgetSlider() {
    final maxBudget = _isMedicalMode ? 500000.0 : 200000.0;
    final budget = _model.totalBudgetTL.clamp(10000.0, maxBudget);

    String segmentLabel;
    Color segmentColor;
    if (_isMedicalMode) {
      segmentLabel = 'Sağlık Turizmi';
      segmentColor = AppTheme.teal;
    } else if (budget < 25000) {
      segmentLabel = 'Ekonomik';
      segmentColor = const Color(0xFF22C55E);
    } else if (budget < 60000) {
      segmentLabel = 'Standart';
      segmentColor = AppTheme.teal;
    } else {
      segmentLabel = 'Premium';
      segmentColor = const Color(0xFF8B5CF6);
    }

    return _section(
      label: 'Toplam bütçen?',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(segmentLabel,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: segmentColor)),
                GestureDetector(
                  onTap: _showBudgetInput,
                  child: Row(
                    children: [
                      Text(_formatBudget(budget),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: segmentColor)),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_outlined,
                          size: 14, color: segmentColor.withOpacity(0.6)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: segmentColor,
                inactiveTrackColor: segmentColor.withOpacity(0.15),
                thumbColor: segmentColor,
                overlayColor: segmentColor.withOpacity(0.1),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: budget,
                min: 10000,
                max: maxBudget,
                divisions: 100,
                onChanged: (val) =>
                    setState(() => _model = _model.copyWith(totalBudgetTL: val)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('10K TL',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                Text(_formatBudget(maxBudget),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetInput() {
    final ctrl = TextEditingController(
        text: _model.totalBudgetTL.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Bütçe Gir',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            suffix: Text('TL', style: TextStyle(color: AppTheme.textMuted)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val >= 10000) {
                setState(() => _model = _model.copyWith(totalBudgetTL: val));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isMedicalMode
                ? [AppTheme.teal, const Color(0xFF0096B7)]
                : [AppTheme.accent, const Color(0xFFFF3B41)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_isMedicalMode ? AppTheme.teal : AppTheme.accent)
                  .withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _search,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Text(
                  _isMedicalMode
                      ? 'Sağlık Paketi Bul'
                      : 'Bütçeme Uygun Rotaları Bul',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildFlashDealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Son Dakika Fırsatları',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${_flashDeals.length} fırsat',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _flashDeals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final deal = _flashDeals[i];
              final clinic = deal['clinics'] as Map? ?? {};
              final discount = deal['flash_discount_percent'] ?? 0;
              final priceEur = deal['price_eur'] ?? 0;
              final flashPrice = priceEur * (1 - discount / 100);
              return GestureDetector(
                onTap: () {
                  setState(() => _isMedicalMode = true);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (ctx) => MedicalScreen(
                      searchModel: _model,
                      destinationIata: 'AYT',
                      cityName: 'Antalya',
                      flightCostTL: _model.totalBudgetTL * 0.10,
                    ),
                  ));
                },
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              deal['treatment_name_tr'] ?? '--',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-%$discount',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clinic['name'] ?? '--',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            '€${flashPrice.toInt()}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '€${priceEur.toInt()}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _section({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}