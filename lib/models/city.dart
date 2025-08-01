import 'region.dart';

class City {
  final int id;
  final String name;
  final String? nameEn;
  final String? nameKz;
  final int regionId;
  final Region? region;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  City({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameKz,
    required this.regionId,
    this.region,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      nameKz: json['name_kz'],
      regionId: json['region_id'] ?? 0,
      region: json['region'] != null ? Region.fromJson(json['region']) : null,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'name_kz': nameKz,
      'region_id': regionId,
      'region': region?.toJson(),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper method to get region name
  String get regionName => region?.name ?? 'Unknown Region';

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
