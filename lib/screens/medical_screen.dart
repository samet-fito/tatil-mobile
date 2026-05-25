import 'package:flutter/material.dart';
import '../models/medical_model.dart';
import '../models/search_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'medical_detail_screen.dart';

class MedicalScreen extends StatefulWidget {
  final SearchModel searchModel;
  final String destinationIata;
  final String cityName;
  final double flightCostTL;

  const MedicalScreen({
    super.key,
    required this.searchModel,
    required this.destinationIata,
    required this.cityName,
    required this.flightCostTL,
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
    return _packages
        .where((p) => p.treatmentType == _selectedType)
        .toList();
  }

  String _formatPrice(double price) {
    return '${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.health,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏥 Sağlık & Güzellik Paketleri',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.cityName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.health),
            )
          : Column(
              children: [
                // Filtre butonları
                Container(
                  height: 50,
                  color: AppTheme.cardBg,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedType == filter['value'] ||
                          (_selectedType == null &&
                              filter['value'] == 'all');
                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedType = filter['value']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.health
                                : AppTheme.background,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.health
                                  : Colors.black.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(filter['emoji']!,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                filter['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Paket listesi
                Expanded(
                  child: _filteredPackages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🏥',
                                  style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              const Text(
                                'Bu kategoride paket bulunamadı.',
                                style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPackages.length,
                          itemBuilder: (context, index) {
                            return _buildPackageCard(
                                _filteredPackages[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildPackageCard(MedicalPackage pkg) {
    final clinic = pkg.clinic;
    final commissionTL = pkg.priceTL * pkg.commissionRate;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicalDetailScreen(
            package: pkg,
            searchModel: widget.searchModel,
            flightCostTL: widget.flightCostTL,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.health, Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
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
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          clinic?.name ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Rozetler
                        Wrap(
                          spacing: 6,
                          children: [
                            if (clinic?.isMinistryAccredited == true)
                              _smallBadge('🏛️ Bakanlık Onaylı'),
                            if (clinic?.isJciAccredited == true)
                              _smallBadge('🌍 JCI'),
                            _smallBadge(
                                '%${pkg.successRate.toInt()} Başarı'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPrice(pkg.priceTL),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (pkg.priceEur != null)
                        Text(
                          '≈ €${pkg.priceEur!.toInt()}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // İçerik
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _infoChip(Icons.calendar_today,
                          '${pkg.totalDays} gün'),
                      const SizedBox(width: 8),
                      _infoChip(Icons.medical_services,
                          '${pkg.durationTreatmentDays} gün tedavi'),
                      const SizedBox(width: 8),
                      _infoChip(Icons.hotel,
                          '${pkg.durationRestDays} gün dinlenme'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pkg.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${pkg.includes.length} hizmet dahil',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.health,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Detayları Gör →',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
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
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.healthLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.health),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.health,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}