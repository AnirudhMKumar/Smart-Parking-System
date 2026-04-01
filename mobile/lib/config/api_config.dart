class ApiConfig {
  static const String baseUrl = 'https://smartps.onrender.com';
  static const String wsUrl = 'wss://smartps.onrender.com/ws/parking';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
