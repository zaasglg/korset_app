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
  String _selectedSubcategoryFilter = 'all'; // Фильтр по подкатегориям 2-го уровня
  String _selectedSubSubcategoryFilter = 'all'; // Фильтр по подкатегориям 3-го уровня
  
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

  // Получить список подкатегорий для фильтра
  List<String> get _subcategoryOptions {
    List<String> options = ['all'];
    if (widget.category.children.isNotEmpty) {
      options.addAll(widget.category.children.map((cat) => cat.name));
    }
    return options;
  }

  Map<String, String> get _subcategoryLabels {
    Map<String, String> labels = {'all': 'Все подкатегории'};
    for (var category in widget.category.children) {
      labels[category.name] = category.name;
    }
    return labels;
  }

  // Получить список подкатегорий 3-го уровня для фильтра
  List<String> get _subSubcategoryOptions {
    List<String> options = ['all'];
    if (_selectedSubcategoryFilter != 'all') {
      final selectedSubcat = widget.category.children.firstWhere(
        (cat) => cat.name == _selectedSubcategoryFilter,
        orElse: () => widget.category.children.first,
      );
      if (selectedSubcat.children.isNotEmpty) {
        options.addAll(selectedSubcat.children.map((cat) => cat.name));
      }
    }
    return options;
  }

  Map<String, String> get _subSubcategoryLabels {
    Map<String, String> labels = {'all': 'Все подкатегории'};
    if (_selectedSubcategoryFilter != 'all') {
      final selectedSubcat = widget.category.children.firstWhere(
        (cat) => cat.name == _selectedSubcategoryFilter,
        orElse: () => widget.category.children.first,
      );
      for (var category in selectedSubcat.children) {
        labels[category.name] = category.name;
      }
    }
    return labels;
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final products = _getMockProducts();
    List<Map<String, dynamic>> filtered = products;

    // Фильтр по подкатегории 2-го уровня
    if (_selectedSubcategoryFilter != 'all') {
      filtered = filtered.where((product) => 
        product['subcategory'] == _selectedSubcategoryFilter).toList();
    }

    // Фильтр по подкатегории 3-го уровня
    if (_selectedSubSubcategoryFilter != 'all') {
      filtered = filtered.where((product) => 
        product['subSubcategory'] == _selectedSubSubcategoryFilter).toList();
    }

    // Фильтр по цене
    if (_selectedPriceRange != 'all') {
      filtered = filtered.where((product) {
        int price = product['priceNumeric'] ?? 0;
        switch (_selectedPriceRange) {
          case '0-50000':
            return price <= 50000;
          case '50000-200000':
            return price > 50000 && price <= 200000;
          case '200000-500000':
            return price > 200000 && price <= 500000;
          case '500000+':
            return price > 500000;
          default:
            return true;
        }
      }).toList();
    }

    // Фильтр по наличию фото
    if (_showOnlyWithPhoto) {
      filtered = filtered.where((product) => product['hasPhoto'] == true).toList();
    }

    // Сортировка
    filtered.sort((a, b) {
      switch (_selectedSortOption) {
        case 'newest':
          return (b['createdAt'] as DateTime? ?? DateTime.now())
              .compareTo(a['createdAt'] as DateTime? ?? DateTime.now());
        case 'oldest':
          return (a['createdAt'] as DateTime? ?? DateTime.now())
              .compareTo(b['createdAt'] as DateTime? ?? DateTime.now());
        case 'price_low':
          return (a['priceNumeric'] as int? ?? 0)
              .compareTo(b['priceNumeric'] as int? ?? 0);
        case 'price_high':
          return (b['priceNumeric'] as int? ?? 0)
              .compareTo(a['priceNumeric'] as int? ?? 0);
        case 'popular':
          return (b['views'] as int? ?? 0)
              .compareTo(a['views'] as int? ?? 0);
        default:
          return 0;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Color(0xff183B4E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.name,
          style: const TextStyle(
            color: Color(0xff183B4E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(IconlyBroken.filter, color: Color(0xff183B4E)),
            onPressed: () => _showFiltersBottomSheet(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Заголовок категории
          _buildCategoryHeader(),
          
          // Фильтры сверху
          _buildTopFilters(),
          
          // Список товаров
          Expanded(
            child: _buildProductsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: widget.category.bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.category.bgColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: widget.category.icon.startsWith('http')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.category.icon,
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
                      widget.category.icon,
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
                  widget.category.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_filteredProducts.length} объявлений',
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

  Widget _buildTopFilters() {
    if (widget.category.children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Подкатегории 2-го уровня
          if (_subcategoryOptions.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xff183B4E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Категории',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _subcategoryOptions.length,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  final option = _subcategoryOptions[index];
                  final isSelected = _selectedSubcategoryFilter == option;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSubcategoryFilter = option;
                        _selectedSubSubcategoryFilter = 'all'; // Сбросить 3-й уровень
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xff183B4E) : Colors.white,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: isSelected ? const Color(0xff183B4E) : Colors.grey.shade200,
                          width: 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xff183B4E).withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Text(
                        _subcategoryLabels[option] ?? option,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF6D6D6D),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Подкатегории 3-го уровня
          if (_selectedSubcategoryFilter != 'all' && _subSubcategoryOptions.length > 1) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xff183B4E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Типы',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _subSubcategoryOptions.length,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  final option = _subSubcategoryOptions[index];
                  final isSelected = _selectedSubSubcategoryFilter == option;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSubSubcategoryFilter = option;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xff183B4E) : Colors.white,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: isSelected ? const Color(0xff183B4E) : Colors.grey.shade200,
                          width: 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xff183B4E).withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Text(
                        _subSubcategoryLabels[option] ?? option,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF6D6D6D),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xff183B4E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? const Color(0xff183B4E) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    final products = _filteredProducts;
    
    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
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
    );
  }

  List<Map<String, dynamic>> _getMockProducts() {
    return [
      {
        'id': '1',
        'title': 'Продам 3к кв в кирпичном доме',
        'price': '17 300 000 ₸',
        'location': 'Туркестан',
        'image': 'assets/images/image.webp',
        'hasPhoto': true,
        'subcategory': 'Квартиры',
        'subSubcategory': 'Вторичка',
        'priceNumeric': 17300000,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'views': 120,
      },
      {
        'id': '2',
        'title': 'Студия в новостройке',
        'price': '8 500 000 ₸',
        'location': 'Алматы',
        'image': 'assets/images/image.webp',
        'hasPhoto': true,
        'subcategory': 'Квартиры',
        'subSubcategory': 'Новостройка',
        'priceNumeric': 8500000,
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
        'views': 95,
      },
      {
        'id': '3',
        'title': '2к квартира с ремонтом',
        'price': '12 000 000 ₸',
        'location': 'Шымкент',
        'image': 'assets/images/image.webp',
        'hasPhoto': true,
        'subcategory': 'Квартиры',
        'subSubcategory': 'Вторичка',
        'priceNumeric': 12000000,
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'views': 110,
      },
      {
        'id': '4',
        'title': 'Дом в пригороде',
        'price': '25 000 000 ₸',
        'location': 'Астана',
        'image': 'assets/images/image.webp',
        'hasPhoto': false,
        'subcategory': 'Дома',
        'subSubcategory': 'Пригород',
        'priceNumeric': 25000000,
        'createdAt': DateTime.now().subtract(const Duration(days: 30)),
        'views': 80,
      },
    ];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
                IconlyBroken.search,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ничего не найдено',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить параметры поиска',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
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
            builder: (context) => DetailPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: product['hasPhoto'] 
                        ? Image.asset(
                            product['image'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
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
                  // Favorite button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        IconlyBroken.heart,
                        size: 16,
                        color: Color(0xff183B4E),
                      ),
                    ),
                  ),
                  // Price badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xff183B4E),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        product['price'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      product['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xff1A1A1A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product['location'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Фильтры',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedSortOption = 'newest';
                        _selectedPriceRange = 'all';
                        _showOnlyWithPhoto = false;
                        _selectedSubcategoryFilter = 'all';
                        _selectedSubSubcategoryFilter = 'all';
                      });
                      setState(() {
                        _selectedSortOption = 'newest';
                        _selectedPriceRange = 'all';
                        _showOnlyWithPhoto = false;
                        _selectedSubcategoryFilter = 'all';
                        _selectedSubSubcategoryFilter = 'all';
                      });
                    },
                    child: const Text(
                      'Сбросить',
                      style: TextStyle(
                        color: Color(0xff183B4E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Сортировка
              const Text(
                'Сортировка',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: _sortOptions.map((option) {
                  return RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_sortLabels[option] ?? option),
                    value: option,
                    groupValue: _selectedSortOption,
                    activeColor: const Color(0xff183B4E),
                    onChanged: (value) {
                      setModalState(() {
                        _selectedSortOption = value!;
                      });
                      setState(() {
                        _selectedSortOption = value!;
                      });
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 20),
              
              // Подкатегории 2-го уровня
              if (_subcategoryOptions.length > 1) ...[
                const Text(
                  'Подкатегория',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: _subcategoryOptions.map((option) {
                    return RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_subcategoryLabels[option] ?? option),
                      value: option,
                      groupValue: _selectedSubcategoryFilter,
                      activeColor: const Color(0xff183B4E),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedSubcategoryFilter = value!;
                          _selectedSubSubcategoryFilter = 'all';
                        });
                        setState(() {
                          _selectedSubcategoryFilter = value!;
                          _selectedSubSubcategoryFilter = 'all';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Подкатегории 3-го уровня
              if (_selectedSubcategoryFilter != 'all' && _subSubcategoryOptions.length > 1) ...[
                const Text(
                  'Тип',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: _subSubcategoryOptions.map((option) {
                    return RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_subSubcategoryLabels[option] ?? option),
                      value: option,
                      groupValue: _selectedSubSubcategoryFilter,
                      activeColor: const Color(0xff183B4E),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedSubSubcategoryFilter = value!;
                        });
                        setState(() {
                          _selectedSubSubcategoryFilter = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
              
              // Цена
              const Text(
                'Цена',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: _priceRanges.map((range) {
                  return RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_priceLabels[range] ?? range),
                    value: range,
                    groupValue: _selectedPriceRange,
                    activeColor: const Color(0xff183B4E),
                    onChanged: (value) {
                      setModalState(() {
                        _selectedPriceRange = value!;
                      });
                      setState(() {
                        _selectedPriceRange = value!;
                      });
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 20),
              
              // Только с фото
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Только с фото'),
                value: _showOnlyWithPhoto,
                activeColor: const Color(0xff183B4E),
                onChanged: (value) {
                  setModalState(() {
                    _showOnlyWithPhoto = value!;
                  });
                  setState(() {
                    _showOnlyWithPhoto = value!;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff183B4E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Показать (${_filteredProducts.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
