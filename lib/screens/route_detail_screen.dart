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

  List<Map<String, dynamic>> get _activities {
    final city = widget.route.cityName;
    final Map<String, List<Map<String, dynamic>>> data = {
      'Antalya': [
        {'time': '10:00', 'title': 'Havalimanina Inis', 'sub': 'VIP Transfer ile otele gecis', 'icon': CupertinoIcons.airplane, 'color': AppTheme.accent},
        {'time': '12:00', 'title': 'Kaleici Turu', 'sub': 'Tarihi surlar ve Roma Limani', 'icon': CupertinoIcons.map_pin, 'color': AppTheme.teal},
        {'time': '14:00', 'title': 'Otel Check-in', 'sub': widget.route.hotel?.name ?? 'Konaklama', 'icon': CupertinoIcons.house, 'color': const Color(0xFF8B5CF6)},
        {'time': '16:00', 'title': 'Duden Selalesi', 'sub': 'Antalyanin simgesi, ucretsiz giris', 'icon': CupertinoIcons.drop, 'color': AppTheme.teal},
        {'time': '19:00', 'title': 'Aksam Yemegi', 'sub': 'Kaleicinde Vizegoo seçkisi - %10 indirimli', 'icon': CupertinoIcons.cart, 'color': AppTheme.accent},
      ],
      'Atina': [
        {'time': '10:00', 'title': 'Havalimanina Inis', 'sub': 'Transfer ile otele gecis', 'icon': CupertinoIcons.airplane, 'color': AppTheme.accent},
        {'time': '12:00', 'title': 'Akropolis Turu', 'sub': 'Dunya mirasi, 20 euro giris', 'icon': CupertinoIcons.map_pin, 'color': AppTheme.teal},
        {'time': '14:00', 'title': 'Otel Check-in', 'sub': widget.route.hotel?.name ?? 'Konaklama', 'icon': CupertinoIcons.house, 'color': const Color(0xFF8B5CF6)},
        {'time': '17:00', 'title': 'Monastiraki Carsisi', 'sub': 'Hediyelik esya ve sokak lezzetleri', 'icon': CupertinoIcons.bag, 'color': AppTheme.teal},
        {'time': '20:00', 'title': 'Aksam Yemegi', 'sub': 'Plaka semtinde Vizegoo seçkisi - %10 indirimli', 'icon': CupertinoIcons.cart, 'color': AppTheme.accent},
      ],
      'Budapeşte': [
        {'time': '10:00', 'title': 'Havalimanina Inis', 'sub': 'Transfer ile otele gecis', 'icon': CupertinoIcons.airplane, 'color': AppTheme.accent},
        {'time': '12:00', 'title': 'Parlamento Turu', 'sub': 'Tuna kiyisinda ihtisam, 15 euro giris', 'icon': CupertinoIcons.map_pin, 'color': AppTheme.teal},
        {'time': '14:00', 'title': 'Otel Check-in', 'sub': widget.route.hotel?.name ?? 'Konaklama', 'icon': CupertinoIcons.house, 'color': const Color(0xFF8B5CF6)},
        {'time': '16:00', 'title': 'Szechenyi Termal', 'sub': 'Dunyaca unlu kaplica, 25 euro', 'icon': CupertinoIcons.drop, 'color': AppTheme.teal},
        {'time': '20:00', 'title': 'Ruin Bar Turu', 'sub': 'Budapesteyé özgü gece deneyimi', 'icon': CupertinoIcons.star, 'color': AppTheme.accent},
      ],
      'Roma': [
        {'time': '10:00', 'title': 'Havalimanina Inis', 'sub': 'Fiumicino transfer', 'icon': CupertinoIcons.airplane, 'color': AppTheme.accent},
        {'time': '12:00', 'title': 'Kolezyum Turu', 'sub': 'Romanin sembolu, 18 euro giris', 'icon': CupertinoIcons.map_pin, 'color': AppTheme.teal},
        {'time': '14:00', 'title': 'Otel Check-in', 'sub': widget.route.hotel?.name ?? 'Konaklama', 'icon': CupertinoIcons.house, 'color': const Color(0xFF8B5CF6)},
        {'time': '16:00', 'title': 'Trevi Cesmesi', 'sub': 'Ucretsiz, mutlaka gorulmeli', 'icon': CupertinoIcons.drop, 'color': AppTheme.teal},
        {'time': '19:30', 'title': 'Aksam Yemegi', 'sub': 'Trasteverede Vizegoo seçkisi - %10 indirimli', 'icon': CupertinoIcons.cart, 'color': AppTheme.accent},
      ],
    };
    return data[city] ?? data['Antalya']!;
  }

  Map<String, dynamic> get _rentCarData {
    final Map<String, Map<String, dynamic>> data = {
      'Antalya': {'taxiCost': 850, 'carCost': 450, 'carModel': 'Renault Clio', 'days': widget.route.nights},
      'Atina': {'taxiCost': 1200, 'carCost': 680, 'carModel': 'Fiat Egea', 'days': widget.route.nights},
      'Budapeşte': {'taxiCost': 950, 'carCost': 520, 'carModel': 'VW Polo', 'days': widget.route.nights},
      'Roma': {'taxiCost': 1800, 'carCost': 950, 'carModel': 'Fiat 500', 'days': widget.route.nights},
    };
    return data[widget.route.cityName] ?? data['Antalya']!;
  }

  List<Map<String, dynamic>> get _restaurants {
    final Map<String, List<Map<String, dynamic>>> data = {
      'Antalya': [
        {'name': 'Vanilla Lounge', 'type': 'Akdeniz Mutfagi', 'price': '€€', 'rating': 4.7, 'discount': true},
        {'name': 'Parlak Restaurant', 'type': 'Turk Mutfagi', 'price': '€', 'rating': 4.5, 'discount': true},
        {'name': 'Felice Cafe', 'type': 'Kahve & Brunch', 'price': '€€', 'rating': 4.6, 'discount': false},
      ],
      'Atina': [
        {'name': 'Scholarhio', 'type': 'Yunan Mutfagi', 'price': '€€', 'rating': 4.8, 'discount': true},
        {'name': 'Tzitzikas', 'type': 'Meze & Ouzo', 'price': '€€', 'rating': 4.6, 'discount': false},
        {'name': 'Kostas Souvlaki', 'type': 'Sokak Yemegi', 'price': '€', 'rating': 4.9, 'discount': true},
      ],
      'Budapeşte': [
        {'name': 'Mazel Tov', 'type': 'Fusion Mutfak', 'price': '€€€', 'rating': 4.7, 'discount': true},
        {'name': 'Menza', 'type': 'Macar Mutfagi', 'price': '€€', 'rating': 4.5, 'discount': false},
        {'name': 'Ruszwurm', 'type': 'Tarihi Pastane', 'price': '€', 'rating': 4.8, 'discount': false},
      ],
      'Roma': [
        {'name': 'Da Enzo al 29', 'type': 'Otantik Roma', 'price': '€€', 'rating': 4.9, 'discount': true},
        {'name': 'Suppli Roma', 'type': 'Sokak Yemegi', 'price': '€', 'rating': 4.7, 'discount': false},
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
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(route.cityName,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            Text('${route.country} · ${route.nights} gece',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      ),
     bottomNavigationBar: Container(
  height: 80,
  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                color: AppTheme.textPrimary),
          ),
        ],
      ),
      const SizedBox(width: 16),
      Expanded(
        child: GestureDetector(
          onTap: () => CheckoutAuthSheet.show(
            context,
            cityName: route.cityName,
            totalPrice: route.estimatedCost.total,
            onSuccess: () {},
          ),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFFFF3B41)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('Rezervasyon Yap',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    ],
  ),
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFinancialCard(),
            const SizedBox(height: 16),
            if (!route.isAffordable || route.alternativeSuggestion != null) _buildBudgetAccordion(),
            _buildSectionTitle('Gunluk Plan'),
            const SizedBox(height: 12),
            _buildTimeline(),
            const SizedBox(height: 20),
            _buildSectionTitle('Ulasim Karsilastirmasi'),
            const SizedBox(height: 12),
            _buildRentCarCard(rentCar, saving),
            const SizedBox(height: 20),
            _buildSectionTitle('Yemek Onerileri'),
            const SizedBox(height: 12),
            _buildRestaurants(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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
          Row(children: [
            const Icon(CupertinoIcons.shield_lefthalf_fill, color: AppTheme.teal, size: 18),
            const SizedBox(width: 8),
            const Text('Finansal Seffaflik',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.teal)),
          ]),
          const SizedBox(height: 12),
          _finRow('Ucus + Otel + Transfer', 'Paketinde dahil', true),
          _finRow('Tahmini yemek ($nights gun)', '~${_fmt(nights * 400)}', false),
          _finRow('Muze & aktivite', '~${_fmt(nights * 200)}', false),
          _finRow('Kisisel harcama', '~${_fmt(nights * 300)}', false),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kalan butcen',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text('+${_fmt(remaining)}',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: remaining > 0 ? AppTheme.teal : Colors.red)),
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
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: isFree ? AppTheme.teal : AppTheme.textSecondary)),
        ],
      ),
    );
  }

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
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Butceni esnet, bu rotayi yakala',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
                  ),
                  Icon(_showBudgetTips ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                      color: const Color(0xFFF59E0B), size: 16),
                ],
              ),
            ),
          ),
          if (_showBudgetTips) ...[
            const Divider(height: 1, color: Color(0x33F59E0B)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _tipRow('Carsamba yerine Persembe ucarsan ucak %12 ucuzluyor'),
                const SizedBox(height: 8),
                _tipRow('4 yildizli yerine butik otel secersen 1.200 TL tasarruf edersin'),
                const SizedBox(height: 8),
                _tipRow('1 gece azaltirsan paket butcene tam oturuyor'),
              ]),
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
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), height: 1.4))),
      ],
    );
  }

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
              Column(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(item['icon'] as IconData, size: 16, color: item['color'] as Color),
                ),
                if (!isLast) Container(width: 1, height: 36, color: AppTheme.border),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(item['time'] as String,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item['title'] as String,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(item['sub'] as String,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.3)),
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

  Widget _buildRentCarCard(Map<String, dynamic> data, int saving) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _rentCarAdded ? AppTheme.teal.withOpacity(0.4) : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _transportOption(
              icon: CupertinoIcons.car_detailed, title: data['carModel'] as String,
              subtitle: '${data['days']} gun kiralik', price: _fmt(data['carCost'] as int),
              color: AppTheme.teal, isSelected: _rentCarAdded,
            )),
            const SizedBox(width: 8),
            const Text('VS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
            const SizedBox(width: 8),
            Expanded(child: _transportOption(
              icon: CupertinoIcons.car, title: 'Taksi',
              subtitle: 'Tahmini ${data['days']} gun', price: '~${_fmt(data['taxiCost'] as int)}',
              color: AppTheme.textMuted, isSelected: false,
            )),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(CupertinoIcons.money_dollar_circle, color: AppTheme.teal, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Arac kiralayarak ${_fmt(saving)} tasarruf et!',
                  style: const TextStyle(fontSize: 12, color: AppTheme.teal, fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _rentCarAdded = !_rentCarAdded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _rentCarAdded ? AppTheme.teal : AppTheme.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  _rentCarAdded ? 'Arac Paketten Cikar' : 'Tek Tikla Pakete Ekle',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _rentCarAdded ? Colors.white : AppTheme.teal),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transportOption({
    required IconData icon, required String title, required String subtitle,
    required String price, required Color color, required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? color.withOpacity(0.4) : Colors.transparent),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Text(price, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

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
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(CupertinoIcons.cart, color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(r['name'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(width: 6),
                  if (r['discount'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(4)),
                      child: const Text('%10 Indirim',
                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                ]),
                Text('${r['type']} · ${r['price']}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ]),
            ),
            Row(children: [
              const Icon(CupertinoIcons.star_fill, color: Color(0xFFF59E0B), size: 12),
              const SizedBox(width: 3),
              Text('${r['rating']}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ]),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: -0.3));
  }
}