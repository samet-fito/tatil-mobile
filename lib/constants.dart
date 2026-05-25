class AppConstants {
  // ============================================================
  // BACKEND URL YAPILANDIRMASI
  // Geliştirme ortamında Mac'in IP adresini kullan.
  // iPhone simülatörü için Mac IP'si gerekli.
  // Android emülatörü için 10.0.2.2 kullan.
  // ============================================================

  // Mac'in yerel IP adresi (wifi değişirse güncelle)
  static const String _macIp = '192.168.1.100';
  static const int _port = 3001;

  // Platform bazlı URL seçimi
  static const String baseUrl = 'http://$_macIp:$_port/api/v1';
// Python FastAPI URL
static const String pythonBaseUrl = 'http://$_macIp:8000/api/v1';
static const String pythonSearchEndpoint = '$baseUrl/gateway/search';
static const String gatewayHealthEndpoint = '$baseUrl/gateway/health';
static const String pythonRouteEndpoint = '$pythonBaseUrl/route';

  // API endpoint'leri
  static const String searchEndpoint = '$baseUrl/search';
  static const String activitiesEndpoint = '$baseUrl/activities';
  static const String visaEndpoint = '$baseUrl/visa';
  static const String chatEndpoint = '$baseUrl/chat';
  static const String destinationsEndpoint = '$baseUrl/destinations';
  static const String healthEndpoint = 'http://$_macIp:$_port/health';

  // Timeout süreleri
  static const Duration connectTimeout = Duration(seconds: 10);
 static const Duration receiveTimeout = Duration(seconds: 8);

  // Sigorta fiyatı
  static const int insurancePrice = 450;
 static const String supabaseUrl = 'http://dcktytulwlqlwpzyxdst.supabase.co';
  static const String supabaseAnonKey = 'SeyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRja3R5dHVsd2xxbHdwenl4ZHN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2MTk4MjQsImV4cCI6MjA5NTE5NTgyNH0.hVy-szhTRbYBcKshLyyyF2_k3c7oRiDCTcmAKXPV90o';
}
// Supabase
 