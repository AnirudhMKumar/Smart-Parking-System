class ApiConfig {
  // static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // iOS simulator
  static const String baseUrl = 'http://192.168.0.106:8000'; // Physical device

  static const String wsUrl = 'ws://192.168.0.106:8000/ws/parking';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
