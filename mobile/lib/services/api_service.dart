import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  late final Dio _dio;
  String? _token;
  BuildContext? _context;

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
      onResponse: (response, handler) {
        handler.next(response);
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

  void setContext(BuildContext context) {
    _context = context;
  }

  void showError(String message) {
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
      );
    }
  }

  String getErrorMessage(DioException e) {
    if (e.response?.data is Map && e.response!.data['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Check your internet connection.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        switch (code) {
          case 401:
            return 'Session expired. Please login again.';
          case 403:
            return 'Access denied.';
          case 404:
            return 'Resource not found.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'Server error ($code). Please try again.';
        }
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      default:
        return 'Something went wrong. Please try again.';
    }
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
    try {
      final response = await _dio.post('/api/auth/login',
          data: {'email': email, 'password': password});
      final token = response.data['access_token'];
      setToken(token);
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String fullName,
      {String? phone}) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phone != null) 'phone': phone,
      });
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/api/auth/me');
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  // Parking
  Future<Map<String, dynamic>> getParkingStats() async {
    try {
      final response = await _dio.get('/api/parking/stats');
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  Future<List<dynamic>> getSpots() async {
    try {
      final response = await _dio.get('/api/parking/spots');
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  Future<List<dynamic>> getAvailableSpots() async {
    try {
      final response = await _dio.get('/api/parking/spots/available');
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  // OCR
  Future<Map<String, dynamic>> recognizePlate(String imagePath) async {
    try {
      final file = File(imagePath);
      final length = await file.length();

      MultipartFile multipartFile;
      if (length > 500000) {
        multipartFile = await MultipartFile.fromFile(
          imagePath,
          filename: 'plate.jpg',
        );
      } else {
        multipartFile = await MultipartFile.fromFile(
          imagePath,
          filename: 'plate.jpg',
        );
      }

      final formData = FormData.fromMap({'file': multipartFile});
      final response = await _dio.post('/api/ocr/recognize', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  Future<Map<String, dynamic>> recordEntry(String plateNumber,
      {int? spotId}) async {
    try {
      final data = <String, dynamic>{'plate_number': plateNumber};
      if (spotId != null) data['spot_id'] = spotId;
      final response = await _dio.post('/api/ocr/entry', data: data);
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  Future<Map<String, dynamic>> recordExit(String plateNumber) async {
    try {
      final response =
          await _dio.post('/api/ocr/exit', data: {'plate_number': plateNumber});
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  // Reservations
  Future<Map<String, dynamic>> createReservation({
    required int spotId,
    String? plateNumber,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _dio.post('/api/reservations', data: {
        'spot_id': spotId,
        if (plateNumber != null) 'plate_number': plateNumber,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
      });
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  Future<List<dynamic>> getReservations({bool activeOnly = false}) async {
    try {
      final response = await _dio.get('/api/reservations',
          queryParameters: {'active_only': activeOnly});
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  Future<Map<String, dynamic>> cancelReservation(int id) async {
    try {
      final response = await _dio.patch('/api/reservations/$id/cancel');
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  Future<List<dynamic>> getReservationHistory() async {
    try {
      final response = await _dio.get('/api/reservations/history');
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  // Vehicles
  Future<List<dynamic>> getVehicles() async {
    try {
      final response = await _dio.get('/api/vehicles');
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  Future<Map<String, dynamic>> addVehicle({
    required String plateNumber,
    String? vehicleType,
    String? color,
  }) async {
    try {
      final response = await _dio.post('/api/vehicles', data: {
        'plate_number': plateNumber,
        if (vehicleType != null) 'vehicle_type': vehicleType,
        if (color != null) 'color': color,
      });
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      await _dio.delete('/api/vehicles/$id');
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }

  // Parking lot info
  Future<List<dynamic>> getParkingLots() async {
    try {
      final response = await _dio.get('/api/parking/lot');
      return response.data;
    } on DioException catch (e) {
      throw getErrorMessage(e);
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
