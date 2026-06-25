import 'activity_image.dart';
import '../widgets/experience_listing_card.dart';

/// Aktivite kartları için sosyal kanıt ve görsel zenginleştirme.
class ActivityListingEnrichment {
  static Map<String, dynamic> enrich(
    Map<String, dynamic> activity, {
    required int index,
    required String cityName,
    String? categoryId,
  }) {
    final copy = Map<String, dynamic>.from(activity);
    final rating = (copy['rating'] as num?)?.toDouble() ?? 0;
    final reviews = (copy['reviewCount'] as num?)?.toInt() ?? 0;
    final price = (copy['priceTL'] as num?)?.toInt() ?? 0;

    if (copy['imageUrl'] == null || '${copy['imageUrl']}'.isEmpty) {
      copy['imageUrl'] = ActivityImage.resolve(
        activityId: copy['id'] as String? ?? 'act-$index',
        category: categoryId ?? 'tours',
      );
    } else {
      copy['imageUrl'] = ActivityImage.resolve(
        imageUrl: copy['imageUrl'] as String?,
        activityId: copy['id'] as String? ?? 'act-$index',
        category: categoryId ?? 'tours',
      );
    }

    if (rating >= 4.7 && reviews >= 500) {
      copy['socialProofLabel'] = 'En yüksek puanlı';
      copy['socialProofStyle'] = 'purple';
    } else if (index % 3 == 0) {
      final booked = 40 + (reviews % 120) + (index * 7);
      copy['socialProofLabel'] = 'Dün $booked kez rezerve edildi';
      copy['socialProofStyle'] = 'navy';
    }

    if (copy['originalPriceTL'] == null && price > 0 && index.isEven) {
      copy['originalPriceTL'] = (price * 1.18).round();
    }

    copy['listingSubtitle'] = _subtitle(copy, categoryId);
    return copy;
  }

  static String? socialProofLabel(Map<String, dynamic> activity) =>
      activity['socialProofLabel'] as String?;

  static SocialProofStyle socialProofStyle(Map<String, dynamic> activity) {
    return switch (activity['socialProofStyle'] as String?) {
      'purple' => SocialProofStyle.purple,
      'orange' => SocialProofStyle.orange,
      _ => SocialProofStyle.navy,
    };
  }

  static String _subtitle(Map<String, dynamic> act, String? categoryId) {
    final duration = act['duration'] as String? ?? '';
    final schedule = act['scheduleLabel'] as String?;
    final parts = <String>[
      if (duration.isNotEmpty) duration,
      if (schedule != null && schedule.isNotEmpty) schedule,
      if (categoryId == 'food') 'Yerel lezzetler',
      if (categoryId == 'museums') 'İsteğe bağlı sesli rehber',
    ];
    return parts.take(2).join(' • ');
  }
}
