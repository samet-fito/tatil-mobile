import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../config/gyg_affiliate_config.dart';
import '../models/search_category.dart';
import '../services/activity_favorites_store.dart';
import '../services/gyg_affiliate_service.dart';
import '../services/api_service.dart';
import '../utils/activity_image.dart';
import '../theme/app_theme.dart';
import '../theme/custom_page_route.dart';
import '../utils/price_format.dart';
import 'category_simple_checkout_screen.dart';

/// Aktivite detay — uygulama içi gezinme; satın alma GetYourGuide affiliate linki.
class ActivityExperienceDetailScreen extends StatefulWidget {
  const ActivityExperienceDetailScreen({
    super.key,
    required this.activity,
    required this.cityName,
    required this.destinationIata,
    required this.categoryId,
    this.eventDate,
    this.returnDate,
  });

  final Map<String, dynamic> activity;
  final String cityName;
  final String destinationIata;
  final String categoryId;
  final DateTime? eventDate;
  final DateTime? returnDate;

  @override
  State<ActivityExperienceDetailScreen> createState() =>
      _ActivityExperienceDetailScreenState();
}

class _ActivityExperienceDetailScreenState
    extends State<ActivityExperienceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _travelers = 2;
  late DateTime _selectedDate;
  bool _favorite = false;
  int? _gygOptionId;
  bool _loadingOptions = false;
  String? _optionsHint;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _selectedDate = widget.eventDate ?? DateTime.now().add(const Duration(days: 14));
    _loadFavorite();
    if (!GygAffiliateConfig.useAffiliateLinks) {
      _loadGygOptions();
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadFavorite() async {
    await ActivityFavoritesStore.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _favorite = ActivityFavoritesStore.instance.isFavorite(
        ActivityFavoritesStore.activityId(widget.activity, widget.cityName),
      );
    });
  }

  int get _priceTL => (widget.activity['priceTL'] as num?)?.toInt() ?? 0;
  double get _rating => (widget.activity['rating'] as num?)?.toDouble() ?? 0;
  int get _reviews => (widget.activity['reviewCount'] as num?)?.toInt() ?? 0;

  int? get _gygTourId {
    final raw = widget.activity['gygTourId'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  Future<void> _loadGygOptions() async {
    final tourId = _gygTourId;
    if (tourId == null) return;

    setState(() {
      _loadingOptions = true;
      _optionsHint = null;
      _gygOptionId = null;
    });

    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final result = await ApiService.getActivityTourOptions(
      tourId: tourId.toString(),
      date: date,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final options = List<Map<String, dynamic>>.from(
        result['data']?['options'] ?? [],
      );
      final first = options.isNotEmpty ? options.first : null;
      final optionId = first?['option_id'] ?? first?['optionId'];
      setState(() {
        _loadingOptions = false;
        _gygOptionId = optionId is int
            ? optionId
            : int.tryParse(optionId?.toString() ?? '');
        _optionsHint = _gygOptionId != null
            ? 'Müsaitlik doğrulandı'
            : 'Bu tarih için seçenek bulunamadı';
      });
      return;
    }

    setState(() {
      _loadingOptions = false;
      _optionsHint = 'Müsaitlik kontrol edilemedi';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadGygOptions();
    }
  }

  void _checkAvailability() {
    if (GygAffiliateConfig.useAffiliateLinks) {
      GygAffiliateService.openActivity(
        context,
        activity: widget.activity,
        cityName: widget.cityName,
      );
      return;
    }

    if (_gygTourId != null && _gygOptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seçilen tarih için müsaitlik yok. Başka bir tarih deneyin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final title = widget.activity['title'] as String? ?? 'Aktivite';
    final duration = widget.activity['duration'] as String? ?? '—';
    final activityPayload = {
      ...widget.activity,
      if (_gygOptionId != null) 'gygOptionId': _gygOptionId,
    };
    pushAppRoute(
      context,
      CategorySimpleCheckoutScreen(
        category: SearchCategory.activities,
        title: title,
        subtitle:
            '${widget.cityName} · $duration · $_travelers kişi\n'
            '${widget.activity['summary'] ?? widget.activity['description'] ?? ''}',
        priceTL: _priceTL * _travelers,
        destinationCity: widget.cityName,
        destinationIata: widget.destinationIata,
        passengers: _travelers,
        activity: activityPayload,
        activityCategory: widget.categoryId,
        eventDate: _selectedDate,
        departureDate: _selectedDate,
        returnDate: widget.returnDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.activity['imageUrl'] as String?;
    final fmt = DateFormat('EEE, d MMM', 'tr_TR');

    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppTheme.purpleDark,
            flexibleSpace: FlexibleSpaceBar(
              background: ActivityNetworkImage(
                imageUrl: imageUrl,
                activityId: widget.activity['id'] as String? ?? 'detail',
                category: widget.categoryId,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Text(
                    widget.activity['title'] as String? ?? '',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.purpleDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.orange, size: 16),
                      Text(
                        ' $_rating · $_reviews yorum',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${PriceFormat.format(_priceTL)} / kişi',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.fuchsia,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Çocuklar için indirimli fiyatlar mevcut olabilir',
                      style: TextStyle(fontSize: 11, color: AppTheme.teal),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _pickerTile(
                          label: 'Tarih',
                          value: fmt.format(_selectedDate),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _pickerTile(
                          label: 'Yolcu',
                          value: '$_travelers',
                          onTap: () async {
                            final n = await showDialog<int>(
                              context: context,
                              builder: (ctx) => SimpleDialog(
                                title: const Text('Yolcu sayısı'),
                                children: [1, 2, 3, 4, 5, 6]
                                    .map(
                                      (c) => SimpleDialogOption(
                                        onPressed: () => Navigator.pop(ctx, c),
                                        child: Text('$c kişi'),
                                      ),
                                    )
                                    .toList(),
                              ),
                            );
                            if (n != null) setState(() => _travelers = n);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (!GygAffiliateConfig.useAffiliateLinks && _gygTourId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_loadingOptions)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            _gygOptionId != null
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.exclamationmark_circle,
                            size: 16,
                            color: _gygOptionId != null
                                ? AppTheme.teal
                                : Colors.orange,
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _optionsHint ?? 'GetYourGuide müsaitliği kontrol ediliyor…',
                            style: TextStyle(
                              fontSize: 12,
                              color: _gygOptionId != null
                                  ? AppTheme.teal
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _checkAvailability,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        GygAffiliateConfig.useAffiliateLinks
                            ? 'GetYourGuide\'da satın al'
                            : 'Müsaitliği kontrol et',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                  if (GygAffiliateConfig.useAffiliateLinks) ...[
                    const SizedBox(height: 12),
                    _policyBox(
                      'GetYourGuide partner linki',
                      'Rezervasyon güvenli tarayıcıda tamamlanır. Komisyon '
                      '31 güne kadar partner hesabınıza yansır.',
                    ),
                  ],
                  const SizedBox(height: 8),
                  _policyBox(
                    'Ücretsiz iptal',
                    GygAffiliateConfig.useAffiliateLinks
                        ? 'İptal koşulları GetYourGuide sayfasında gösterilir.'
                        : 'Deneyim başlamadan 24 saat öncesine kadar tam iade.',
                  ),
                  const SizedBox(height: 8),
                  if (!GygAffiliateConfig.useAffiliateLinks)
                    _policyBox(
                      'Şimdi rezerve et, sonra öde',
                      'Esnek planlama için yerinizi şimdi ayırtın.',
                    ),
                  if (!GygAffiliateConfig.useAffiliateLinks) const SizedBox(height: 8),
                  _urgencyCard(),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    labelColor: AppTheme.purpleDark,
                    unselectedLabelColor: AppTheme.textMuted,
                    indicatorColor: AppTheme.orange,
                    tabs: const [
                      Tab(text: 'Genel bakış'),
                      Tab(text: 'Dahil olanlar'),
                      Tab(text: 'Buluşma'),
                      Tab(text: 'Yorumlar'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _overviewTab(),
                        _includedTab(),
                        _meetingTab(),
                        _reviewsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _stickyBar(),
    );
  }

  Widget _pickerTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(CupertinoIcons.chevron_down, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _policyBox(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.teal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(body, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgencyCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.orangeSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.flame_fill, color: AppTheme.orange),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Erken ayırtın! Bu deneyim ortalama 50 gün önceden rezerve ediliyor.',
              style: TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewTab() {
    return Text(
      widget.activity['detail'] as String? ??
          widget.activity['description'] as String? ??
          'Partner ağımız üzerinden güvenli rezervasyon.',
      style: const TextStyle(fontSize: 13, height: 1.5),
    );
  }

  Widget _includedTab() {
    final highlights = List<String>.from(widget.activity['highlights'] ?? []);
    final items = highlights.isNotEmpty
        ? highlights
        : [
            'Rehberli deneyim',
            'Mobil bilet',
            'Anında onay',
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 16, color: AppTheme.textPrimary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(h, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _meetingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(CupertinoIcons.location_solid, color: AppTheme.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Buluşma noktası', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      '${widget.cityName} merkez — rezervasyon sonrası tam adres paylaşılır.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Aktivite buluşma noktasında sona erer.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _reviewsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
        ),
        const Text('Vizegoo partner yorumları', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 12),
        Text(
          '“${widget.activity['summary'] ?? 'Harika bir deneyim, rehber çok bilgiliydi.'}”',
          style: const TextStyle(fontSize: 13, height: 1.45, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _stickyBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _checkAvailability,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                GygAffiliateConfig.useAffiliateLinks
                    ? 'GetYourGuide\'da satın al'
                    : 'Müsaitliği kontrol et',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () async {
              final id = ActivityFavoritesStore.activityId(widget.activity, widget.cityName);
              final on = await ActivityFavoritesStore.instance.toggle(id);
              if (mounted) setState(() => _favorite = on);
            },
            icon: Icon(
              _favorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: _favorite ? AppTheme.fuchsia : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
