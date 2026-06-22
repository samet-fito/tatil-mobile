import '../models/smart_travel_advisor_model.dart';

/// Canlı etkinlik API yanıtı eksik/boş olduğunda yedek etkinlikler.
class AdvisorEventsCatalog {
  AdvisorEventsCatalog._();

  static const _events = <String, List<LiveEventAffiliate>>{
    'DXB': [
      LiveEventAffiliate(
        eventName: 'Dubai Summer Surprises',
        date: 'Temmuz 2026',
        description:
            'AVM etkinlikleri, çocuk atölyeleri ve gece konserleri — Dubai Mall ve City Walk.',
        ticketAffiliateUrl: 'https://www.visitdubai.com/en/events',
      ),
      LiveEventAffiliate(
        eventName: 'La Perle by Dragone',
        date: 'Hafta içi / hafta sonu seanslar',
        description: 'Su ve akrobatik gösteri — Al Habtoor City.',
        ticketAffiliateUrl: 'https://www.laperle.com/en/book-tickets',
      ),
      LiveEventAffiliate(
        eventName: 'Dubai Opera programı',
        date: 'Sezon boyunca',
        description: 'Klasik, caz ve dünya müziği konserleri — Downtown.',
        ticketAffiliateUrl: 'https://www.dubaiopera.com/en-US/tickets',
      ),
    ],
    'IST': [
      LiveEventAffiliate(
        eventName: 'Zorlu PSM etkinlik takvimi',
        date: 'Güncel sezon',
        description: 'Konser, tiyatro ve stand-up — Beşiktaş.',
        ticketAffiliateUrl: 'https://www.zorlupsm.com/tr/etkinlikler',
      ),
      LiveEventAffiliate(
        eventName: 'IKSV Jazz Festival',
        date: 'Yaz ayları',
        description: 'Açık hava caz konserleri — çeşitli mekânlar.',
        ticketAffiliateUrl: 'https://caz.iksv.org/tr',
      ),
    ],
    'ROM': [
      LiveEventAffiliate(
        eventName: 'Opera di Roma yaz konserleri',
        date: 'Haziran – Ağustos',
        description: 'Caraçi Terme ve açık hava operası.',
        ticketAffiliateUrl: 'https://www.operaroma.it/en/',
      ),
    ],
    'PAR': [
      LiveEventAffiliate(
        eventName: 'Fête de la Musique',
        date: '21 Haziran',
        description: 'Ücretsiz sokak konserleri — tüm şehir.',
        ticketAffiliateUrl: 'https://fetedelamusique.culture.gouv.fr/',
      ),
    ],
  };

  static List<LiveEventAffiliate> forIata(String iata) {
    return List<LiveEventAffiliate>.from(_events[iata.toUpperCase()] ?? const []);
  }
}
