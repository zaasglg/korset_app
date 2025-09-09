class PublicationPrice {
  final int id;
  final String name;
  final String description;
  final String price;
  final String formattedPrice;
  final int durationHours;
  final String durationText;
  final Map<String, dynamic>? features;

  PublicationPrice({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.formattedPrice,
    required this.durationHours,
    required this.durationText,
    this.features,
  });

  factory PublicationPrice.fromJson(Map<String, dynamic> json) {
    return PublicationPrice(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '0.00',
      formattedPrice: json['formatted_price'] ?? '0.00 KZT',
      durationHours: json['duration_hours'] ?? 0,
      durationText: json['duration_text'] ?? '',
      features: json['features'] != null
          ? Map<String, dynamic>.from(json['features'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'formatted_price': formattedPrice,
      'duration_hours': durationHours,
      'duration_text': durationText,
      'features': features,
    };
  }

  double get priceValue {
    return double.tryParse(price) ?? 0.0;
  }

  bool get isFree {
    return priceValue == 0.0;
  }
}
