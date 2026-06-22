import '../models/budget_package_offer.dart';
import 'package:flutter/material.dart';

/// Canlı / plan veri kaynağı.
enum OfferDataKind { live, partial, plan }

class OfferDataColors {
  const OfferDataColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

/// Tüketici yüzeylerinde tek tip, sade dil (before.click).
abstract final class ConsumerCopy {
  static OfferDataKind offerDataKind({
    required bool flightsLive,
    required bool hotelsLive,
    required bool flightVerified,
  }) {
    if (flightsLive && flightVerified && hotelsLive) {
      return OfferDataKind.live;
    }
    if (flightsLive || hotelsLive) return OfferDataKind.partial;
    return OfferDataKind.plan;
  }

  static String offerDataLabel(OfferDataKind kind) {
    switch (kind) {
      case OfferDataKind.live:
        return 'Güncel fiyat';
      case OfferDataKind.partial:
        return 'Kısmen güncel';
      case OfferDataKind.plan:
        return 'Tahmini fiyat';
    }
  }

  static IconData offerDataIcon(OfferDataKind kind) {
    switch (kind) {
      case OfferDataKind.live:
        return Icons.bolt_rounded;
      case OfferDataKind.partial:
        return Icons.sync_rounded;
      case OfferDataKind.plan:
        return Icons.auto_awesome_outlined;
    }
  }

  static OfferDataColors offerDataColors(
    OfferDataKind kind, {
    bool onDark = false,
  }) {
    switch (kind) {
      case OfferDataKind.live:
        return OfferDataColors(
          foreground: onDark ? const Color(0xFF5EEAD4) : const Color(0xFF0D9488),
          background: onDark
              ? const Color(0xFF5EEAD4).withValues(alpha: 0.15)
              : const Color(0xFF0D9488).withValues(alpha: 0.12),
          border: onDark
              ? const Color(0xFF5EEAD4).withValues(alpha: 0.35)
              : const Color(0xFF0D9488).withValues(alpha: 0.28),
        );
      case OfferDataKind.partial:
        return OfferDataColors(
          foreground: onDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C),
          background: onDark
              ? const Color(0xFFFDBA74).withValues(alpha: 0.12)
              : const Color(0xFFEA580C).withValues(alpha: 0.1),
          border: onDark
              ? const Color(0xFFFDBA74).withValues(alpha: 0.3)
              : const Color(0xFFEA580C).withValues(alpha: 0.25),
        );
      case OfferDataKind.plan:
        return OfferDataColors(
          foreground: onDark ? Colors.white70 : const Color(0xFF64748B),
          background: onDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFF1F5F9),
          border: onDark
              ? Colors.white.withValues(alpha: 0.2)
              : const Color(0xFFE2E8F0),
        );
    }
  }

  static String offerDataHint({
    required bool flightsLive,
    required bool hotelsLive,
    required bool flightVerified,
  }) {
    final kind = offerDataKind(
      flightsLive: flightsLive,
      hotelsLive: hotelsLive,
      flightVerified: flightVerified,
    );
    switch (kind) {
      case OfferDataKind.live:
        return 'Güncel fiyat · uçuş ve otel doğrulandı';
      case OfferDataKind.partial:
        if (flightsLive && !hotelsLive) {
          return 'Uçuş güncel · otel tahmini';
        }
        if (hotelsLive && !(flightsLive && flightVerified)) {
          return 'Otel güncel · uçuş tahmini';
        }
        return 'Bazı kalemler güncel, bazıları tahmini';
      case OfferDataKind.plan:
        return 'Tahmini fiyat · detayda güncellenir';
    }
  }

  static String priceNote({required bool hasLive}) =>
      hasLive ? 'canlı teklif' : 'plan tahmini';

  static String packageSubtitle({required bool hasLive}) =>
      hasLive ? 'Uçak + otel · canlı' : 'Uçak + otel · plan tahmini';

  static String payableTotal = 'Ödeyeceğiniz tutar';

  static String totalLabel = 'Toplam';

  static String priceSource({
    required bool flightsLive,
    required bool hotelsLive,
    bool flightVerified = true,
  }) {
    return offerDataLabel(
      offerDataKind(
        flightsLive: flightsLive,
        hotelsLive: hotelsLive,
        flightVerified: flightVerified,
      ),
    );
  }

  static String loadingPrices = 'Uçuş ve otel fiyatları yükleniyor…';

  static String flightUnavailableTitle = 'Uçuş fiyatı alınamadı';

  static String flightUnavailableBody =
      'Şu an uçuş fiyatlarına ulaşılamıyor. Lütfen birkaç dakika sonra tekrar deneyin.';

  static String hotelUnavailableTitle = 'Otel fiyatı alınamadı';

  static String hotelUnavailableBody =
      'Şu an otel fiyatlarına ulaşılamıyor. Lütfen birkaç dakika sonra tekrar deneyin.';

  /// Öneri kartı — bütçe içinde kalan limit + paket toplamı.
  static String recommendationBudgetInsight({
    required String remainingFormatted,
    required String recommendationFormatted,
  }) =>
      'Bütçenizden geriye kalan limit: $remainingFormatted. '
      'Öneri kartımızın toplam tutarı: $recommendationFormatted.';

  /// Öneri kartı bütçeyi aştığında.
  static String recommendationOverBudgetInsight({
    required String recommendationFormatted,
    required String overFormatted,
  }) =>
      'Öneri kartımızın toplam tutarı $recommendationFormatted. '
      'Bütçenizi $overFormatted aşıyor.';

  static String liveEnrichedCount(int count) =>
      count == 1 ? '1 canlı teklif' : '$count canlı teklif';

  static const String liveEnriching = 'Canlı fiyatlar güncelleniyor…';

  static String budgetFitLabel(BudgetFitKind kind, {required bool hasLive}) {
    switch (kind) {
      case BudgetFitKind.unscoped:
        return '';
      case BudgetFitKind.liveWithinBudget:
        return 'Bütçeye uygun';
      case BudgetFitKind.planWithinBudget:
        return hasLive ? 'Bütçede · fiyat güncellendi' : 'Bütçede · tahmini';
      case BudgetFitKind.planOnly:
        return 'Tahmini fiyat';
      case BudgetFitKind.overBudget:
        return 'Bütçe üstü';
    }
  }

  static String orchestratorLiveHigher(int budgetTL) =>
      'Güncel fiyatlar tahminden yüksek. '
      'Kartlar bütçenize ($budgetTL TL) en yakın paketleri gösterir.';

  static String orchestratorLiveWithin(int count) =>
      '$count rota güncel fiyatlarla bütçenize uygun.';

  static String loadingMerge =
      'Rotalar ve güncel fiyatlar birleştiriliyor';
}
