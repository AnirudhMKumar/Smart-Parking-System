class ParkingSpot {
  final int id;
  final int lotId;
  final String spotNumber;
  final String spotType;
  final String status;
  final int floor;
  final String? section;

  ParkingSpot({
    required this.id,
    required this.lotId,
    required this.spotNumber,
    required this.spotType,
    required this.status,
    required this.floor,
    this.section,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'],
      lotId: json['lot_id'],
      spotNumber: json['spot_number'],
      spotType: json['spot_type'],
      status: json['status'],
      floor: json['floor'],
      section: json['section'],
    );
  }

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';
}

class ParkingStats {
  final int totalSpots;
  final int available;
  final int occupied;
  final int reserved;
  final int maintenance;

  ParkingStats({
    required this.totalSpots,
    required this.available,
    required this.occupied,
    required this.reserved,
    required this.maintenance,
  });

  factory ParkingStats.fromJson(Map<String, dynamic> json) {
    return ParkingStats(
      totalSpots: json['total_spots'],
      available: json['available'],
      occupied: json['occupied'],
      reserved: json['reserved'],
      maintenance: json['maintenance'],
    );
  }

  double get occupancyRate => totalSpots > 0 ? occupied / totalSpots : 0;
}
