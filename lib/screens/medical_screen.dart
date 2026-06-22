import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/medical_model.dart';
import '../models/search_model.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../services/api_service.dart';
import '../theme/custom_page_route.dart';
import 'medical_detail_screen.dart';

class MedicalScreen extends StatefulWidget {
  final SearchModel searchModel;
  final String destinationIata;
  final String cityName;

  const MedicalScreen({
    super.key,
    required this.searchModel,
    required this.destinationIata,
    required this.cityName,
  });

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> {
  List<MedicalPackage> _packages = [];
  bool _isLoading = true;
  String? _selectedType;

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'Tümü', 'emoji': '🏥'},
    {'value': 'hair_transplant', 'label': 'Saç Ekimi', 'emoji': '💆'},
    {'value': 'dental', 'label': 'Diş', 'emoji': '🦷'},
    {'value': 'eye_laser', 'label': 'Göz Lazer', 'emoji': '👁️'},
    {'value': 'obesity', 'label': 'Obezite', 'emoji': '⚕️'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getMedicalPackages(
      iata: widget.destinationIata,
      budget: widget.searchModel.totalBudgetTL,
    );
    if (mounted) {
      setState(() {
        _packages = data.map((p) => MedicalPackage.fromJson(p)).toList();
        _isLoading = false;
      });
    }
  }

  List<MedicalPackage> get _filteredPackages {
    if (_selectedType == null || _selectedType == 'all') return _packages;
    return _packages.where((p) => p.treatmentType == _selectedType).toList();
  }

  String _formatPrice(double price) {
    return '${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _filteredPackages.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredPackages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) return _buildTrustBanner();
                          return _buildPackageCard(_filteredPackages[index - 1]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: TatilTheme.bgSoft,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.arrow_left, color: TatilTheme.textDark),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sağlık paketleri',
                      style: TatilTheme.title.copyWith(fontSize: 20),
                    ),
                    Text(
                      widget.cityName,
                      style: TatilTheme.hint,
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

  Widget _buildFilters() {
    return Container(
      height: 50,
      color: AppTheme.bgSecondary,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedType == filter['value'] ||
              (_selectedType == null && filter['value'] == 'all');
          return GestureDetector(
            onTap: () => setState(() => _selectedType = filter['value']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.teal : AppTheme.bgTertiary,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected ? AppTheme.teal : AppTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Text(filter['emoji']!, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    filter['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // VIZEGOO MEDIKAL GUVEN SKORU KARTI
  // ============================================================
  Widget _buildTrustBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.teal.withOpacity(0.15),
            AppTheme.teal.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.teal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.shield_fill,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Onaylı klinikler',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.teal),
                    ),
                    Text(
                      'Tüm klinikler doğrulandı',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _trustItem(CupertinoIcons.checkmark_shield, 'Sağlık Bakanlığı'),
              const SizedBox(width: 12),
              _trustItem(CupertinoIcons.star, 'JCI Akredite'),
              const SizedBox(width: 12),
              _trustItem(CupertinoIcons.person_2, '10.000+ hasta'),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showTeleHealthSheet,
              child: const Text(
                'Ücretsiz ön görüşme',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.teal, size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppTheme.teal),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _showTeleHealthSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ücretsiz ön görüşme',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Uzman doktorumuzla kısa bir ön görüşme yapabilirsiniz.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            // Takvim simulasyonu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgTertiary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Müsait saatler',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['10:00', '11:00', '14:00', '15:00', '16:00']
                        .map((time) => GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '$time randevusu alındı. Size bildirim gönderilecek.'),
                                    backgroundColor: AppTheme.teal,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.teal.withOpacity(0.3)),
                                ),
                                child: Text(
                                  time,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.teal),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Randevu Al',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.bandage, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text('Bu kategoride paket bulunamadı.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildPackageCard(MedicalPackage pkg) {
    final clinic = pkg.clinic;

    return GestureDetector(
      onTap: () => pushAppRoute(
        context,
        MedicalDetailScreen(
          package: pkg,
          searchModel: widget.searchModel,
          destinationIata: widget.destinationIata,
          cityName: widget.cityName,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            // Baslik
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Row(
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
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          clinic?.name ?? '',
                          style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (clinic?.isMinistryAccredited == true)
                              _smallBadge('Bakanlık onaylı'),
                            if (clinic?.isJciAccredited == true)
                              _smallBadge('JCI'),
                            _smallBadge('%${pkg.successRate.toInt()} başarı'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatPrice(pkg.priceTL),
                    style: const TextStyle(
                        color: AppTheme.teal,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            // Icerik
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _infoChip(CupertinoIcons.calendar,
                          '${pkg.totalDays} gün'),
                      const SizedBox(width: 8),
                      _infoChip(CupertinoIcons.bandage,
                          '${pkg.durationTreatmentDays} gün tedavi'),
                      const SizedBox(width: 8),
                      _infoChip(CupertinoIcons.house,
                          '${pkg.durationRestDays} gün dinlenme'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pkg.description,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          '${pkg.includes.length} hizmet dahil',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.teal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'İncele',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: AppTheme.teal, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.teal.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.teal),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.teal,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}