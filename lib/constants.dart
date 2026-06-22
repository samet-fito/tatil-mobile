class AppConstants {
  // Production / Development toggle
  static const bool isProduction = true;

  // Local Mac IP
  static const String _macIp = '192.168.1.100';
  static const int _port = 3001;

  // URLs
  static const String _localUrl = 'http://$_macIp:$_port/api/v1';
  static const String _productionUrl = 'https://tatil-backend.onrender.com/api/v1';
  static String get baseUrl => isProduction ? _productionUrl : _localUrl;

  // Python API (sadece local için)
  static const String _pythonLocalUrl = 'http://$_macIp:8000/api/v1';

  // Endpoint'ler
  static String get searchEndpoint => '$baseUrl/search';
  static String get activitiesEndpoint => '$baseUrl/activities';
  static String activityTourEndpoint(String tourId) =>
      '$baseUrl/activities/tour/$tourId';
  static String activityTourOptionsEndpoint(String tourId) =>
      '$baseUrl/activities/tour/$tourId/options';
  static String get activityBookEndpoint => '$baseUrl/activities/book';
  static String get visaEndpoint => '$baseUrl/visa';
  static String get chatEndpoint => '$baseUrl/chat';
  static String get advisorDiscoveryEndpoint => '$baseUrl/advisor/discovery';
  static String get destinationsEndpoint => '$baseUrl/destinations';
  static String get healthEndpoint =>
      isProduction
          ? 'https://tatil-backend.onrender.com/health'
          : 'http://$_macIp:$_port/health';

  // Gateway endpoint'leri
  static String get pythonSearchEndpoint => '$baseUrl/gateway/search';
  static String get gatewayHealthEndpoint => '$baseUrl/gateway/health';
  static String get calendarQuotesEndpoint => '$baseUrl/calendar/quotes';
  static String get busSearchEndpoint => '$baseUrl/bus/search';
  static String get carRentalSearchEndpoint => '$baseUrl/car-rental/search';
  static String get pythonRouteEndpoint => '$_pythonLocalUrl/route';

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 12);
  static const Duration livePriceTimeout = Duration(seconds: 60);

  // Sigorta & ek gelir ürünleri (TL)
  static const int insurancePrice = 450;
  /// Biletini korumaya al — uçuşa 2 saat kalana kadar %90 iade (kişi başı).
  static const int ticketProtectionPerPersonTL = 199;
  /// Esnek bilet — online değişiklik hakkı (rezervasyon başına).
  static const int flexTicketPerBookingTL = 349;

  // Supabase
  static const String supabaseUrl = 'https://dcktytulwlqlwpzyxdst.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRja3R5dHVsd2xxbHdwenl4ZHN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2MTk4MjQsImV4cCI6MjA5NTE5NTgyNH0.hVy-szhTRbYBcKshLyyyF2_k3c7oRiDCTcmAKXPV90o';
}