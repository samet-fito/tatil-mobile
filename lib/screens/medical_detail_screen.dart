import 'package:flutter/material.dart';
import '../models/medical_model.dart';
import '../models/search_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class MedicalDetailScreen extends StatefulWidget {
  final MedicalPackage package;
  final SearchModel searchModel;
  final double flightCostTL;

  const MedicalDetailScreen({
    super.key,
    required this.package,
    required this.searchModel,
    required this.flightCostTL,
  });

  @override
  State<MedicalDetailScreen> createState() => _MedicalDetailScreenState();
}

class _MedicalDetailScreenState extends State<MedicalDetailScreen> {
  bool _insuranceSelected = false;
  final String _sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
  static const int INSURANCE_PRICE = 450;

  String _formatPrice(double price) {
    return '${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  double get _totalCost =>
      widget.flightCostTL +
      widget.package.priceTL +
      (widget.searchModel.totalBudgetTL * 0.15) +
      (widget.searchModel.totalBudgetTL * 0.05) +
      (_insuranceSelected ? INSURANCE_PRICE : 0);

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
            expandedHeight: 180,
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
              child: ElevatedButton(
                onPressed: _bookMedicalPackage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.health,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '🏥 Medikal Paket Rezerve Et',
                  style: TextStyle(
                    fontSize: 14,
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
  // ROZETLER
  // ============================================================
  Widget _buildBadges(MedicalClinic? clinic) {
    return Wrap(
      spacing: 8,
      children: [
        if (clinic?.isMinistryAccredited == true)
          _badge('🏛️ Sağlık Bakanlığı Onaylı', const Color(0xFF065F46)),
        if (clinic?.isJciAccredited == true)
          _badge('🌍 JCI Akreditasyonlu', const Color(0xFF1E40AF)),
        _badge('✅ Klinik Onaylı', const Color(0xFF6D28D9)),
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // MALİYET ÖZETİ
  // ============================================================
  Widget _buildCostSummary() {
    final budget = widget.searchModel.totalBudgetTL;
    final hotel = budget * 0.15;
    final transfer = budget * 0.05;
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
          _costRow('✈️ Uçuş', widget.flightCostTL),
          _costRow('🏥 Tedavi', widget.package.priceTL),
          _costRow('🏨 Otel (${widget.package.totalDays} gece)', hotel),
          _costRow('🚗 VIP Transfer', transfer),
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

  Widget _costRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          Text(
            _formatPrice(amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0C97A), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🛡️ Medikal Seyahat Sigortası',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tedavi komplikasyonları + iptal güvencesi',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '+$INSURANCE_PRICE TL · Medikal seyahatte şart!',
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
            activeColor: AppTheme.health,
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
            '✅ Pakete Dahil Olanlar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...widget.package.includes.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 18, color: AppTheme.health),
                    const SizedBox(width: 10),
                    Text(item,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )),
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
    final travelDate = widget.searchModel.departureDate
        .toIso8601String()
        .split('T')[0];
    final hotelCost = widget.searchModel.totalBudgetTL * 0.15;
    final transferCost = widget.searchModel.totalBudgetTL * 0.05;

    await ApiService.saveMedicalBooking(
      sessionId: _sessionId,
      packageId: widget.package.id,
      clinicId: widget.package.clinicId,
      travelDate: travelDate,
      passengerCount: widget.searchModel.passengers,
      treatmentPriceTL: widget.package.priceTL,
      flightPriceTL: widget.flightCostTL,
      hotelPriceTL: hotelCost,
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