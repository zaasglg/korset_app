import 'package:korset_app/models/category.dart';
import 'package:korset_app/models/city.dart';

class PublicationPrice {
  final String name;
  final String typeName;

  PublicationPrice({
    required this.name,
    required this.typeName,
  });

  factory PublicationPrice.fromJson(Map<String, dynamic> json) {
    return PublicationPrice(
      name: json['name'] ?? '',
      typeName: json['type_name'] ?? '',
    );
  }
}

class ProductParameterValue {
  final int id;
  final int productId;
  final int productParameterId;
  final String value;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProductParameter parameter;

  ProductParameterValue({
    required this.id,
    required this.productId,
    required this.productParameterId,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
    required this.parameter,
  });

  factory ProductParameterValue.fromJson(Map<String, dynamic> json) {
    return ProductParameterValue(
      id: json['id'],
      productId: json['product_id'],
      productParameterId: json['product_parameter_id'],
      value: json['value'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      parameter: ProductParameter.fromJson(json['parameter']),
    );
  }
}

class ProductParameter {
  final int id;
  final int categoryId;
  final String name;
  final String type;
  final List<ParameterOption>? options;
  final bool isRequired;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductParameter({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.type,
    this.options,
    required this.isRequired,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductParameter.fromJson(Map<String, dynamic> json) {
    List<ParameterOption>? options;
    if (json['options'] != null) {
      options = (json['options'] as List)
          .map((option) => ParameterOption.fromJson(option))
          .toList();
    }

    return ProductParameter(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      type: json['type'],
      options: options,
      isRequired: json['is_required'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class ParameterOption {
  final String label;
  final String value;

  ParameterOption({
    required this.label,
    required this.value,
  });

  factory ParameterOption.fromJson(Map<String, dynamic> json) {
    return ParameterOption(
      label: json['label'],
      value: json['value'],
    );
  }
}

class Product {
  final int id;
  final int? userId; // Made optional since it's not in new API
  final int? categoryId; // Made optional, will get from category.id
  final int? cityId; // Made optional, will get from city.id
  final String name;
  final String slug;
  final String description;
  final String? mainPhoto;
  final String? video;
  final String price;
  final String address;
  final bool isVideoCallAvailable;
  final DateTime expiresAt;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt; // Made optional since it's not in new API
  final String? videoUrl;
  final String? whatsappNumber;
  final String? phoneNumber;
  final bool readyForVideoDemo;
  final int viewsCount;
  final bool isPromoted; // New field from API
  final Category category;
  final City city;
  final List<ProductParameterValue> parameterValues;
  final PublicationPrice? publicationPrice; // New field from API

  Product({
    required this.id,
    this.userId,
    this.categoryId,
    this.cityId,
    required this.name,
    required this.slug,
    required this.description,
    this.mainPhoto,
    this.video,
    required this.price,
    required this.address,
    this.isVideoCallAvailable = false,
    required this.expiresAt,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
    this.videoUrl,
    this.whatsappNumber,
    this.phoneNumber,
    this.readyForVideoDemo = false,
    this.viewsCount = 0,
    this.isPromoted = false,
    required this.category,
    required this.city,
    this.parameterValues = const [],
    this.publicationPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      userId: json['user_id'], // May be null in new API
      categoryId: json['category_id'], // May be null, will get from category
      cityId: json['city_id'], // May be null, will get from city
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      mainPhoto: json['main_photo'] == 'null' || json['main_photo'] == ''
          ? null
          : json['main_photo'],
      video: json['video'],
      price: json['price'],
      address: json['address'],
      isVideoCallAvailable: json['is_video_call_available'] ?? false,
      expiresAt: DateTime.parse(json['expires_at']),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      videoUrl: json['video_url'],
      whatsappNumber: json['whatsapp_number'],
      phoneNumber: json['phone_number'],
      readyForVideoDemo: json['ready_for_video_demo'] ?? false,
      viewsCount: json['views_count'] ?? 0,
      isPromoted: json['is_promoted'] ?? false,
      category: Category.fromJson(json['category']),
      city: City.fromJson(json['city']),
      parameterValues: json['parameter_values'] != null
          ? (json['parameter_values'] as List)
              .map((param) => ProductParameterValue.fromJson(param))
              .toList()
          : [],
      publicationPrice: json['publication_price'] != null
          ? PublicationPrice.fromJson(json['publication_price'])
          : null,
    );
  }

  // Форматированная цена с валютой
  String get formattedPrice {
    final priceDouble = double.tryParse(price) ?? 0.0;
    final formatter = priceDouble >= 1000000
        ? '${(priceDouble / 1000000).toStringAsFixed(1)} млн'
        : priceDouble >= 1000
            ? '${(priceDouble / 1000).toStringAsFixed(0)} тыс'
            : priceDouble.toStringAsFixed(0);
    return '$formatter ₸';
  }

  // Get effective category ID
  int get effectiveCategoryId => categoryId ?? category.id;

  // Get effective city ID
  int get effectiveCityId => cityId ?? city.id;

  // Получить изображение для отображения
  String get displayImage {
    if (mainPhoto != null && mainPhoto!.isNotEmpty && mainPhoto != 'null') {
      return mainPhoto!;
    }
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      return videoUrl!;
    }
    return 'assets/images/image.webp'; // fallback
  }

  // Получить параметр по имени
  String? getParameterValue(String parameterName) {
    for (var paramValue in parameterValues) {
      if (paramValue.parameter.name == parameterName) {
        return paramValue.value;
      }
    }
    return null;
  }

  // Convert Product to JSON/Map for compatibility with existing UI code
  Map<String, dynamic> toJson() {
    // Parse price to numeric value for sorting
    final priceNumeric = double.tryParse(price)?.toInt() ?? 0;

    return {
      'id': id,
      'title': name,
      'price': formattedPrice,
      'priceNumeric': priceNumeric,
      'location': '${city.name}, $address',
      'image': displayImage,
      'hasPhoto':
          mainPhoto != null && mainPhoto!.isNotEmpty && mainPhoto != 'null',
      'createdAt': createdAt,
      'views': viewsCount,
      'description': description,
      'category': category.name,
      'city': city.name,
      'address': address,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'videoUrl': videoUrl,
      'isVideoCallAvailable': isVideoCallAvailable,
      'readyForVideoDemo': readyForVideoDemo,
      'status': status,
      'expiresAt': expiresAt.toIso8601String(),
      'isPromoted': isPromoted,
      'publicationPrice': publicationPrice?.name,
      'parameterValues': parameterValues
          .map((pv) => {
                'id': pv.id,
                'value': pv.value,
                'parameter': {
                  'id': pv.parameter.id,
                  'name': pv.parameter.name,
                  'type': pv.parameter.type,
                }
              })
          .toList(),
    };
  }
}
