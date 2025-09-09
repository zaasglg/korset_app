class ProductFilters {
  List<int>? categoryIds;
  int? cityId;
  double? minPrice;
  double? maxPrice;
  String? search;
  String? sortBy;
  Map<String, dynamic>? customFilters;
  String? priceRange;
  bool? hasPhoto;
  String? subcategory;
  String? subSubcategory;

  ProductFilters({
    this.categoryIds,
    this.cityId,
    this.minPrice,
    this.maxPrice,
    this.search,
    this.sortBy,
    this.customFilters,
    this.priceRange,
    this.hasPhoto,
    this.subcategory,
    this.subSubcategory,
  });

  /// Добавить категорию в фильтр
  void addCategory(int categoryId) {
    categoryIds ??= [];
    if (!categoryIds!.contains(categoryId)) {
      categoryIds!.add(categoryId);
    }
  }

  /// Удалить категорию из фильтра
  void removeCategory(int categoryId) {
    categoryIds?.remove(categoryId);
    if (categoryIds?.isEmpty == true) {
      categoryIds = null;
    }
  }

  /// Очистить все фильтры
  void clear() {
    categoryIds = null;
    cityId = null;
    minPrice = null;
    maxPrice = null;
    search = null;
    sortBy = null;
    customFilters = null;
  }

  /// Проверить, активны ли фильтры
  bool get hasActiveFilters {
    return categoryIds?.isNotEmpty == true ||
           cityId != null ||
           minPrice != null ||
           maxPrice != null ||
           search?.isNotEmpty == true ||
           customFilters?.isNotEmpty == true ||
           priceRange?.isNotEmpty == true ||
           hasPhoto != null ||
           subcategory?.isNotEmpty == true ||
           subSubcategory?.isNotEmpty == true;
  }

  /// Получить количество активных фильтров
  int get activeFiltersCount {
    int count = 0;
    if (categoryIds?.isNotEmpty == true) count++;
    if (cityId != null) count++;
    if (minPrice != null) count++;
    if (maxPrice != null) count++;
    if (search?.isNotEmpty == true) count++;
    if (customFilters?.isNotEmpty == true) count += customFilters!.length;
    if (priceRange?.isNotEmpty == true) count++;
    if (hasPhoto != null) count++;
    if (subcategory?.isNotEmpty == true) count++;
    if (subSubcategory?.isNotEmpty == true) count++;
    return count;
  }

  /// Конвертировать в Map для API запроса
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {};
    
    if (categoryIds?.isNotEmpty == true) {
      map['category_ids'] = categoryIds!.join(',');
    }
    if (cityId != null) map['city_id'] = cityId;
    if (minPrice != null) map['min_price'] = minPrice;
    if (maxPrice != null) map['max_price'] = maxPrice;
    if (search?.isNotEmpty == true) map['search'] = search;
    if (sortBy?.isNotEmpty == true) map['sort_by'] = sortBy;
    if (priceRange?.isNotEmpty == true) map['price_range'] = priceRange;
    if (hasPhoto != null) map['has_photo'] = hasPhoto;
    if (subcategory?.isNotEmpty == true) map['subcategory'] = subcategory;
    if (subSubcategory?.isNotEmpty == true) map['sub_subcategory'] = subSubcategory;
    
    // Добавляем кастомные фильтры
    if (customFilters?.isNotEmpty == true) {
      map.addAll(customFilters!);
    }
    
    return map;
  }

  /// Создать копию фильтров
  ProductFilters copy() {
    return ProductFilters(
      categoryIds: categoryIds?.toList(),
      cityId: cityId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      search: search,
      sortBy: sortBy,
      customFilters: customFilters != null ? Map.from(customFilters!) : null,
      priceRange: priceRange,
      hasPhoto: hasPhoto,
      subcategory: subcategory,
      subSubcategory: subSubcategory,
    );
  }

  @override
  String toString() {
    return 'ProductFilters{categoryIds: $categoryIds, cityId: $cityId, minPrice: $minPrice, maxPrice: $maxPrice, search: $search, sortBy: $sortBy, customFilters: $customFilters, priceRange: $priceRange, hasPhoto: $hasPhoto, subcategory: $subcategory, subSubcategory: $subSubcategory}';
  }
}

/// Константы для сортировки
class ProductSortOptions {
  static const String priceAsc = 'price_asc';
  static const String priceDesc = 'price_desc';
  static const String dateAsc = 'date_asc';
  static const String dateDesc = 'date_desc';
  static const String popularityDesc = 'popularity_desc';
  static const String titleAsc = 'title_asc';
  static const String titleDesc = 'title_desc';

  static const List<String> allOptions = [
    priceAsc,
    priceDesc,
    dateAsc,
    dateDesc,
    popularityDesc,
    titleAsc,
    titleDesc,
  ];

  static String getDisplayName(String sortBy) {
    switch (sortBy) {
      case priceAsc:
        return 'Цена: по возрастанию';
      case priceDesc:
        return 'Цена: по убыванию';
      case dateAsc:
        return 'Дата: сначала старые';
      case dateDesc:
        return 'Дата: сначала новые';
      case popularityDesc:
        return 'По популярности';
      case titleAsc:
        return 'Название: А-Я';
      case titleDesc:
        return 'Название: Я-А';
      default:
        return 'Сортировка';
    }
  }
}
