class Region {
  final int id;
  final String name;
  final String? nameEn;
  final String? nameKz;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Region({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameKz,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      nameKz: json['name_kz'],
      description: json['description'],
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
      'description': description,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Region && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
