import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/search_category.dart';
import '../theme/app_theme.dart';
import '../theme/custom_page_route.dart';
import '../utils/activity_schedule_utils.dart';
import '../utils/price_format.dart';
import '../widgets/travel_state_view.dart';
import 'category_simple_checkout_screen.dart';

/// Rezervasyon sonrası — komisyon kazanılabilen partner aktiviteleri detay sayfası.
class CommissionActivitiesScreen extends StatelessWidget {
  const CommissionActivitiesScreen({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  String get _cityName => data['cityName'] as String? ?? '';
  String get _destinationIata =>
      data['iata'] as String? ?? data['destinationIata'] as String? ?? '';

  DateTime? get _eventDate {
    final raw = data['eventDeparture'];
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  DateTime? get _eventReturn {
    final raw = data['eventReturn'];
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
  String get _headline => data['headline'] as String? ?? 'Önerilen Aktiviteler';
  String get _subtitle => data['subtitle'] as String? ?? '';
  bool get _isSampleData =>
      data['source'] == 'ai' || data['dataSource'] == 'mock';

  int get _activityCount {
    var n = 0;
    for (final c in _categories) {
      n += (c['activities'] as List?)?.length ?? 0;
    }
    return n;
  }

  List<Map<String, dynamic>> get _categories =>
      List<Map<String, dynamic>>.from(data['categories'] ?? []);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _cityName.isNotEmpty ? '$_cityName Aktiviteleri' : 'Aktiviteler',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _activityCount == 0
          ? TravelStateView(
              icon: CupertinoIcons.ticket,
              title: 'Bu tarihlerde aktivite yok',
              message:
                  'Seçtiğiniz tarih aralığında etkinlik bulunamadı. '
                  'Tarihleri genişletmeyi veya başka bir şehir denemeyi düşünün.',
              primaryLabel: 'Aramayı düzenle',
              onPrimary: () => Navigator.pop(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                _buildIntroBanner(),
                if (_isSampleData) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                ],
                const SizedBox(height: 20),
                ..._categories.map(
                  (cat) => _CategorySection(
                    category: cat,
                    cityName: _cityName,
                    destinationIata: _destinationIata,
                    eventDate: _eventDate,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.orange.withValues(alpha: 0.12),
            AppTheme.bgSecondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.orangeSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.star_circle_fill, color: AppTheme.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _headline,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (_subtitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _subtitle,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
            ),
          ],
          if (_tripRangeLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.calendar, size: 14, color: AppTheme.orange),
                const SizedBox(width: 6),
                Text(
                  _tripRangeLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.orange,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'Önerilen deneyimler',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.orange),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.cityName,
    required this.destinationIata,
    this.eventDate,
  });

  final Map<String, dynamic> category;
  final String cityName;
  final String destinationIata;
  final DateTime? eventDate;

  @override
  Widget build(BuildContext context) {
    final activities = List<Map<String, dynamic>>.from(category['activities'] ?? []);
    if (activities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category['icon'] as String? ?? '🎯', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category['title'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '${activities.length} seçenek',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activities.map(
            (a) => _ActivityCard(
              activity: a,
              cityName: cityName,
              destinationIata: destinationIata,
              categoryId: category['id'] as String? ?? 'tours',
              defaultEventDate: eventDate,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.cityName,
    required this.destinationIata,
    required this.categoryId,
    this.defaultEventDate,
  });

  final Map<String, dynamic> activity;
  final String cityName;
  final String destinationIata;
  final String categoryId;
  final DateTime? defaultEventDate;

  DateTime? get _bookingDate =>
      ActivityScheduleUtils.parseEventDate(activity) ?? defaultEventDate;

  String get _scheduleLabel =>
      activity['scheduleLabel'] as String? ??
      (activity['isDaily'] == true ? 'Her gün' : '');

  @override
  Widget build(BuildContext context) {
    final price = (activity['priceTL'] as num?)?.toInt() ?? 0;
    final rating = (activity['rating'] as num?)?.toDouble() ?? 0;
    final reviews = (activity['reviewCount'] as num?)?.toInt() ?? 0;
    final highlights = List<String>.from(activity['highlights'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['summary'] as String? ?? activity['description'] as String? ?? '',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(CupertinoIcons.clock, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      activity['duration'] as String? ?? '—',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    if (_scheduleLabel.isNotEmpty) ...[
                      const SizedBox(width: 14),
                      const Icon(CupertinoIcons.calendar, size: 14, color: AppTheme.orange),
                      const SizedBox(width: 4),
                      Text(
                        _scheduleLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.orange,
                        ),
                      ),
                    ],
                    const SizedBox(width: 14),
                    const Icon(CupertinoIcons.star_fill, size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 3),
                    Text(
                      '$rating ($reviews)',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: highlights
                    .map(
                      (h) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.orangeSoft,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          h,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.orange),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              activity['detail'] as String? ?? '',
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Text(
                  PriceFormat.format(price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.orange,
                  ),
                ),
                const Text(
                  ' / kişi',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    final title = activity['title'] as String? ?? 'Aktivite';
                    final duration = activity['duration'] as String? ?? '—';
                    pushAppRoute(
                      context,
                      CategorySimpleCheckoutScreen(
                        category: SearchCategory.activities,
                        title: title,
                        subtitle:
                            '$cityName · $duration\n'
                            '${activity['summary'] ?? activity['description'] ?? ''}',
                        priceTL: price,
                        destinationCity: cityName.isNotEmpty ? cityName : 'Destinasyon',
                        destinationIata: destinationIata,
                        activity: activity,
                        activityCategory: categoryId,
                        eventDate: _bookingDate,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Rezerve Et',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
