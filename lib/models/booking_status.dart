class ActiveBooking {
  final int id;
  final int userId;
  final String userName;
  final String status;
  final String statusName;
  final DateTime bookedAt;
  final DateTime expiresAt;

  ActiveBooking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.status,
    required this.statusName,
    required this.bookedAt,
    required this.expiresAt,
  });

  factory ActiveBooking.fromJson(Map<String, dynamic> json) {
    return ActiveBooking(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      status: json['status'] ?? '',
      statusName: json['status_name'] ?? '',
      bookedAt:
          DateTime.parse(json['booked_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(
          json['expires_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'status': status,
      'status_name': statusName,
      'booked_at': bookedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

class BookingStatus {
  final int productId;
  final bool isBookable;
  final String bookingStatus;
  final ActiveBooking? activeBooking;

  BookingStatus({
    required this.productId,
    required this.isBookable,
    required this.bookingStatus,
    this.activeBooking,
  });

  factory BookingStatus.fromJson(Map<String, dynamic> json) {
    return BookingStatus(
      productId: json['product_id'] ?? 0,
      isBookable: json['is_bookable'] ?? false,
      bookingStatus: json['booking_status'] ?? '',
      activeBooking: json['active_booking'] != null
          ? ActiveBooking.fromJson(json['active_booking'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'is_bookable': isBookable,
      'booking_status': bookingStatus,
      'active_booking': activeBooking?.toJson(),
    };
  }
}
