class Booking {
  final int productId;
  final String notes;

  Booking({
    required this.productId,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'notes': notes,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      productId: json['product_id'] ?? 0,
      notes: json['notes'] ?? '',
    );
  }
}
