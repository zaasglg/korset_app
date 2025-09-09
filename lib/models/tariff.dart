class Tariff {
  final int id;
  final String name;
  final String price;
  final String? discountPrice;
  final String description;
  final Map<String, dynamic> features;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tariff({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice,
    required this.description,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tariff.fromJson(Map<String, dynamic> json) {
    return Tariff(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '0.00',
      discountPrice: json['discount_price'],
      description: json['description'] ?? '',
      features: json['features'] ?? {},
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'discount_price': discountPrice,
      'description': description,
      'features': features,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Вспомогательные методы
  double get priceAsDouble {
    return double.tryParse(price) ?? 0.0;
  }

  double? get discountPriceAsDouble {
    return discountPrice != null ? double.tryParse(discountPrice!) : null;
  }

  double get effectivePrice {
    return discountPriceAsDouble ?? priceAsDouble;
  }

  bool get hasDiscount {
    return discountPrice != null && discountPriceAsDouble! < priceAsDouble;
  }

  List<String> get featuresList {
    return features.values.map((value) => value.toString()).toList();
  }
}
