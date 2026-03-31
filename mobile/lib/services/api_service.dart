import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  late final Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _token = null;
          _saveToken(null);
        }
        handler.next(error);
      },
    ));
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
  }

  Future<void> _saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('access_token', token);
    } else {
      await prefs.remove('access_token');
    }
  }

  void setToken(String token) {
    _token = token;
    _saveToken(token);
  }

  void clearToken() {
    _token = null;
    _saveToken(null);
  }

  bool get isAuthenticated => _token != null;

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio
        .post('/api/auth/login', data: {'email': email, 'password': password});
    final token = response.data['access_token'];
    setToken(token);
    return response.data;
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String fullName,
      {String? phone}) async {
    final response = await _dio.post('/api/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      if (phone != null) 'phone': phone,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/api/auth/me');
    return response.data;
  }

  // Parking
  Future<Map<String, dynamic>> getParkingStats() async {
    final response = await _dio.get('/api/parking/stats');
    return response.data;
  }

  Future<List<dynamic>> getSpots() async {
    final response = await _dio.get('/api/parking/spots');
    return response.data;
  }

  Future<List<dynamic>> getAvailableSpots() async {
    final response = await _dio.get('/api/parking/spots/available');
    return response.data;
  }

  // OCR
  Future<Map<String, dynamic>> recognizePlate(String imagePath) async {
    final formData =
        FormData.fromMap({'file': await MultipartFile.fromFile(imagePath)});
    final response = await _dio.post('/api/ocr/recognize', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> recordEntry(String plateNumber,
      {int? spotId}) async {
    final data = <String, dynamic>{'plate_number': plateNumber};
    if (spotId != null) data['spot_id'] = spotId;
    final response = await _dio.post('/api/ocr/entry', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> recordExit(String plateNumber) async {
    final response =
        await _dio.post('/api/ocr/exit', data: {'plate_number': plateNumber});
    return response.data;
  }

  // Reservations
  Future<Map<String, dynamic>> createReservation({
    required int spotId,
    String? plateNumber,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await _dio.post('/api/reservations', data: {
      'spot_id': spotId,
      if (plateNumber != null) 'plate_number': plateNumber,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
    });
    return response.data;
  }

  Future<List<dynamic>> getReservations({bool activeOnly = false}) async {
    final response = await _dio
        .get('/api/reservations', queryParameters: {'active_only': activeOnly});
    return response.data;
  }

  Future<Map<String, dynamic>> cancelReservation(int id) async {
    final response = await _dio.patch('/api/reservations/$id/cancel');
    return response.data;
  }

  Future<List<dynamic>> getReservationHistory() async {
    final response = await _dio.get('/api/reservations/history');
    return response.data;
  }

  // Vehicles
  Future<List<dynamic>> getVehicles() async {
    final response = await _dio.get('/api/vehicles');
    return response.data;
  }

  Future<Map<String, dynamic>> addVehicle({
    required String plateNumber,
    String? vehicleType,
    String? color,
  }) async {
    final response = await _dio.post('/api/vehicles', data: {
      'plate_number': plateNumber,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (color != null) 'color': color,
    });
    return response.data;
  }

  Future<void> deleteVehicle(int id) async {
    await _dio.delete('/api/vehicles/$id');
  }

  // Parking lot info
  Future<List<dynamic>> getParkingLots() async {
    final response = await _dio.get('/api/parking/lot');
    return response.data;
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
