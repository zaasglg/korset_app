class BookingProduct {
  final int id;
  final String name;
  final String price;
  final String address;
  final String category;
  final String city;

  BookingProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.address,
    required this.category,
    required this.city,
  });

  factory BookingProduct.fromJson(Map<String, dynamic> json) {
    return BookingProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      address: json['address'] ?? '',
      category: json['category'] ?? '',
      city: json['city'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'address': address,
      'category': category,
      'city': city,
    };
  }
}

class BookingUser {
  final int id;
  final String name;
  final String phoneNumber;

  BookingUser({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  factory BookingUser.fromJson(Map<String, dynamic> json) {
    return BookingUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
    };
  }
}

class BookingDetail {
  final int id;
  final BookingProduct product;
  final BookingUser user;
  final String status;
  final String statusName;
  final String commissionAmount;
  final String paymentReference;
  final DateTime bookedAt;
  final DateTime expiresAt;
  final String notes;
  final DateTime createdAt;

  BookingDetail({
    required this.id,
    required this.product,
    required this.user,
    required this.status,
    required this.statusName,
    required this.commissionAmount,
    required this.paymentReference,
    required this.bookedAt,
    required this.expiresAt,
    required this.notes,
    required this.createdAt,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    return BookingDetail(
      id: json['id'] ?? 0,
      product: BookingProduct.fromJson(json['product'] ?? {}),
      user: BookingUser.fromJson(json['user'] ?? {}),
      status: json['status'] ?? '',
      statusName: json['status_name'] ?? '',
      commissionAmount: json['commission_amount'] ?? '',
      paymentReference: json['payment_reference'] ?? '',
      bookedAt:
          DateTime.parse(json['booked_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(
          json['expires_at'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'user': user.toJson(),
      'status': status,
      'status_name': statusName,
      'commission_amount': commissionAmount,
      'payment_reference': paymentReference,
      'booked_at': bookedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
