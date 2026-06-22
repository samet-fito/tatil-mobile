import 'package:flutter/cupertino.dart';
import '../theme/custom_page_route.dart';
import 'clinic_chat_screen.dart';
import 'package:flutter/material.dart';
import '../models/medical_model.dart';
import '../models/search_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/admin_service.dart';
import '../utils/price_format.dart';

class MedicalDetailScreen extends StatefulWidget {
  final MedicalPackage package;
  final SearchModel searchModel;
  final String destinationIata;
  final String cityName;

  const MedicalDetailScreen({
    super.key,
    required this.package,
    required this.searchModel,
    required this.destinationIata,
    required this.cityName,
  });

  @override
  State<MedicalDetailScreen> createState() => _MedicalDetailScreenState();
}

class _MedicalDetailScreenState extends State<MedicalDetailScreen> {
  bool _insuranceSelected = false;
  bool _loadingTravelCosts = true;
  double? _flightCostTL;
  double? _hotelCostTL;
  double? _transferCostTL;
  final String _sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
  static const int INSURANCE_PRICE = 450;

  @override
  void initState() {
    super.initState();
    _loadTravelCosts();
  }

  Future<void> _loadTravelCosts() async {
    final nights = widget.package.totalDays.clamp(1, 30);
    final checkOut = widget.searchModel.departureDate.add(Duration(days: nights));
    final travelers =
        widget.searchModel.passengers + widget.searchModel.children;

    final results = await Future.wait([
      ApiService.searchRealFlights(
        originIata: widget.searchModel.originIata,
        destinationIata: widget.destinationIata,
        departureDate: widget.searchModel.departureDate,
        returnDate: checkOut,
        passengers: travelers,
      ),
      ApiService.searchHotels(
        cityName: widget.cityName,
        checkIn: widget.searchModel.departureDate,
        returnDate: checkOut,
        adults: travelers,
      ),
      AdminService.getActiveTransferForIata(widget.destinationIata),
    ]);

    if (!mounted) return;

    final flights = results[0] as List<Map<String, dynamic>>;
    final hotels = results[1] as List<Map<String, dynamic>>;
    final transfer = results[2] as Map<String, dynamic>?;

    double? flightCost;
    if (flights.isNotEmpty) {
      flightCost = (flights.first['totalAmountTL'] as num?)?.toDouble();
    }

    double? hotelCost;
    if (hotels.isNotEmpty) {
      final perNight = PriceFormat.hotelPerNightTL(hotels.first);
      hotelCost = perNight * nights.toDouble();
    }

    double? transferCost;
    if (transfer != null) {
      transferCost = (transfer['price_fixed'] as num?)?.toDouble();
    }

    setState(() {
      _flightCostTL = flightCost;
      _hotelCostTL = hotelCost;
      _transferCostTL = transferCost;
      _loadingTravelCosts = false;
    });
  }

  String _formatPrice(double price) {
    return '${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  double get _totalCost {
    var total = widget.package.priceTL;
    if (_flightCostTL != null) total += _flightCostTL!;
    if (_hotelCostTL != null) total += _hotelCostTL!;
    if (_transferCostTL != null) total += _transferCostTL!;
    if (_insuranceSelected) total += INSURANCE_PRICE;
    return total;
  }

  double get _commissionTL =>
      widget.package.priceTL * widget.package.commissionRate;

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;
    final clinic = pkg.clinic;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.health,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.health, Color(0xFF5B21B6)],
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
                          children: [
                            Text(pkg.treatmentTypeEmoji,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pkg.treatmentNameTr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    clinic?.name ?? '',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Başarı oranı
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '%${pkg.successRate.toInt()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Text(
                                    'Başarı',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Rozetler
                        _buildBadges(clinic),
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
                  // Bütçe özeti
                  _buildCostSummary(),
                  const SizedBox(height: 12),

                  // Sigorta
                  _buildInsuranceBox(),
                  const SizedBox(height: 12),

                  // Tedavi süreci timeline
                  _buildTimeline(),
                  const SizedBox(height: 12),

                  // Klinik bilgileri
                  _buildClinicInfo(clinic),
                  const SizedBox(height: 12),

                  // Dahil olanlar
                  _buildIncludes(),
                  const SizedBox(height: 12),

                  // Doktor & Ekip
                  _buildDoctorInfo(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Alt buton
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
            GestureDetector(
              onTap: () => pushAppRoute(
                context,
                ClinicChatScreen(
                  clinicId: widget.package.clinicId,
                  clinicName: widget.package.clinic?.name ?? 'Klinik',
                ),
              ),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
                ),
                child: Icon(CupertinoIcons.chat_bubble,
    color: AppTheme.teal, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Toplam Tutar',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                Text(
                  _formatPrice(_totalCost),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.health,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Material(
                color: AppTheme.teal,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _bookMedicalPackage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: const Text(
                      'Rezervasyon Yap',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
  // ROZETLER
  // ============================================================
  Widget _buildBadges(MedicalClinic? clinic) {
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      if (clinic?.isMinistryAccredited == true)
        _badge('Sağlık Bakanlığı Onaylı', const Color(0xFF065F46)),
      if (clinic?.isJciAccredited == true)
        _badge('JCI Akreditasyonlu', const Color(0xFF1E40AF)),
      _badge('Klinik Onaylı', const Color(0xFF6D28D9)),
      _badge('%${widget.package.successRate.toInt()} Başarı', const Color(0xFF92400E)),
    ],
  );
}

  Widget _badge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    ),
  );
}

  // ============================================================
  // MALİYET ÖZETİ
  // ============================================================
  Widget _buildCostSummary() {
    final budget = widget.searchModel.totalBudgetTL;
    final remaining = budget - _totalCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.healthLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💰 Paket Maliyet Dağılımı',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.health,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingTravelCosts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.health),
              ),
            )
          else ...[
            _costRow('✈️ Uçuş', _flightCostTL),
            _costRow('🏥 Tedavi', widget.package.priceTL),
            _costRow(
              '🏨 Otel (${widget.package.totalDays} gece)',
              _hotelCostTL,
            ),
            _costRow('🚗 VIP Transfer', _transferCostTL),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Toplam',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(
                _formatPrice(_totalCost),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.health,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kalan bütçe',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              Text(
                '+${_formatPrice(remaining)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: remaining >= 0 ? AppTheme.accent : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _costRow(String label, double? amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          Text(
            amount != null ? _formatPrice(amount) : 'Canlı fiyat yok',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: amount != null ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SİGORTA
  // ============================================================
  Widget _buildInsuranceBox() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF2A1F00),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Medikal Seyahat Sigortası',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tedavi komplikasyonları + iptal güvencesi',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              const Text(
                '+450 TL · Medikal seyahatte şart!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _insuranceSelected,
          onChanged: (val) => setState(() => _insuranceSelected = val),
          activeColor: const Color(0xFFF59E0B),
        ),
      ],
    ),
  );
}

  // ============================================================
  // TEDAVİ SÜRECİ TİMELINE
  // ============================================================
  Widget _buildTimeline() {
    final pkg = widget.package;
    final steps = _getTimelineSteps(pkg);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Tedavi Süreci',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Toplam ${pkg.totalDays} gün · ${pkg.durationTreatmentDays} gün tedavi + ${pkg.durationRestDays} gün dinlenme',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: step['color'] as Color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          step['emoji'] as String,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: Colors.black.withOpacity(0.08),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          step['desc'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        if (!isLast) const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getTimelineSteps(MedicalPackage pkg) {
    final base = [
      {
        'emoji': '🛬',
        'title': 'Varış & Karşılama',
        'desc': 'VIP transfer ile kliniğe transfer',
        'color': AppTheme.accent,
      },
      {
        'emoji': '🩺',
        'title': 'Konsültasyon & Hazırlık',
        'desc': 'Uzman doktor muayenesi ve operasyon planı',
        'color': AppTheme.health,
      },
    ];

    if (pkg.durationTreatmentDays == 1) {
      base.add({
        'emoji': pkg.treatmentTypeEmoji,
        'title': 'Operasyon Günü',
        'desc': '${pkg.treatmentNameTr} operasyonu gerçekleştirilir',
        'color': const Color(0xFF7C3AED),
      });
    } else {
      for (int i = 1; i <= pkg.durationTreatmentDays; i++) {
        base.add({
          'emoji': i == 1 ? pkg.treatmentTypeEmoji : '⚕️',
          'title': '$i. Tedavi Günü',
          'desc': i == 1 ? 'Ana operasyon' : 'Kontrol ve devam tedavisi',
          'color': const Color(0xFF7C3AED),
        });
      }
    }

    base.addAll([
      {
        'emoji': '🏨',
        'title': 'Dinlenme & İyileşme',
        'desc': '${pkg.durationRestDays} gün otel konaklaması, doktor takibi',
        'color': const Color(0xFF0EA5E9),
      },
      {
        'emoji': '✅',
        'title': 'Son Kontrol & Uçuş',
        'desc': 'Çıkış muayenesi ve eve dönüş',
        'color': AppTheme.accent,
      },
    ]);

    return base;
  }

  // ============================================================
  // KLİNİK BİLGİLERİ
  // ============================================================
  Widget _buildClinicInfo(MedicalClinic? clinic) {
    if (clinic == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.healthLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🏥', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      clinic.cityName,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${clinic.successScore}/10',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.health,
                    ),
                  ),
                  const Text(
                    'Başarı Puanı',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _clinicRow('👥 Hasta Sayısı',
              '${clinic.patientCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}+'),
          _clinicRow('🌍 Dil Seçenekleri', clinic.languages.join(', ')),
          _clinicRow(
              '🔬 Uzmanlıklar', clinic.specializations.take(3).join(', ')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (clinic.isMinistryAccredited)
                _infoBadge('🏛️ Bakanlık Onaylı', AppTheme.health),
              if (clinic.isJciAccredited)
                _infoBadge('🌍 JCI', const Color(0xFF1E40AF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clinicRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  // ============================================================
  // DAHİL OLANLAR
  // ============================================================
  Widget _buildIncludes() {
  final includes = widget.package.includes;
  final hasHotel = includes.any((i) => i.toLowerCase().contains('otel') || i.toLowerCase().contains('hotel'));
  final hasFlight = includes.any((i) => i.toLowerCase().contains('uçuş') || i.toLowerCase().contains('transfer'));

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.bgSecondary,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pakete Dahil Olanlar',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        // Tedavi paketi içerikleri
        ...includes.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: AppTheme.teal),
              const SizedBox(width: 10),
              Text(item, style: const TextStyle(
                  fontSize: 13, color: AppTheme.textPrimary)),
            ],
          ),
        )),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        // Uçuş ve otel durumu
        const Text(
          'Paket Dışı (Ayrıca Hesaplanır)',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted),
        ),
        const SizedBox(height: 8),
        if (!hasFlight)
          _notIncludedRow('Uçuş bileti ayrıca hesaplanmıştır',
              'Yukarıdaki maliyet dağılımına dahildir'),
        if (!hasHotel)
          _notIncludedRow('Otel konaklaması ayrıca hesaplanmıştır',
              'Yukarıdaki maliyet dağılımına dahildir'),
        _notIncludedRow('VIP Havalimanı transferi',
            'Yukarıdaki maliyet dağılımına dahildir'),
      ],
    ),
  );
}

Widget _notIncludedRow(String title, String sub) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ============================================================
  // DOKTOR BİLGİSİ
  // ============================================================
  Widget _buildDoctorInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👨‍⚕️ Uzman Doktor Ekibi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.healthLight,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Center(
                  child: Text('👨‍⚕️', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uzman Cerrah Ekibi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${widget.package.treatmentTypeLabel} Uzmanı · 10+ yıl deneyim',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '%${widget.package.successRate.toInt()} başarı oranı · ${widget.package.clinic?.patientCount ?? 0}+ hasta',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.health,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REZERVASYON
  // ============================================================
  Future<void> _bookMedicalPackage() async {
    if (_flightCostTL == null || _hotelCostTL == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uçuş ve otel fiyatları yüklenemedi. Tekrar deneyin.'),
        ),
      );
      return;
    }

    final travelDate = widget.searchModel.departureDate
        .toIso8601String()
        .split('T')[0];

    await ApiService.saveMedicalBooking(
      sessionId: _sessionId,
      packageId: widget.package.id,
      clinicId: widget.package.clinicId,
      travelDate: travelDate,
      passengerCount: widget.searchModel.passengers,
      treatmentPriceTL: widget.package.priceTL,
      flightPriceTL: _flightCostTL!,
      hotelPriceTL: _hotelCostTL!,
      totalPriceTL: _totalCost,
      commissionTL: _commissionTL,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🏥 Rezervasyon Alındı!'),
          content: Text(
            '${widget.package.treatmentNameTr} için talebiniz alındı!\n\n'
            '${widget.package.clinic?.name ?? 'Klinik'} ekibi 24 saat '
            'içinde sizinle iletişime geçecek.\n\n'
            'Toplam: ${_formatPrice(_totalCost)}\n'
            'Süre: ${widget.package.totalDays} gün',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }
}