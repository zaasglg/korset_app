class BookingCommission {
  final int id;
  final String type;
  final String typeName;
  final String name;
  final String description;
  final String price;
  final String formattedPrice;
  final int durationHours;
  final String durationText;
  final List<dynamic> features;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingCommission({
    required this.id,
    required this.type,
    required this.typeName,
    required this.name,
    required this.description,
    required this.price,
    required this.formattedPrice,
    required this.durationHours,
    required this.durationText,
    required this.features,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingCommission.fromJson(Map<String, dynamic> json) {
    return BookingCommission(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      typeName: json['type_name'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '',
      formattedPrice: json['formatted_price'] ?? '',
      durationHours: json['duration_hours'] ?? 0,
      durationText: json['duration_text'] ?? '',
      features: json['features'] ?? [],
      isActive: json['is_active'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'type_name': typeName,
      'name': name,
      'description': description,
      'price': price,
      'formatted_price': formattedPrice,
      'duration_hours': durationHours,
      'duration_text': durationText,
      'features': features,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
