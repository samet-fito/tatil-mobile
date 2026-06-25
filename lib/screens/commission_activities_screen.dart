import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/destination_filter_state.dart';
import '../services/activity_favorites_store.dart';
import '../config/gyg_affiliate_config.dart';
import '../services/gyg_affiliate_service.dart';
import '../theme/app_theme.dart';
import '../theme/custom_page_route.dart';
import '../utils/activity_listing_enrichment.dart';
import '../utils/price_format.dart';
import '../widgets/destination_filter_panel.dart';
import '../widgets/experience_listing_card.dart';
import '../widgets/travel_state_view.dart';
import '../widgets/vizegoo_trust_footer.dart';
import '../screens/activity_experience_detail_screen.dart';

/// Şehir aktiviteleri — GetYourGuide tarzı listeleme + filtre + güven footer.
class CommissionActivitiesScreen extends StatefulWidget {
  const CommissionActivitiesScreen({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  State<CommissionActivitiesScreen> createState() =>
      _CommissionActivitiesScreenState();
}

class _CommissionActivitiesScreenState extends State<CommissionActivitiesScreen> {
  final DestinationFilterState _filters = DestinationFilterState();
  final ActivityFavoritesStore _favorites = ActivityFavoritesStore.instance;
  String? _selectedCategoryChip;
  final Set<String> _favoriteIds = {};

  String get _cityName => widget.data['cityName'] as String? ?? '';
  String get _destinationIata =>
      widget.data['iata'] as String? ?? widget.data['destinationIata'] as String? ?? '';

  DateTime? get _eventDate {
    final raw = widget.data['eventDeparture'];
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  DateTime? get _eventReturn {
    final raw = widget.data['eventReturn'];
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  String? get _tripRangeLabel {
    final start = _eventDate;
    final end = _eventReturn;
    if (start == null || end == null) return null;
    final fmt = DateFormat('d MMM', 'tr_TR');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }

  String get _headline => widget.data['headline'] as String? ?? 'Önerilen Aktiviteler';
  String get _subtitle => widget.data['subtitle'] as String? ?? '';
  bool get _isSampleData {
    final ds = widget.data['dataSource'] as String?;
    if (ds == 'catalog' || ds == 'getyourguide') return false;
    return widget.data['source'] == 'ai' || ds == 'mock';
  }

  List<Map<String, dynamic>> get _categories =>
      List<Map<String, dynamic>>.from(widget.data['categories'] ?? []);

  List<(String id, String label)> get _categoryChips {
    return _categories
        .map((c) => (c['id'] as String? ?? '', c['title'] as String? ?? ''))
        .where((e) => e.$1.isNotEmpty && e.$2.isNotEmpty)
        .toList();
  }

  List<({Map<String, dynamic> activity, String categoryId})> get _filteredActivities {
    final items = <({Map<String, dynamic> activity, String categoryId})>[];
    var index = 0;
    for (final cat in _categories) {
      final catId = cat['id'] as String? ?? 'tours';
      if (_selectedCategoryChip != null && _selectedCategoryChip != catId) {
        continue;
      }
      final acts = List<Map<String, dynamic>>.from(cat['activities'] ?? []);
      for (final raw in acts) {
        final enriched = ActivityListingEnrichment.enrich(
          raw,
          index: index++,
          cityName: _cityName,
          categoryId: catId,
        );
        final price = (enriched['priceTL'] as num?)?.toInt() ?? 0;
        if (!_filters.matchesActivityPrice(price)) continue;
        if (!_filters.matchesActivityCategory(catId)) continue;
        items.add((activity: enriched, categoryId: catId));
      }
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _favorites.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _toggleFavorite(Map<String, dynamic> activity) async {
    final id = ActivityFavoritesStore.activityId(activity, _cityName);
    final on = await _favorites.toggle(id);
    if (!mounted) return;
    setState(() {
      if (on) {
        _favoriteIds.add(id);
      } else {
        _favoriteIds.remove(id);
      }
    });
  }

  bool _isFavorite(Map<String, dynamic> activity) {
    final id = ActivityFavoritesStore.activityId(activity, _cityName);
    return _favoriteIds.contains(id) || _favorites.isFavorite(id);
  }

  void _openFilters() {
    DestinationFilterPanel.show(
      context,
      state: _filters,
      showRegion: false,
      onApply: () => setState(() {}),
      onClear: () => setState(() {}),
    );
  }

  void _openCheckout(Map<String, dynamic> activity, String categoryId) {
    pushAppRoute(
      context,
      ActivityExperienceDetailScreen(
        activity: activity,
        cityName: _cityName,
        destinationIata: _destinationIata,
        categoryId: categoryId,
        eventDate: _eventDate,
        returnDate: _eventReturn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredActivities;

    return ListenableBuilder(
      listenable: _filters,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.bgSecondary,
          appBar: AppBar(
            backgroundColor: AppTheme.bgSecondary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cityName.isNotEmpty ? _cityName : 'Aktiviteler',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                if (_tripRangeLabel != null)
                  Text(
                    _tripRangeLabel!,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
              ],
            ),
          ),
          body: _categories.isEmpty
              ? TravelStateView(
                  icon: CupertinoIcons.ticket,
                  title: 'Bu tarihlerde aktivite yok',
                  message:
                      'Seçtiğiniz tarih aralığında etkinlik bulunamadı. '
                      'Tarihleri genişletmeyi veya başka bir şehir denemeyi düşünün.',
                  primaryLabel: 'Geri dön',
                  onPrimary: () => Navigator.pop(context),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ActivityFilterChipBar(
                      filterCount: _filters.activeCount,
                      onOpenFilters: _openFilters,
                      categoryChips: _categoryChips,
                      selectedCategory: _selectedCategoryChip,
                      onCategorySelected: (id) =>
                          setState(() => _selectedCategoryChip = id),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: items.isEmpty
                          ? TravelStateView(
                              icon: CupertinoIcons.slider_horizontal_3,
                              title: 'Filtreye uygun aktivite yok',
                              message:
                                  'Farklı bütçe veya seyahat stili seçerek listeyi genişletebilirsiniz.',
                              primaryLabel: 'Filtreleri temizle',
                              onPrimary: () {
                                setState(() {
                                  _filters.clearAll();
                                  _selectedCategoryChip = null;
                                });
                              },
                            )
                          : ListView(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                                  child: _buildIntroBanner(items.length),
                                ),
                                if (_isSampleData) ...[
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.orangeSoft,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: const Text(
                                        'Örnek aktiviteler — canlı liste yüklenemedi',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                ...items.asMap().entries.expand((entry) {
                                  final i = entry.key;
                                  final item = entry.value;
                                  final act = item.activity;
                                  return [
                                    if (i > 0)
                                      const Divider(
                                        height: 1,
                                        indent: 16,
                                        endIndent: 16,
                                      ),
                                    ExperienceListingCard(
                                      title: act['title'] as String? ?? '',
                                      activityId: act['id'] as String? ?? act['title'] as String? ?? 'act',
                                      category: item.categoryId,
                                      subtitle: act['listingSubtitle'] as String?,
                                      duration: act['duration'] as String? ?? '—',
                                      priceTL: (act['priceTL'] as num?)?.toInt() ?? 0,
                                      originalPriceTL:
                                          (act['originalPriceTL'] as num?)?.toInt(),
                                      imageUrl: act['imageUrl'] as String?,
                                      rating: (act['rating'] as num?)?.toDouble() ?? 0,
                                      reviewCount:
                                          (act['reviewCount'] as num?)?.toInt() ?? 0,
                                      socialProofLabel:
                                          ActivityListingEnrichment.socialProofLabel(act),
                                      socialProofStyle:
                                          ActivityListingEnrichment.socialProofStyle(act),
                                      isFavorite: _isFavorite(act),
                                      onFavoriteToggle: () => _toggleFavorite(act),
                                      onTap: () => _openCheckout(act, item.categoryId),
                                    ),
                                  ];
                                }),
                                const VizegooTrustFooter(compact: true),
                              ],
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildIntroBanner(int count) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.fuchsiaSoft,
            AppTheme.purpleSoft,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headline,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          if (_subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.35),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '$count deneyim · ${PriceFormat.format(_minPrice(items: _filteredActivities))}’den başlayan fiyatlar',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.fuchsia,
            ),
          ),
          if (GygAffiliateConfig.useAffiliateLinks && _cityName.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => GygAffiliateService.openCity(context, _cityName),
                icon: const Icon(CupertinoIcons.globe, size: 16),
                label: const Text('Tümünü GetYourGuide\'da gör'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.purpleDark,
                  side: BorderSide(color: AppTheme.purple.withValues(alpha: 0.35)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _minPrice({required List<({Map<String, dynamic> activity, String categoryId})> items}) {
    final prices = items
        .map((e) => (e.activity['priceTL'] as num?)?.toInt() ?? 0)
        .where((p) => p > 0)
        .toList();
    if (prices.isEmpty) return 0;
    prices.sort();
    return prices.first;
  }
}
