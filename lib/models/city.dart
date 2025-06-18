class City {
  final int id;
  final String name;
  final String? nameEn;
  final String? nameKz;
  final String? region;
  final bool isActive;

  City({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameKz,
    this.region,
    this.isActive = true,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      nameKz: json['name_kz'],
      region: json['region'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'name_kz': nameKz,
      'region': region,
      'is_active': isActive,
    };
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
