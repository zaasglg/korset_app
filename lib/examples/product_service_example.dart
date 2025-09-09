import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product_filters.dart';
import '../models/product.dart';

/// Пример использования ProductService с фильтрацией по категориям
class ProductServiceExample {
  final ProductService _productService = ProductService();

  /// Пример 1: Получить продукты конкретной категории
  Future<void> getProductsFromCategory(int categoryId) async {
    try {
      print('--- Получение продуктов категории $categoryId ---');
      
      final products = await _productService.getProductsByCategory(
        categoryId: categoryId,
        limit: 10,
        sortBy: ProductSortOptions.dateDesc,
      );
      
      print('Найдено ${products.length} продуктов');
      for (final product in products) {
        print('- ${product.name}: ${product.price}');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  /// Пример 2: Получить продукты из нескольких категорий
  Future<void> getProductsFromMultipleCategories(List<int> categoryIds) async {
    try {
      print('--- Получение продуктов категорий $categoryIds ---');
      
      final products = await _productService.getProductsByCategories(
        categoryIds: categoryIds,
        limit: 20,
        sortBy: ProductSortOptions.priceAsc,
      );
      
      print('Найдено ${products.length} продуктов');
      for (final product in products) {
        print('- ${product.name}: ${product.price}');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  /// Пример 3: Использование ProductFilters для сложной фильтрации
  Future<void> advancedFilteringExample() async {
    try {
      print('--- Продвинутая фильтрация ---');
      
      // Создаем объект фильтров
      final filters = ProductFilters();
      
      // Добавляем категории
      filters.addCategory(1); // Электроника
      filters.addCategory(2); // Автомобили
      
      // Устанавливаем ценовой диапазон
      filters.minPrice = 10000;
      filters.maxPrice = 500000;
      
      // Устанавливаем сортировку
      filters.sortBy = ProductSortOptions.popularityDesc;
      
      // Поиск по ключевому слову
      filters.search = 'iPhone';
      
      print('Активные фильтры: ${filters.activeFiltersCount}');
      print('Фильтры: $filters');
      
      // Получаем продукты с фильтрами
      final products = await _productService.getProductsWithFilters(
        filters: filters,
        page: 1,
        limit: 15,
      );
      
      print('Найдено ${products.length} продуктов с фильтрами');
      for (final product in products) {
        print('- ${product.name}: ${product.price}');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  /// Пример 4: Поиск с продвинутыми фильтрами
  Future<void> advancedSearchExample() async {
    try {
      print('--- Продвинутый поиск ---');
      
      final products = await _productService.searchProductsAdvanced(
        query: 'смартфон',
        categoryIds: [1, 5], // Электроника и Гаджеты
        minPrice: 50000,
        maxPrice: 200000,
        sortBy: ProductSortOptions.priceAsc,
        filters: {
          'brand': 'Apple',
          'condition': 'new',
          'has_warranty': 'true',
        },
      );
      
      print('Найдено ${products.length} продуктов по запросу');
      for (final product in products) {
        print('- ${product.name}: ${product.price}');
      }
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  /// Пример 5: Получение статистики по категориям
  Future<void> getCategoryStatsExample() async {
    try {
      print('--- Статистика категорий ---');
      
      final stats = await _productService.getCategoryStatistics();
      print('Статистика: $stats');
      
      // Получаем количество продуктов в конкретной категории
      final count = await _productService.getProductsCountByCategory(1);
      print('Продуктов в категории 1: $count');
      
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  /// Демонстрация всех примеров
  Future<void> runAllExamples() async {
    await getProductsFromCategory(1);
    await getProductsFromMultipleCategories([1, 2, 3]);
    await advancedFilteringExample();
    await advancedSearchExample();
    await getCategoryStatsExample();
  }
}

/// Widget для демонстрации работы с категориями
class CategoryProductsDemo extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsDemo({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<CategoryProductsDemo> createState() => _CategoryProductsDemoState();
}

class _CategoryProductsDemoState extends State<CategoryProductsDemo> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String _selectedSort = ProductSortOptions.dateDesc;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getProductsByCategory(
        categoryId: widget.categoryId,
        sortBy: _selectedSort,
        limit: 20,
      );

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Ошибка загрузки продуктов: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _selectedSort = value;
              });
              _loadProducts();
            },
            itemBuilder: (BuildContext context) {
              return ProductSortOptions.allOptions.map((String option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Text(ProductSortOptions.getDisplayName(option)),
                );
              }).toList();
            },
            child: const Icon(Icons.sort),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Продукты не найдены'))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text('${product.price} ₸'),
                      leading: const Icon(Icons.shopping_bag),
                      onTap: () {
                        // Переход к детальной странице продукта
                      },
                    );
                  },
                ),
    );
  }
}
