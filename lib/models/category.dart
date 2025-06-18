import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final String? description;
  final String? photo;
  final int? parentId;
  final String? createdAt;
  final String? updatedAt;
  final List<Category> children;
  final String icon;
  final Color bgColor;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.photo,
    this.parentId,
    this.createdAt,
    this.updatedAt,
    this.children = const [],
    required this.icon,
    required this.bgColor,
  });

  // For UI compatibility, we'll keep the label getter
  String get label => name;

  factory Category.fromJson(Map<String, dynamic> json) {
    // Get category name
    String categoryName = json['name'] ?? '';

    // Determine default icon based on category name (only used if photo is null)
    String defaultIconPath = 'assets/icons/default.png';

    // Map category names to appropriate icons for fallback
    if (categoryName.toLowerCase().contains('недвиж') ||
        categoryName.toLowerCase().contains('квартир') ||
        categoryName.toLowerCase().contains('аренд')) {
      defaultIconPath = 'assets/icons/house.png';
    } else if (categoryName.toLowerCase().contains('транспорт')) {
      defaultIconPath = 'assets/icons/car.png';
    } else if (categoryName.toLowerCase().contains('услуг')) {
      defaultIconPath = 'assets/icons/service.png';
    } else if (categoryName.toLowerCase().contains('бизнес')) {
      defaultIconPath = 'assets/icons/business.png';
    } else if (categoryName.toLowerCase().contains('дет')) {
      defaultIconPath = 'assets/icons/toys.png';
    } else if (categoryName.toLowerCase().contains('электрон')) {
      defaultIconPath = 'assets/icons/electronics.png';
    } else if (categoryName.toLowerCase().contains('мод') ||
        categoryName.toLowerCase().contains('стил')) {
      defaultIconPath = 'assets/icons/fashion.png';
    } else if (categoryName.toLowerCase().contains('красот') ||
        categoryName.toLowerCase().contains('здоров')) {
      defaultIconPath = 'assets/icons/beauty.png';
    } else if (categoryName.toLowerCase().contains('спорт') ||
        categoryName.toLowerCase().contains('отдых')) {
      defaultIconPath = 'assets/icons/sport.png';
    } else if (categoryName.toLowerCase().contains('дом') ||
        categoryName.toLowerCase().contains('дач')) {
      defaultIconPath = 'assets/icons/dacha.png';
    }

    // Generate a color automatically based on the category id or name
    Color autoColor;

    // If we have an ID, use it to generate a consistent color
    if (json['id'] != null) {
      // Use the id to generate a hue value between 0 and 360
      final int id = json['id'];
      final double hue = (id * 137.5) % 360.0;

      // Create pastel colors with high saturation and lightness
      autoColor = HSLColor.fromAHSL(1.0, hue, 0.7, 0.85).toColor();
    } else {
      // If no ID, use the name's hash code
      final int nameHash = categoryName.hashCode.abs();
      final double hue = (nameHash % 360).toDouble();
      autoColor = HSLColor.fromAHSL(1.0, hue, 0.7, 0.85).toColor();
    }

    // Parse children categories if they exist
    List<Category> childrenList = [];
    if (json['children'] != null && json['children'] is List) {
      childrenList = (json['children'] as List)
          .map((childJson) => Category.fromJson(childJson))
          .toList();
    }

    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      description: json['description'],
      photo: json['photo'],
      parentId: json['parent_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      children: childrenList,
      icon: json['photo'] != null
          ? 'http://127.0.0.1:8000/storage/${json['photo']}'
          : defaultIconPath,
      bgColor: autoColor,
    );
  }
}
