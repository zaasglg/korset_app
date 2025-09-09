import 'package:flutter/material.dart';
import 'package:korset_app/config/api_config.dart';

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
          ? '${ApiConfig.baseUrl}/storage/${json['photo']}'
          : '', // No default icon, empty string if no photo
      bgColor: autoColor,
    );
  }
}
