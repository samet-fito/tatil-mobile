import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../models/search_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class DetailScreen extends StatefulWidget {
  final PackageModel package;
  final SearchModel searchModel;

  const DetailScreen({
    super.key,
    required this.package,
    required this.searchModel,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _insuranceSelected = false;
  bool _activitiesLoaded = false;
  bool _activitiesLoading = false;
  Map<String, dynamic>? _activitiesData;
  Map<String, dynamic>? _visaData;
  final String _sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';

  static const int INSURANCE_PRICE = 450;

  @override
  void initState() {
    super.initState();
    _loadVisaInfo();
  }

  Future<void> _loadVisaInfo() async {
    if (widget.package.isDomestic) return;
    final result = await ApiService.getVisaInfo(
      widget.package.countryCodeFromCountry,
    );
    if (mounted && result['success'] == true) {
      setState(() => _visaData = result['data']);
    }
  }

  Future<void> _loadActivities() async {
    if (_activitiesLoaded) return;
    setState(() => _activitiesLoading = true);

    final dep = widget.searchModel.departureDate.toIso8601String().split('T')[0];
    final ret = widget.searchModel.returnDate.toIso8601String().split('T')[0];

    final result = await ApiService.getActivities(
      iata: widget.package.iataCode,
      city: widget.package.cityName,
      departure: dep,
      returnDate: ret,
    );

    if (mounted) {
      setState(() {
        _activitiesData = result['data'];
        _activitiesLoaded = true;
        _activitiesLoading = false;
      });
    }
  }

  int get _totalPrice =>
      widget.package.estimatedCost.total +
      (_insuranceSelected ? INSURANCE_PRICE : 0);

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF1D3461)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '✈️ ${widget.package.cityName}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${widget.package.country} · ${widget.package.nights} gece',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${widget.package.score}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Text(
                                    'PUAN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                children: [
                  // Bütçe Özeti
                  _buildBudgetSummary(),

                  const SizedBox(height: 12),

                  // Sigorta (sadece yurt dışı)
                  if (!widget.package.isDomestic) _buildInsuranceBox(),

                  const SizedBox(height: 12),

                  // Accordion'lar
                  _buildAccordion(
                    title: '✈️ Uçuş Bilgileri',
                    child: _buildFlightDetails(),
                  ),
                  _buildAccordion(
                    title: '🚗 Ulaşım Alternatifleri',
                    child: _buildTransportOptions(),
                  ),
                  _buildAccordion(
                    title: '🏨 Havalimanından Otele',
                    child: _buildAirportTransfer(),
                  ),
                  _buildAccordion(
                    title: '🏨 Konaklama',
                    child: _buildHotelDetails(),
                  ),
                  if (!widget.package.isDomestic)
                    _buildAccordion(
                      title: '🛂 Vize Bilgileri',
                      child: _buildVisaInfo(),
                    ),
                  _buildActivitiesAccordion(),
                  _buildAccordion(
                    title: '💸 Günlük Harcama Tahmini',
                    child: _buildDailyExpenses(),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Alt rezervasyon butonu
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toplam Tutar',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                Text(
                  _formatPrice(_totalPrice),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🚀 Rezervasyon sistemi yakında aktif!'),
                      backgroundColor: AppTheme.accent,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Rezervasyon Yap →',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
  // BÜTÇE ÖZETİ
  // ============================================================
  Widget _buildBudgetSummary() {
    final bd = widget.package.budgetBreakdown;
    final cost = widget.package.estimatedCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💰 Bütçe Dağılımı · ${bd.segmentLabel} Segment',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 12),
          _buildBudgetBar('✈ Ulaşım', bd.transport.percentage, cost.flight, AppTheme.accent),
          const SizedBox(height: 8),
          _buildBudgetBar('🏨 Otel', bd.accommodation.percentage, cost.hotel, const Color(0xFFD85A30)),
          const SizedBox(height: 8),
          _buildBudgetBar('💰 Harçlık', bd.pocketMoney.percentage, cost.living, const Color(0xFF6366F1)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Toplam Tahmini', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              Text(
                '${_formatPrice(cost.total)} · +${_formatPrice(cost.remaining)} kalan',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetBar(String label, int percentage, int amount, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(
            _formatPrice(amount),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SİGORTA
  // ============================================================
  Widget _buildInsuranceBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0C97A), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🛡️ Seyahat Sağlık Sigortası',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '%100 İptal Güvencesi dahil',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+$INSURANCE_PRICE TL · Güvenli seyahat için önerilir',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF854F0B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _insuranceSelected,
                onChanged: (val) => setState(() => _insuranceSelected = val),
                activeColor: AppTheme.accent,
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Toplam Tutar', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              Text(
                _formatPrice(_totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCORDION
  // ============================================================
  Widget _buildAccordion({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        iconColor: AppTheme.accent,
        collapsedIconColor: AppTheme.textMuted,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPrice ? AppTheme.accent : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UÇUŞ BİLGİLERİ
  // ============================================================
  Widget _buildFlightDetails() {
    final f = widget.package.flightInfo;
    final cost = widget.package.estimatedCost;
    return Column(
      children: [
        _buildDetailRow('Havayolu', f.airline),
        _buildDetailRow('Süre', f.duration),
        _buildDetailRow('Kalkış', f.departureTime),
        _buildDetailRow('Varış', f.arrivalTime),
        _buildDetailRow('Aktarma', f.stops == 0 ? 'Direkt' : '${f.stops} aktarma'),
        _buildDetailRow('Kişi Başı', _formatPrice(cost.flight ~/ widget.searchModel.passengers), isPrice: true),
      ],
    );
  }

  // ============================================================
  // ULAŞIM ALTERNATİFLERİ
  // ============================================================
  Widget _buildTransportOptions() {
    final flight = widget.package.estimatedCost.flight;
    final options = [
      {'icon': '✈️', 'label': 'Uçakla', 'price': flight},
      {'icon': '🚌', 'label': 'Otobüsle', 'price': (flight * 0.25).toInt()},
      {'icon': '🚂', 'label': 'Trenle', 'price': (flight * 0.35).toInt()},
      {'icon': '🚗', 'label': 'Kendi Aracın', 'price': (flight * 0.40).toInt()},
      {'icon': '🔑', 'label': 'Kiralık Araç', 'price': (flight * 0.60).toInt()},
    ];
    return Column(
      children: options.map((o) => _buildDetailRow(
        '${o['icon']} ${o['label']}',
        _formatPrice(o['price'] as int),
        isPrice: true,
      )).toList(),
    );
  }

  // ============================================================
  // HAVALİMANI TRANSFERİ
  // ============================================================
  Widget _buildAirportTransfer() {
    final flight = widget.package.estimatedCost.flight;
    final options = [
      {'icon': '🚇', 'label': 'Metro / Tren', 'price': (flight * 0.01).toInt()},
      {'icon': '🚌', 'label': 'Servis', 'price': (flight * 0.03).toInt()},
      {'icon': '🚕', 'label': 'Taksi', 'price': (flight * 0.05).toInt()},
      {'icon': '👑', 'label': 'VIP Transfer', 'price': (flight * 0.08).toInt()},
    ];
    return Column(
      children: options.map((o) => _buildDetailRow(
        '${o['icon']} ${o['label']}',
        _formatPrice(o['price'] as int),
        isPrice: true,
      )).toList(),
    );
  }

  // ============================================================
  // KONAKLAMA
  // ============================================================
  Widget _buildHotelDetails() {
    final h = widget.package.hotelInfo;
    final cost = widget.package.estimatedCost;
    final nights = widget.package.nights;
    return Column(
      children: [
        _buildDetailRow('Otel', h.name),
        _buildDetailRow('Puan', '${h.rating}/10 ⭐'),
        _buildDetailRow('Yorum', '${h.reviewCount} yorum'),
        _buildDetailRow('Gecelik', _formatPrice(cost.hotel ~/ nights), isPrice: true),
        _buildDetailRow('Toplam ($nights gece)', _formatPrice(cost.hotel), isPrice: true),
      ],
    );
  }

  // ============================================================
  // VİZE BİLGİLERİ
  // ============================================================
  Widget _buildVisaInfo() {
    if (_visaData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    final visa = _visaData!;
    final required = visa['required'] ?? false;

    if (!required) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.accentLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Text('✅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${visa['country']} için vize gerekmez',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accent),
                  ),
                  Text(
                    visa['type'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCEBEB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ ${visa['country']} için ${visa['type']} gereklidir',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFA32D2D)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('💰 ${_formatPrice((visa['price'] ?? 0).toInt())}',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 16),
                  Text('⏱️ ${visa['processingDays'] ?? '--'}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text('📄 Gerekli Evraklar',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...(visa['documents'] as List? ?? []).map((doc) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(doc, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vize danışmanlık talebiniz alındı!'),
                  backgroundColor: AppTheme.accent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA32D2D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              '🤝 ${visa['partner'] ?? 'Vizegoo'} ile Vize Danışmanlığı Al',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AKTİVİTELER
  // ============================================================
  Widget _buildActivitiesAccordion() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: ExpansionTile(
        title: const Text(
          '🎯 Aktiviteler & Etkinlikler',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        iconColor: AppTheme.accent,
        collapsedIconColor: AppTheme.textMuted,
        onExpansionChanged: (expanded) {
          if (expanded) _loadActivities();
        },
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [_buildActivitiesContent()],
      ),
    );
  }

  Widget _buildActivitiesContent() {
    if (_activitiesLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    if (_activitiesData == null) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Aktiviteleri görmek için genişletin.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
      );
    }

    final acts = _activitiesData!['activities'];
    if (acts == null) return const Text('Aktivite bulunamadı.');

    final withinTrip = List<Map<String, dynamic>>.from(acts['withinTrip'] ?? []);
    final nearby = List<Map<String, dynamic>>.from(acts['nearby'] ?? []);

    final categoryLabels = {
      'tours': '🗺️ Turlar',
      'museums': '🏛️ Müzeler',
      'adventure': '🏄 Macera',
      'events': '🎭 Etkinlikler',
    };

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final act in withinTrip) {
      final cat = act['category'] as String? ?? 'tours';
      grouped.putIfAbsent(cat, () => []).add(act);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...grouped.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    categoryLabels[entry.key] ?? entry.key,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                ...entry.value.map((act) => _buildActivityItem(act, false)),
              ],
            )),
        if (nearby.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '📅 Kaçırma! Yakın Tarihlerde',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF854F0B),
              ),
            ),
          ),
          ...nearby.map((act) => _buildActivityItem(act, true)),
        ],
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> act, bool isNearby) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNearby ? const Color(0xFFFFFBF0) : AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNearby
              ? const Color(0xFFF0C97A)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      act['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isNearby) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAEEDA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '±10 gün',
                          style: TextStyle(fontSize: 10, color: Color(0xFF854F0B)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${act['description']} · ${act['duration']}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                Text(
                  '⭐ ${act['rating']} (${act['reviewCount']} yorum)',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPrice((act['priceTL'] ?? 0).toInt()),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${act['title']} rezervasyonu yakında!'),
                      backgroundColor: AppTheme.accent,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isNearby ? const Color(0xFF854F0B) : AppTheme.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Rezervasyon',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GÜNLÜK HARCAMA
  // ============================================================
  Widget _buildDailyExpenses() {
    final living = widget.package.estimatedCost.living;
    final nights = widget.package.nights;
    final daily = living ~/ nights;
    return Column(
      children: [
        _buildDetailRow('🍽️ Yemek', _formatPrice((daily * 0.5).toInt()), isPrice: true),
        _buildDetailRow('🚌 Şehir İçi', _formatPrice((daily * 0.2).toInt()), isPrice: true),
        _buildDetailRow('🛍️ Alışveriş', _formatPrice((daily * 0.3).toInt()), isPrice: true),
        const Divider(),
        _buildDetailRow('Toplam / Gün', _formatPrice(daily), isPrice: true),
      ],
    );
  }
}