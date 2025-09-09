import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:korset_app/models/category.dart';
import 'package:korset_app/pages/detail.dart';
import 'package:korset_app/services/product_service.dart';
import 'package:korset_app/models/product.dart';
import 'package:korset_app/components/product_image_widget.dart';
import 'package:korset_app/services/image_url_helper.dart';
import 'package:korset_app/services/favorites_service.dart';

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
  String _selectedSubcategoryFilter = ''; // Фильтр по подкатегориям 2-го уровня
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

  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Favorites data
  Set<int> _favoriteProductIds = <int>{};
  bool _favoritesLoading = false;

  @override
  void initState() {
    super.initState();
    // Устанавливаем первую подкатегорию по умолчанию
    if (widget.category.children.isNotEmpty) {
      _selectedSubcategoryFilter = widget.category.children.first.name;
    }
    _fetchProducts();
    _fetchFavorites();
  }

  // Получить список подкатегорий для фильтра
  List<String> get _subcategoryOptions {
    if (widget.category.children.isNotEmpty) {
      return widget.category.children.map((cat) => cat.name).toList();
    }
    return [];
  }

  Map<String, String> get _subcategoryLabels {
    Map<String, String> labels = {};
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

  List<Product> get _filteredProducts {
    // The filtering logic is now handled by the API call in _fetchProducts
    // This getter now primarily handles sorting.
    List<Product> filtered = List.from(_products);

    // Сортировка
    filtered.sort((a, b) {
      switch (_selectedSortOption) {
        case 'newest':
          return b.createdAt.compareTo(a.createdAt);
        case 'oldest':
          return a.createdAt.compareTo(b.createdAt);
        case 'price_low':
          return a.price.compareTo(b.price);
        case 'price_high':
          return b.price.compareTo(a.price);
        case 'popular':
          // Если нет поля views, используем ID как показатель популярности
          return b.id.compareTo(a.id);
        default:
          return 0;
      }
    });

    return filtered;
  }

  Future<void> _fetchFavorites() async {
    try {
      setState(() {
        _favoritesLoading = true;
      });

      final favoriteItems = await FavoritesService.getFavorites();

      if (mounted) {
        setState(() {
          _favoriteProductIds = favoriteItems
              .map((item) => int.tryParse(item.id) ?? 0)
              .where((id) => id > 0)
              .toSet();
          _favoritesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _favoritesLoading = false;
        });
      }
      print('Error fetching favorites: $e');
    }
  }

  Future<void> _toggleFavorite(int productId) async {
    try {
      final isCurrentlyFavorite = _favoriteProductIds.contains(productId);
      
      // Optimistically update UI
      setState(() {
        if (isCurrentlyFavorite) {
          _favoriteProductIds.remove(productId);
        } else {
          _favoriteProductIds.add(productId);
        }
      });

      // Make API call
      final newFavoriteStatus = await FavoritesService.toggleFavorite(
        productId, 
        isCurrentlyFavorite
      );

      // Verify the state matches the API response
      if (mounted) {
        setState(() {
          if (newFavoriteStatus) {
            _favoriteProductIds.add(productId);
          } else {
            _favoriteProductIds.remove(productId);
          }
        });
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          if (_favoriteProductIds.contains(productId)) {
            _favoriteProductIds.remove(productId);
          } else {
            _favoriteProductIds.add(productId);
          }
        });
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при обновлении избранного: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error toggling favorite: $e');
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    int effectiveCategoryId;
    
    // Определяем эффективный ID категории для запроса
    if (_selectedSubcategoryFilter == 'all') {
      // Если выбрано "Все подкатегории", используем родительскую категорию
      effectiveCategoryId = widget.category.id;
    } else {
      // Если выбрана конкретная подкатегория
      final selectedSubcat = widget.category.children.firstWhere(
        (cat) => cat.name == _selectedSubcategoryFilter,
      );
      
      if (_selectedSubSubcategoryFilter == 'all') {
        // Если выбрано "Все подкате��ории" 3-го уровня, используем подкатегорию 2-го уровня
        effectiveCategoryId = selectedSubcat.id;
      } else {
        // Если выбрана конкретная подкатегория 3-го уровня
        final selectedSubSubcat = selectedSubcat.children.firstWhere(
          (cat) => cat.name == _selectedSubSubcategoryFilter,
        );
        effectiveCategoryId = selectedSubSubcat.id;
      }
    }

    // Отладочная информация
    print('=== FETCH PRODUCTS DEBUG ===');
    print('Category: ${widget.category.name} (ID: ${widget.category.id})');
    print('Selected subcategory filter: $_selectedSubcategoryFilter');
    print('Selected sub-subcategory filter: $_selectedSubSubcategoryFilter');
    print('Effective category ID: $effectiveCategoryId');
    print('Sort by: $_selectedSortOption');
    print('Price range: $_selectedPriceRange');
    print('Has photo: $_showOnlyWithPhoto');
    print('============================');

    try {
      final fetchedProducts = await _productService.getProductsByCategory(
        categoryId: effectiveCategoryId,
        sortBy: _selectedSortOption,
        priceRange: _selectedPriceRange,
        hasPhoto: _showOnlyWithPhoto,
      );
      
      print('=== API RESPONSE DEBUG ===');
      print('Fetched products count: ${fetchedProducts.length}');
      if (fetchedProducts.isNotEmpty) {
        print('First product: ${fetchedProducts.first.name}');
      }
      print('==========================');
      
      setState(() {
        _products = fetchedProducts;
      });
    } catch (e) {
      print('=== ERROR DEBUG ===');
      print('Error fetching products: $e');
      print('===================');
      setState(() {
        _errorMessage = 'Не удалось загрузить продукты: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            onPressed: () {
              _showFiltersBottomSheet().then((_) => _fetchProducts());
            },
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
                  color: widget.category.bgColor.withValues(alpha: 0.3),
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
          if (_subcategoryOptions.isNotEmpty) ...[
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
                      _fetchProducts();
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
                            color: const Color(0xff183B4E).withValues(alpha: 0.1),
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
                      _fetchProducts();
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
                            color: const Color(0xff183B4E).withValues(alpha: 0.1),
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

  Widget _buildProductsGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    final products = _filteredProducts;
    
    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
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

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with enhanced design
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF8FAFC),
                            Color(0xFFF1F5F9),
                          ],
                        ),
                      ),
                      child: ProductImageWidget(
                        imageUrl: ImageUrlHelper.isValidPath(product.mainPhoto)
                            ? ImageUrlHelper.getImageUrl(product.mainPhoto)
                            : null,
                        videoUrl: ImageUrlHelper.isValidPath(product.videoUrl)
                            ? ImageUrlHelper.getVideoUrl(product.videoUrl)
                            : null,
                        videoPath: ImageUrlHelper.isValidPath(product.video)
                            ? ImageUrlHelper.getVideoUrl(product.video)
                            : null,
                        fit: BoxFit.cover,
                        fallbackAsset: 'assets/images/image.webp',
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                    ),
                  ),
                  // Enhanced favorite button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(product.id),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                        child: Icon(
                          _favoriteProductIds.contains(product.id)
                            ? IconlyBold.heart
                            : IconlyBroken.heart,
                          size: 18,
                          color: _favoriteProductIds.contains(product.id)
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced content section
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location first - with modern icon
                    Text(
                      product.city.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 188, 195, 206),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Enhanced title
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                        color: Color(0xFF0F172A),
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Price after title
                    Text(
                      product.formattedPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),

                    const Spacer(),

                    // Category badge at bottom
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        product.category.name,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFiltersBottomSheet() async {
    return showModalBottomSheet(
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
          child: SingleChildScrollView(
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
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          final firstSubcategory = widget.category.children.isNotEmpty 
                              ? widget.category.children.first.name 
                              : '';
                          setModalState(() {
                            _selectedSortOption = 'newest';
                            _selectedPriceRange = 'all';
                            _showOnlyWithPhoto = false;
                            _selectedSubcategoryFilter = firstSubcategory;
                            _selectedSubSubcategoryFilter = 'all';
                          });
                          setState(() {
                            _selectedSortOption = 'newest';
                            _selectedPriceRange = 'all';
                            _showOnlyWithPhoto = false;
                            _selectedSubcategoryFilter = firstSubcategory;
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
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xff183B4E),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
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
                      _fetchProducts();
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
                      _fetchProducts();
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
                  _fetchProducts();
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
      ),
    );
  }
}