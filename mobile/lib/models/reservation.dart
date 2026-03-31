class Reservation {
  final int id;
  final int userId;
  final int spotId;
  final String? plateNumber;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? actualEntryTime;
  final DateTime? actualExitTime;
  final double? totalAmount;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.userId,
    required this.spotId,
    this.plateNumber,
    required this.status,
    required this.startTime,
    required this.endTime,
    this.actualEntryTime,
    this.actualExitTime,
    this.totalAmount,
    required this.createdAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      userId: json['user_id'],
      spotId: json['spot_id'],
      plateNumber: json['plate_number'],
      status: json['status'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      actualEntryTime: json['actual_entry_time'] != null ? DateTime.parse(json['actual_entry_time']) : null,
      actualExitTime: json['actual_exit_time'] != null ? DateTime.parse(json['actual_exit_time']) : null,
      totalAmount: json['total_amount']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
}
