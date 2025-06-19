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

class Parameter {
  final int id;
  final int categoryId;
  final String name;
  final String type; // "text", "number", "select", "checkbox"
  final List<ParameterOption>? options;
  final bool isRequired;
  final String? createdAt;
  final String? updatedAt;
  String? value; // User's input value

  Parameter({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.type,
    this.options,
    required this.isRequired,
    this.createdAt,
    this.updatedAt,
    this.value,
  });

  factory Parameter.fromJson(Map<String, dynamic> json) {
    List<ParameterOption>? optionsList;
    
    if (json['options'] != null) {
      optionsList = (json['options'] as List)
          .map((option) => ParameterOption.fromJson(option))
          .toList();
    }

    return Parameter(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      type: json['type'],
      options: optionsList,
      isRequired: json['is_required'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}