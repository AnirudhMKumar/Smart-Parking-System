import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parking_spot.dart';
import '../models/reservation.dart';
import '../services/api_service.dart';

final parkingStatsProvider = FutureProvider<ParkingStats>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getParkingStats();
  return ParkingStats.fromJson(data);
});

final spotsProvider = FutureProvider<List<ParkingSpot>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getSpots();
  return data.map((json) => ParkingSpot.fromJson(json)).toList();
});

final availableSpotsProvider = FutureProvider<List<ParkingSpot>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getAvailableSpots();
  return data.map((json) => ParkingSpot.fromJson(json)).toList();
});

final reservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getReservations();
  return data.map((json) => Reservation.fromJson(json)).toList();
});

final reservationHistoryProvider = FutureProvider<List<Reservation>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getReservationHistory();
  return data.map((json) => Reservation.fromJson(json)).toList();
});
