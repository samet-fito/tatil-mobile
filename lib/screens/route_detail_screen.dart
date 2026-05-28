import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/route_result_model.dart';
import '../theme/app_theme.dart';
import '../widgets/checkout_auth_sheet.dart';

class RouteDetailScreen extends StatefulWidget {
  final RouteResultModel route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  bool _rentCarAdded = false;
  bool _showBudgetTips = false;

  String _fmt(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  // Şehre göre aktiviteler
  List<Map<String, dynamic>> get _activities {
    final city = widget.route.cityName;
    final Map<String, List<Map<String, dynamic>>> data = {
      'Antalya': [
        {'time': '10:00', 'title': 'Havalimanı\'na İniş', 'sub': 'VIP Transfer ile otele geçiş', 'icon': CupertinoIcons.airplane, 'color': AppTheme.accent},
        {'time': '12:00', 'title': 'Kaleiçi Turu', 'sub': 'Tarihi surlar ve Roma Limanı', 'icon': CupertinoIcons.map_pin, 'color': AppTheme.teal},
        {'time': '14:00', 'title': 'Otel Check-in', 'sub': widget.route.hotel?.name ?? 'Konaklama', 'icon': CupertinoIcons.house, 'color': const Color(0xFF8B5CF6)},
        {'time': '16:00', 'title': 'Düden Şelalesi', 'sub': 'Antalya\'nın simgesi, ücretsiz giriş', 'icon': CupertinoIcons.drop, 'color': AppTheme.teal},
        {'time': '19:00', 'title': 'Akşam Yemeği', 'sub': 'Kaleiçi\'nde Vizegoo seçkisi — %10 indirimli', 'icon': CupertinoIcons.cart, 'color': AppTheme.accent},
      ],
      'Atina': [
        {'time': '10:00', 'title': 'Havalimanı\'na İniş', 'sub': 'Transfer ile otele geçiş', 'icon': CupertinoIcons.airplane, 'color': AppTheme.accent},
        {'time': '12:00', 'title': 'Akropolis Turu', 'sub': 'Dünya mirası, €20 giriş', 'icon': CupertinoIcons.map_pin, 'color': AppTheme.teal},
        {'time': '14:00', 'title': 'Otel Check-in', 'sub': widget.route.hotel?.name ?? 'Konaklama', 'icon': CupertinoIcons.house, 'color': const Color(0xFF8B5CF6)},
        {'time': '17:00', 'title': 'Monastiraki Çarşısı', 'sub': 'Hediyelik eşya ve sokak lezzetleri', 'icon': CupertinoIcons.bag, 'color': AppTheme.teal},
        {'time': '20:00', 'title': 'Akşam Yemeği', 'sub': 'Plaka semtinde Vizegoo seçkisi — %10 indirimli', 'icon': CupertinoIcons.cart, 'color': AppTheme.accent},
      ],
      'Budapeşte': [
        {'time': '10:00', 'title': 'Havalimanı\'na İniş', 'sub': 'Transfer ile otele geçiş', 'icon': CupertinoIcons.airplane, 'color': AppTheme.accent},
        {'time': '12:00', 'title': 'Parlamento Turu', 'sub': 'Tuna kıyısında ihtişam, €15 giriş', 'icon': CupertinoIcons.map_pin, 'color': AppTheme.teal},
        {'time': '14:00', 'title': 'Otel Check-in', 'sub': widget.route.hotel?.name ?? 'Konaklama', 'icon': CupertinoIcons.house, 'color': const Color(0xFF8B5CF6)},
        {'time': '16:00', 'title': 'Széchenyi Termal Banyosu', 'sub': 'Dünyaca ünlü kaplıca, €25', 'icon': CupertinoIcons.drop, 'color': AppTheme.teal},
        {'time': '20:00', 'title': 'Ruin Bar Turu', 'sub': 'Budapeşte\'ye özgü gece deneyimi', 'icon': CupertinoIcons.star, 'color': AppTheme.accent},
      ],
      'Roma': [
        {'time': '10:00', 'title': 'Havalimanı\'na İniş', 'sub': 'Fiumicino\'dan transfer', 'icon': CupertinoIcons.airplane, 'color': AppTheme.accent},
        {'time': '12:00', 'title': 'Kolezyum Turu', 'sub': 'Roma\'nın sembolü, €18 giriş', 'icon': CupertinoIcons.map_pin, 'color': AppTheme.teal},
        {'time': '14:00', 'title': 'Otel Check-in', 'sub': widget.route.hotel?.name ?? 'Konaklama', 'icon': CupertinoIcons.house, 'color': const Color(0xFF8B5CF6)},
        {'time': '16:00', 'title': 'Trevi Çeşmesi & Spanish Steps', 'sub': 'Ücretsiz, mutlaka görülmeli', 'icon': CupertinoIcons.drop, 'color': AppTheme.teal},
        {'time': '19:30', 'title': 'Trastevere\'de Akşam Yemeği', 'sub': 'Vizegoo seçkisi — %10 indirimli', 'icon': CupertinoIcons.cart, 'color': AppTheme.accent},
      ],
    };
    return data[city] ?? data['Antalya']!;
  }

  // Rent a car verisi
  Map<String, dynamic> get _rentCarData {
    final Map<String, Map<String, dynamic>> data = {
      'Antalya': {'taxiCost': 850, 'carCost': 450, 'carModel': 'Renault Clio', 'days': widget.route.nights},
      'Atina': {'taxiCost': 1200, 'carCost': 680, 'carModel': 'Fiat Egea', 'days': widget.route.nights},
      'Budapeşte': {'taxiCost': 950, 'carCost': 520, 'carModel': 'VW Polo', 'days': widget.route.nights},
      'Roma': {'taxiCost': 1800, 'carCost': 950, 'carModel': 'Fiat 500', 'days': widget.route.nights},
    };
    return data[widget.route.cityName] ?? data['Antalya']!;
  }

  // Restoran önerileri
  List<Map<String, dynamic>> get _restaurants {
    final Map<String, List<Map<String, dynamic>>> data = {
      'Antalya': [
        {'name': 'Vanilla Lounge', 'type': 'Akdeniz Mutfağı', 'price': '€€', 'rating': 4.7, 'discount': true},
        {'name': 'Parlak Restaurant', 'type': 'Türk Mutfağı', 'price': '€', 'rating': 4.5, 'discount': true},
        {'name': 'Felice Cafe', 'type': 'Kahve & Brunch', 'price': '€€', 'rating': 4.6, 'discount': false},
      ],
      'Atina': [
        {'name': 'Scholarhio', 'type': 'Yunan Mutfağı', 'price': '€€', 'rating': 4.8, 'discount': true},
        {'name': 'Tzitzikas', 'type': 'Meze & Ouzo', 'price': '€€', 'rating': 4.6, 'discount': false},
        {'name': 'Kostas Souvlaki', 'type': 'Sokak Yemeği', 'price': '€', 'rating': 4.9, 'discount': true},
      ],
      'Budapeşte': [
        {'name': 'Mazel Tov', 'type': 'Fusion Mutfak', 'price': '€€€', 'rating': 4.7, 'discount': true},
        {'name': 'Menza', 'type': 'Macar Mutfağı', 'price': '€€', 'rating': 4.5, 'discount': false},
        {'name': 'Ruszwurm Cukrászda', 'type': 'Tarihi Pastane', 'price': '€', 'rating': 4.8, 'discount': false},
      ],
      'Roma': [
        {'name': 'Da Enzo al 29', 'type': 'Otantik Roma', 'price': '€€', 'rating': 4.9, 'discount': true},
        {'name': 'Supplì Roma', 'type': 'Sokak Yemeği', 'price': '€', 'rating': 4.7, 'discount': false},
        {'name': 'Il Sorpasso', 'type': 'Aperitivo Bar', 'price': '€€', 'rating': 4.6, 'discount': true},
      ],
    };
    return data[widget.route.cityName] ?? data['Antalya']!;
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final rentCar = _rentCarData;
    final saving = (rentCar['taxiCost'] as int) - (rentCar['carCost'] as int);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // Hero AppBar
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.bgPrimary,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withOpacity(0.8),
                      AppTheme.bgPrimary,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          route.cityName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${route.country} · ${route.nights} gece · ${route.passengers} yolcu',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gizli Maliyet Savar
                  _buildFinancialCard(),
                  const SizedBox(height: 16),

                  // Bütçe Esnetme
                  if (!route.isAffordable || route.alternativeSuggestion != null)
                    _buildBudgetAccordion(),

                  // Zaman Cetveli
                  _buildSectionTitle('Günlük Plan'),
                  const SizedBox(height: 12),
                  _buildTimeline(),
                  const SizedBox(height: 20),

                  // Rent a Car
                  _buildSectionTitle('Ulaşım Karşılaştırması'),
                  const SizedBox(height: 12),
                  _buildRentCarCard(rentCar, saving),
                  const SizedBox(height: 20),

                  // Restoranlar
                  _buildSectionTitle('Yemek Önerileri'),
                  const SizedBox(height: 12),
                  _buildRestaurants(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Alt buton
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Toplam',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                Text(
                  _fmt(route.estimatedCost.total +
                      (_rentCarAdded ? (_rentCarData['carCost'] as int) : 0)),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  CheckoutAuthSheet.show(
                    context,
                    cityName: route.cityName,
                    totalPrice: route.estimatedCost.total,
                    onSuccess: () {},
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accent, Color(0xFFFF3B41)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Rezervasyon Yap',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GİZLİ MALİYET SAVAR
  // ============================================================
  Widget _buildFinancialCard() {
    final remaining = widget.route.estimatedCost.remaining;
    final nights = widget.route.nights;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.shield_lefthalf_fill,
                  color: AppTheme.teal, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Finansal Şeffaflık',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _finRow('Uçuş + Otel + Transfer', 'Paketinde dahil', true),
          _finRow('Tahmini yemek ($nights gün)', '~${_fmt(nights * 400)}', false),
          _finRow('Müze & aktivite', '~${_fmt(nights * 200)}', false),
          _finRow('Kişisel harcama', '~${_fmt(nights * 300)}', false),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kalan bütçen',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              Text(
                '+${_fmt(remaining)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: remaining > 0 ? AppTheme.teal : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _finRow(String label, String value, bool isFree) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isFree ? AppTheme.teal : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BÜTÇE ESNETME AKORDEON
  // ============================================================
  Widget _buildBudgetAccordion() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showBudgetTips = !_showBudgetTips),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Bütçeni esnet, bu rotayı yakala',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  Icon(
                    _showBudgetTips
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: const Color(0xFFF59E0B),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_showBudgetTips) ...[
            const Divider(height: 1, color: Color(0x33F59E0B)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _tipRow('Çarşamba yerine Perşembe uçarsan uçak %12 ucuzluyor'),
                  const SizedBox(height: 8),
                  _tipRow('4 yıldızlı yerine butik otel seçersen 1.200 TL tasarruf edersin'),
                  const SizedBox(height: 8),
                  _tipRow('1 gece azaltırsan paket bütçene tam oturuyor'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tipRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFF59E0B),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ZAMAN CETVELİ
  // ============================================================
  Widget _buildTimeline() {
    final activities = _activities;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == activities.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: item['color'] as Color,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 1,
                      height: 36,
                      color: AppTheme.border,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item['time'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['sub'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.3,
                        ),
                      ),
                      if (!isLast) const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // RENT A CAR KARTI
  // ============================================================
  Widget _buildRentCarCard(Map<String, dynamic> data, int saving) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _rentCarAdded
              ? AppTheme.teal.withOpacity(0.4)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _transportOption(
                  icon: CupertinoIcons.car_detailed,
                  title: data['carModel'] as String,
                  subtitle: '${data['days']} gün kiralık',
                  price: '${_fmt(data['carCost'] as int)}',
                  color: AppTheme.teal,
                  isSelected: _rentCarAdded,
                ),
              ),
              const SizedBox(width: 8),
              const Text('VS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted)),
              const SizedBox(width: 8),
              Expanded(
                child: _transportOption(
                  icon: CupertinoIcons.car,
                  title: 'Taksi',
                  subtitle: 'Tahmini ${data['days']} gün',
                  price: '~${_fmt(data['taxiCost'] as int)}',
                  color: AppTheme.textMuted,
                  isSelected: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.money_dollar_circle,
                    color: AppTheme.teal, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Araç kiralayarak ${_fmt(saving)} tasarruf et, daha özgür gez!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _rentCarAdded = !_rentCarAdded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _rentCarAdded
                    ? AppTheme.teal
                    : AppTheme.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.teal.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  _rentCarAdded ? 'Araç Paketten Çıkar' : 'Tek Tıkla Pakete Ekle',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _rentCarAdded ? Colors.white : AppTheme.teal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
    required Color color,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.4) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          Text(subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(price,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }

  // ============================================================
  // RESTORANLAR
  // ============================================================
  Widget _buildRestaurants() {
    return Column(
      children: _restaurants.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.cart,
                    color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          r['name'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (r['discount'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '%10 İndirim',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${r['type']} · ${r['price']}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(CupertinoIcons.star_fill,
                      color: Color(0xFFF59E0B), size: 12),
                  const SizedBox(width: 3),
                  Text(
                    '${r['rating']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}