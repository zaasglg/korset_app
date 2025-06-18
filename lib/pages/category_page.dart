import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:korset_app/models/category.dart';
import 'package:korset_app/pages/detail.dart';

class CategoryPage extends StatefulWidget {
  final Category category;
  
  const CategoryPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  // Filter variables
  String _selectedSortOption = 'newest';
  String _selectedPriceRange = 'all';
  bool _showOnlyWithPhoto = false;
  
  // Category navigation - поддержка 2-го и 3-го уровня
  Category? _selectedSubcategory;
  Category? _selectedSubSubcategory;
  
  final List<String> _sortOptions = [
    'newest',
    'oldest', 
    'price_low',
    'price_high',
    'popular',
  ];
  
  final Map<String, String> _sortLabels = {
    'newest': 'Сначала новые',
    'oldest': 'Сначала старые',
    'price_low': 'Сначала дешевые',
    'price_high': 'Сначала дорогие',
    'popular': 'Популярные',
  };
  
  final List<String> _priceRanges = [
    'all',
    '0-50000',
    '50000-200000',
    '200000-500000',
    '500000+',
  ];
  
  final Map<String, String> _priceLabels = {
    'all': 'Любая цена',
    '0-50000': 'до 50 000 ₸',
    '50000-200000': '50 000 - 200 000 ₸',
    '200000-500000': '200 000 - 500 000 ₸',
    '500000+': 'от 500 000 ₸',
  };

  // Получить текущую активную категорию (самый глубокий выбранный уровень)
  Category get _currentCategory {
    if (_selectedSubSubcategory != null) return _selectedSubSubcategory!;
    if (_selectedSubcategory != null) return _selectedSubcategory!;
    return widget.category;
  }

  // Получить путь для breadcrumbs
  List<Category> get _breadcrumbPath {
    List<Category> path = [widget.category];
    if (_selectedSubcategory != null) {
      path.add(_selectedSubcategory!);
    }
    if (_selectedSubSubcategory != null) {
      path.add(_selectedSubSubcategory!);
    }
    return path;
  }

  // Проверить, нужно ли показывать подкатегории или товары
  bool get _shouldShowSubcategories {
    if (_selectedSubSubcategory != null) {
      return _selectedSubSubcategory!.children.isNotEmpty;
    }
    if (_selectedSubcategory != null) {
      return _selectedSubcategory!.children.isNotEmpty;
    }
    return widget.category.children.isNotEmpty;
  }

  // Получить текущие подкатегории для отображения
  List<Category> get _currentSubcategories {
    if (_selectedSubcategory != null && _selectedSubSubcategory == null) {
      return _selectedSubcategory!.children;
    }
    if (_selectedSubcategory == null) {
      return widget.category.children;
    }
    return [];
  }

  // Пример данных товаров - в реальном приложении будет из API
  List<Map<String, dynamic>> get _filteredProducts {
    // Мок данные для демонстрации
    List<Map<String, dynamic>> products = [
      {
        'id': '1',
        'title': 'Продам 3к кв в кирпичном доме',
        'price': '17 300 000 ₸',
        'location': 'Туркестан',
        'image': 'assets/images/image.webp',
        'hasPhoto': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'priceNumeric': 17300000,
        'views': 250,
      },
      {
        'id': '2',
        'title': 'Студия в новостройке',
        'price': '8 500 000 ₸',
        'location': 'Алматы',
        'image': 'assets/images/image.webp',
        'hasPhoto': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 3)),
        'priceNumeric': 8500000,
        'views': 180,
      },
      {
        'id': '3',
        'title': '2к квартира с ремонтом',
        'price': '12 000 000 ₸',
        'location': 'Шымкент',
        'image': 'assets/images/image.webp',
        'hasPhoto': true,
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
        'priceNumeric': 12000000,
        'views': 320,
      },
      {
        'id': '4',
        'title': 'Дом в пригороде',
        'price': '25 000 000 ₸',
        'location': 'Астана',
        'image': 'assets/images/image.webp',
        'hasPhoto': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 7)),
        'priceNumeric': 25000000,
        'views': 95,
      },
    ];
    
    // Применяем фильтры
    List<Map<String, dynamic>> filtered = products.where((product) {
      // Фильтр по цене
      if (_selectedPriceRange != 'all') {
        int price = product['priceNumeric'];
        switch (_selectedPriceRange) {
          case '0-50000':
            if (price > 50000) return false;
            break;
          case '50000-200000':
            if (price < 50000 || price > 200000) return false;
            break;
          case '200000-500000':
            if (price < 200000 || price > 500000) return false;
            break;
          case '500000+':
            if (price < 500000) return false;
            break;
        }
      }
      
      // Фильтр по фото
      if (_showOnlyWithPhoto && !product['hasPhoto']) return false;
      
      return true;
    }).toList();
    
    // Применяем сортировку
    switch (_selectedSortOption) {
      case 'newest':
        filtered.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
        break;
      case 'oldest':
        filtered.sort((a, b) => a['createdAt'].compareTo(b['createdAt']));
        break;
      case 'price_low':
        filtered.sort((a, b) => a['priceNumeric'].compareTo(b['priceNumeric']));
        break;
      case 'price_high':
        filtered.sort((a, b) => b['priceNumeric'].compareTo(a['priceNumeric']));
        break;
      case 'popular':
        filtered.sort((a, b) => b['views'].compareTo(a['views']));
        break;
    }
    
    return filtered;
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'Фильтры и сортировка',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              
              // Sort section
              const Text(
                'Сортировка',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...(_sortOptions.map((option) => RadioListTile<String>(
                title: Text(_sortLabels[option]!),
                value: option,
                groupValue: _selectedSortOption,
                activeColor: const Color(0xff183B4E),
                onChanged: (value) {
                  setModalState(() {
                    _selectedSortOption = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ))),
              
              const SizedBox(height: 24),
              
              // Price range section
              const Text(
                'Цена',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...(_priceRanges.map((range) => RadioListTile<String>(
                title: Text(_priceLabels[range]!),
                value: range,
                groupValue: _selectedPriceRange,
                activeColor: const Color(0xff183B4E),
                onChanged: (value) {
                  setModalState(() {
                    _selectedPriceRange = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ))),
              
              const SizedBox(height: 24),
              
              // Additional filters
              CheckboxListTile(
                title: const Text('Только с фото'),
                value: _showOnlyWithPhoto,
                activeColor: const Color(0xff183B4E),
                onChanged: (value) {
                  setModalState(() {
                    _showOnlyWithPhoto = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: 32),
              
              // Apply button
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedSortOption = 'newest';
                          _selectedPriceRange = 'all';
                          _showOnlyWithPhoto = false;
                        });
                      },
                      child: const Text(
                        'Сбросить',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Apply filters
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff183B4E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Применить',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _filteredProducts;
    final currentCategory = _currentCategory;
    final shouldShowSubcategories = _shouldShowSubcategories;
    final currentSubcategories = _currentSubcategories;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Colors.black),
          onPressed: () {
            // Обработка навигации назад через уровни категорий
            if (_selectedSubSubcategory != null) {
              setState(() {
                _selectedSubSubcategory = null;
              });
            } else if (_selectedSubcategory != null) {
              setState(() {
                _selectedSubcategory = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          currentCategory.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(IconlyBroken.search, color: Color(0xff183B4E)),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb навигация
          if (_breadcrumbPath.length > 1) _buildBreadcrumbs(),
          
          // Заголовок категории с иконкой
          _buildCategoryHeader(currentCategory, shouldShowSubcategories, currentSubcategories, filteredProducts),
          
          // Показать подкатегории или товары с фильтрами
          if (shouldShowSubcategories)
            _buildSubcategoriesView(currentSubcategories)
          else
            _buildProductsView(filteredProducts),
        ],
      ),
    );
  }

  // Построение breadcrumb навигации
  Widget _buildBreadcrumbs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _breadcrumbPath.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final isLast = index == _breadcrumbPath.length - 1;
                  
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: isLast ? null : () {
                          // Навигация назад к этому уровню
                          setState(() {
                            if (index == 0) {
                              _selectedSubcategory = null;
                              _selectedSubSubcategory = null;
                            } else if (index == 1) {
                              _selectedSubSubcategory = null;
                            }
                          });
                        },
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                            color: isLast ? const Color(0xff183B4E) : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Построение заголовка категории
  Widget _buildCategoryHeader(Category currentCategory, bool shouldShowSubcategories, 
                              List<Category> currentSubcategories, List<Map<String, dynamic>> filteredProducts) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: currentCategory.bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: currentCategory.bgColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: currentCategory.icon.startsWith('http')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        currentCategory.icon,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.category,
                            size: 28,
                            color: Colors.white,
                          );
                        },
                      ),
                    )
                  : Image.asset(
                      currentCategory.icon,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentCategory.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shouldShowSubcategories
                      ? '${currentSubcategories.length} подкатегорий'
                      : '${filteredProducts.length} объявлений',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Построение сетки подкатегорий
  Widget _buildSubcategoriesView(List<Category> subcategories) {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final subcategory = subcategories[index];
          return _buildSubcategoryCard(subcategory);
        },
      ),
    );
  }

  // Построение вида товаров с панелью фильтров
  Widget _buildProductsView(List<Map<String, dynamic>> products) {
    return Expanded(
      child: Column(
        children: [
          // Панель фильтров
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _sortLabels[_selectedSortOption]!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xff183B4E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showFiltersBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xff183B4E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          IconlyBroken.filter,
                          size: 16,
                          color: Color(0xff183B4E),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Фильтры',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xff183B4E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          
          // Сетка товаров
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Построение карточки подкатегории
  Widget _buildSubcategoryCard(Category subcategory) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedSubcategory == null) {
            // Переход с уровня 1 на уровень 2
            _selectedSubcategory = subcategory;
          } else {
            // Переход с уровня 2 на уровень 3
            _selectedSubSubcategory = subcategory;
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: subcategory.bgColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Иконка категории
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: subcategory.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: subcategory.icon.startsWith('http')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            subcategory.icon,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.category,
                                size: 24,
                                color: Colors.white,
                              );
                            },
                          ),
                        )
                      : Image.asset(
                          subcategory.icon,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Название категории
              Text(
                subcategory.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Количество подкатегорий или товаров
              Text(
                subcategory.children.isNotEmpty
                    ? '${subcategory.children.length} подкатегорий'
                    : 'Товары',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              
              // Индикатор стрелки
              const SizedBox(height: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                IconlyBroken.document,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Объявления не найдены',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить параметры поиска',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedSortOption = 'newest';
                  _selectedPriceRange = 'all';
                  _showOnlyWithPhoto = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff183B4E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Сбросить фильтры',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(
              product: {
                'image': product['image'],
                'title': product['title'],
                'location': product['location'],
                'price': product['price'],
                'description': 'Подробное описание товара будет здесь...',
                'seller': 'Продавец',
                'sellerSince': '2023',
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: product['hasPhoto']
                          ? Image.asset(
                              product['image'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),
                  ),
                  // Кнопка избранного
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        IconlyBroken.heart,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Контент
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Text(
                      product['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xff2F2D2C),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Местоположение
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product['location'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Цена
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xff183B4E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product['price'],
                        style: const TextStyle(
                          color: Color(0xff183B4E),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
