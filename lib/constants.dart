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
  static String get visaEndpoint => '$baseUrl/visa';
  static String get chatEndpoint => '$baseUrl/chat';
  static String get destinationsEndpoint => '$baseUrl/destinations';
  static String get healthEndpoint =>
      isProduction
          ? 'https://tatil-backend.onrender.com/health'
          : 'http://$_macIp:$_port/health';

  // Gateway endpoint'leri
  static String get pythonSearchEndpoint => '$baseUrl/gateway/search';
  static String get gatewayHealthEndpoint => '$baseUrl/gateway/health';
  static String get pythonRouteEndpoint => '$_pythonLocalUrl/route';

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 8);

  // Sigorta
  static const int insurancePrice = 450;

  // Supabase
  static const String supabaseUrl = 'https://dcktytulwlqlwpzyxdst.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRja3R5dHVsd2xxbHdwenl4ZHN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2MTk4MjQsImV4cCI6MjA5NTE5NTgyNH0.hVy-szhTRbYBcKshLyyyF2_k3c7oRiDCTcmAKXPV90o';
}