import 'package:flutter/cupertino.dart';

enum SearchCategory {
  flight,
  hotel,
  bus,
  packageTour,
  carRental,
  transfer,
  activities,
}

extension SearchCategoryMeta on SearchCategory {
  String get label {
    switch (this) {
      case SearchCategory.flight:
        return 'Uçak';
      case SearchCategory.hotel:
        return 'Otel';
      case SearchCategory.bus:
        return 'Otobüs';
      case SearchCategory.packageTour:
        return 'Paket Tur';
      case SearchCategory.carRental:
        return 'Kiralık Araç';
      case SearchCategory.transfer:
        return 'Transfer';
      case SearchCategory.activities:
        return 'Aktivite';
    }
  }

  String get headerSubtitle {
    switch (this) {
      case SearchCategory.flight:
        return 'Gidiş-dönüş · çoklu uçuş · tek yön';
      case SearchCategory.hotel:
        return 'Konaklama seçeneklerini keşfet';
      case SearchCategory.bus:
        return 'Şehirler arası otobüs seferleri';
      case SearchCategory.packageTour:
        return 'Uçuş + otel + transfer paketleri';
      case SearchCategory.carRental:
        return 'Araç kiralama fiyatlarını karşılaştır';
      case SearchCategory.transfer:
        return 'Havalimanı ve şehir transferleri';
      case SearchCategory.activities:
        return 'Turlar, müzeler ve etkinlikler';
    }
  }

  String get searchButtonLabel {
    switch (this) {
      case SearchCategory.flight:
        return 'Uçuş Ara';
      case SearchCategory.hotel:
        return 'Otel Ara';
      case SearchCategory.bus:
        return 'Sefer Ara';
      case SearchCategory.packageTour:
        return 'Paketleri Keşfet';
      case SearchCategory.carRental:
        return 'Kiralık Araç Ara';
      case SearchCategory.transfer:
        return 'Transfer Ara';
      case SearchCategory.activities:
        return 'Aktivite & Etkinlik Bul';
    }
  }

  IconData get icon {
    switch (this) {
      case SearchCategory.flight:
        return CupertinoIcons.airplane;
      case SearchCategory.hotel:
        return CupertinoIcons.bed_double;
      case SearchCategory.bus:
        return CupertinoIcons.bus;
      case SearchCategory.packageTour:
        return CupertinoIcons.briefcase_fill;
      case SearchCategory.carRental:
        return CupertinoIcons.car_detailed;
      case SearchCategory.transfer:
        return CupertinoIcons.arrow_right_arrow_left;
      case SearchCategory.activities:
        return CupertinoIcons.ticket_fill;
    }
  }

  String get gridLabel {
    switch (this) {
      case SearchCategory.carRental:
        return 'Kiralık Araç';
      case SearchCategory.activities:
        return 'Aktivite &\nEtkinlikler';
      default:
        return label;
    }
  }

  bool get requiresDestination => this != SearchCategory.packageTour;

  bool get showInspirationHero => this == SearchCategory.packageTour;

  bool get showBudgetField => this == SearchCategory.packageTour;

  bool get showAdvancedFilters => this == SearchCategory.packageTour;

  bool get showCheapestToggle => this == SearchCategory.packageTour;

  bool get showSearchGuide =>
      this == SearchCategory.packageTour ||
      this == SearchCategory.carRental ||
      this == SearchCategory.transfer ||
      this == SearchCategory.activities;

  /// Tarih seçici orta rozet metni — kategoriye göre.
  String? dateSpanBadgeLabel({
    required int nights,
    required DateTime departure,
    required DateTime returnDate,
  }) {
    switch (this) {
      case SearchCategory.hotel:
      case SearchCategory.packageTour:
        return '$nights gece';
      case SearchCategory.carRental:
        final days = returnDate.difference(departure).inDays.clamp(1, 30);
        return '$days gün';
      case SearchCategory.flight:
        return 'Gidiş-dönüş';
      case SearchCategory.activities:
        final days = returnDate.difference(departure).inDays;
        if (days <= 0) return 'Aynı gün';
        return '$days gün aralığı';
      case SearchCategory.bus:
      case SearchCategory.transfer:
        return null;
    }
  }

  /// Tarih aralığı seçicide sol/sağ alan etiketleri.
  String get dateRangeStartLabel {
    switch (this) {
      case SearchCategory.hotel:
        return 'Giriş';
      case SearchCategory.carRental:
        return 'Alış tarihi';
      default:
        return 'Gidiş';
    }
  }

  String get dateRangeEndLabel {
    switch (this) {
      case SearchCategory.hotel:
        return 'Çıkış';
      case SearchCategory.carRental:
        return 'Teslim tarihi';
      default:
        return 'Dönüş';
    }
  }

  List<String> get searchGuideSteps {
    if (!showSearchGuide) return const [];

    switch (this) {
      case SearchCategory.packageTour:
        return [
          'İlham veren destinasyonlardan birini seçin veya listeden şehir arayın',
          'Tarih ve isteğe bağlı bütçenizi girin',
          'Paketleri Keşfet ile uçuş+otel kombinasyonlarını görün',
        ];
      case SearchCategory.carRental:
        return [
          'Aracı alacağınız şehri seçin',
          'Alış ve teslim tarihlerini girin',
          'Kiralık Araç Ara ile sınıfları karşılaştırın',
        ];
      case SearchCategory.transfer:
        return [
          'Destinasyonu ve güzergâhı seçin',
          'Tarih ve yolcu sayısını girin',
          'Transfer Ara ile araç tipini seçin',
        ];
      case SearchCategory.activities:
        return [
          'Şehri ve ziyaret tarih aralığını seçin',
          'Aktivite & Etkinlik Bul ile listeyi açın',
          'Tarihe uygun turları ve etkinlikleri inceleyin',
        ];
      case SearchCategory.flight:
      case SearchCategory.hotel:
      case SearchCategory.bus:
        return const [];
    }
  }
}
