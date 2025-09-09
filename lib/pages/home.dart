import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:korset_app/pages/catalog.dart';
import 'package:korset_app/pages/detail.dart';
import 'package:korset_app/pages/secure_deals.dart';
import 'package:korset_app/pages/map_listings.dart';
import 'package:korset_app/pages/turbo_sales.dart';
import 'package:korset_app/pages/online_stores.dart';
import 'package:korset_app/services/image_url_helper.dart';
import 'package:korset_app/pages/category_page.dart';
import 'package:korset_app/pages/story_viewer.dart';
import 'package:korset_app/pages/create_story_page.dart';
import 'package:korset_app/models/category.dart';
import 'package:korset_app/models/city.dart';
import 'package:korset_app/models/product.dart';
import 'package:korset_app/services/category_service.dart';
import 'package:korset_app/services/cities_service.dart';
import 'package:korset_app/services/auth_service.dart';
import 'package:korset_app/services/product_service.dart';
import 'package:korset_app/services/favorites_service.dart';
import 'package:korset_app/services/story_service.dart';
import 'package:korset_app/models/story.dart';
import 'package:korset_app/components/product_image_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // TextControllers
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CategoryService _categoryService = CategoryService();
  final CitiesService _citiesService = CitiesService();
  final ProductService _productService = ProductService();

  // Add selected tab index
  int _selectedTabIndex = 0;

  // Add tab titles
  final List<String> _tabTitles = [
    "Рекомендации",
    "Свежие",
    "Магазины",
  ];

  // Products data from API
  List<Product> _allProducts = [];
  bool _productsLoading = false;
  String? _productsError;

  // Favorites data from API
  Set<int> _favoriteProductIds = <int>{};
  bool _favoritesLoading = false;

  // Categories list
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshing = false;

  // Cities data
  List<City> _cities = [];
  bool _citiesLoading = false;
  String? _citiesError;

  // Authentication state
  bool _isAuthenticated = false;

  // Real Stories data from API
  List<Story> _realStories = [];
  bool _storiesLoading = false;
  String? _storiesError;

  // Mock Stories data (fallback)
  final List<Map<String, dynamic>> _storiesData = [];

  // No default categories - we'll rely on the API

  // Get products for current tab
  List<Product> _getProductsForTab() {
    switch (_selectedTabIndex) {
      case 0: // Рекомендации
        return _allProducts;
      case 1: // Свежие
        return _allProducts.reversed.toList();
      case 2: // Магазины
        return []; // Пустой список, так как здесь будут магазины
      default:
        return _allProducts;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchCities();
    _fetchProducts();
    _fetchFavorites();
    _fetchStories();
    _checkAuthentication();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _productsLoading = true;
        _productsError = null;
      });

      final products = await _productService.getProducts(limit: 100);

      if (mounted) {
        setState(() {
          _allProducts = products;
          _productsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allProducts = [];
          _productsLoading = false;
          _productsError = 'Ошибка загрузки объявлений: ${e.toString()}';
        });
      }
      print('Error fetching products: $e');
    }
  }

  Future<void> _checkAuthentication() async {
    final isAuthenticated = await AuthService.isAuthenticated();
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuthenticated;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Проверяем авторизацию при каждом возврате на страницу
    _checkAuthentication();
  }

  Future<void> _fetchCategories() async {
    if (_isRefreshing) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _isRefreshing = true;
      });

      final categories = await _categoryService.getCategories();

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load categories';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchCities() async {
    try {
      setState(() {
        _citiesLoading = true;
        _citiesError = null;
      });

      final cities = await _citiesService.getCities();

      if (mounted) {
        setState(() {
          _cities = cities;
          _citiesLoading = false;
          if (cities.isEmpty) {
            _citiesError =
                'Не удалось загрузить города. Проверьте подключение к интернету.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cities = [];
          _citiesLoading = false;
          _citiesError = 'Ошибка загрузки городов: ${e.toString()}';
        });
      }
      print('Error fetching cities: $e');
    }
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

  Future<void> _fetchStories() async {
    try {
      setState(() {
        _storiesLoading = true;
        _storiesError = null;
      });

      final stories = await StoryService.getStories();

      if (mounted) {
        setState(() {
          _realStories = stories;
          _storiesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _realStories = [];
          _storiesLoading = false;
          _storiesError = 'Ошибка загрузки историй: ${e.toString()}';
        });
      }
      print('Error fetching stories: $e');
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
      final newFavoriteStatus =
          await FavoritesService.toggleFavorite(productId, isCurrentlyFavorite);

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

  // Конвертируем реальные истории в формат для StoryViewerPage, группируя по авторам
  List<Map<String, dynamic>> _convertStoriesToMockFormat(List<Story> stories) {
    final Map<String, Map<String, dynamic>> userStoriesMap = {};
    for (final story in stories) {
      final userKey = story.userName;
      final avatar = (story.userAvatar != null && story.userAvatar!.isNotEmpty)
          ? (story.userAvatar!.startsWith('http')
              ? story.userAvatar!
              : 'https://videopokaz.kz/storage/${story.userAvatar!}')
          : 'assets/icons/guest.png';
      final imageUrl = story.mediaUrl != null
          ? (story.mediaUrl!.startsWith('http')
              ? story.mediaUrl!
              : 'https://videopokaz.kz/storage/${story.mediaUrl!}')
          : 'assets/images/image.webp';
      final storyItem = {
        'image': imageUrl,
        'time': _getTimeAgo(story.createdAt),
        'text': story.content ?? '',
        'isVideo': story.mediaType == 'video',
      };
      if (userStoriesMap.containsKey(userKey)) {
        userStoriesMap[userKey]!['stories'].add(storyItem);
      } else {
        userStoriesMap[userKey] = {
          'name': userKey,
          'avatar': avatar,
          'stories': [storyItem],
        };
      }
    }
    return userStoriesMap.values.toList();
  }

  // Получаем время в формате "Xч назад"
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}м';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}ч';
    } else {
      return '${difference.inDays}д';
    }
  }

  // Filter variables
  City? _selectedCity;
  String? _selectedCategory;
  double _minPrice = 0;
  double _maxPrice = 100000000;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
              'Филsьтры',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // City filter
            const Text(
              'Город',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _citiesLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Загрузка городов...'),
                        ],
                      ),
                    )
                  : _citiesError != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  size: 16, color: Colors.red.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ошибка загрузки городов',
                                  style: TextStyle(
                                      color: Colors.red.shade600, fontSize: 14),
                                ),
                              ),
                              TextButton(
                                onPressed: _fetchCities,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Повторить',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButton<City>(
                          value: _selectedCity,
                          hint: Text(
                            'Выберите город',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: Colors.grey[600]),
                          items: _cities.map((city) {
                            return DropdownMenuItem<City>(
                              value: city,
                              child: Text('${city.name} (${city.regionName})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCity = value;
                            });
                          },
                        ),
            ),
            const SizedBox(height: 20),

            // Category filter
            const Text(
              'Категория',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButton<String>(
                value: _selectedCategory,
                hint: Text(
                  'Выберите категорию',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.name,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Price range
            const Text(
              'Цена',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'От',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(0xff183B4E), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      _minPrice = double.tryParse(value) ?? 0;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '—',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'До',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Color(0xff183B4E), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      _maxPrice = double.tryParse(value) ?? 100000000;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCity = null;
                          _selectedCategory = null;
                          _minPriceController.clear();
                          _maxPriceController.clear();
                        });
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xff183B4E)),
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply filters logic here
                        // TODO: Implement actual filtering using:
                        // _selectedCity, _selectedCategory, _minPrice, _maxPrice
                        print(
                            'Applying filters: City: $_selectedCity, Category: $_selectedCategory, Price: $_minPrice - $_maxPrice');
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Применить',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
    );
  }

  @override
  Widget build(BuildContext context) => KeyboardDismisser(
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          key: _scaffoldKey,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: SafeArea(
                child: Row(
                  children: [
                    // Поле поиска
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            const Icon(Icons.search,
                                color: Color(0xFFB6B6C1), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Поиск товаров, услуг...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFB6B6C1),
                                    fontSize: 14,
                                  ),
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Правая иконка (фильтр/настройки)
                    GestureDetector(
                      onTap: () {
                        _showFilterBottomSheet(context);
                      },
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: Icon(IconlyBroken.filter,
                              color: Color(0xff183B4E), size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // MARK: - Header
                Container(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                  ),
                  child: Column(
                    children: [
                      // MARK: - Stories
                      Container(
                        margin: const EdgeInsets.only(top: 24.0, left: 10),
                        height: 100,
                        child: _storiesLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF183B4E),
                                  strokeWidth: 2,
                                ),
                              )
                            : ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  if (_isAuthenticated) ...[
                                    _buildAddStoryButton(
                                        context, _fetchStories),
                                    const SizedBox(width: 12),
                                  ],

                                  // Build story circles from real API data
                                  if (_realStories.isNotEmpty) ...[
                                    ..._convertStoriesToMockFormat(_realStories)
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final storyGroup = entry.value;
                                      return Row(
                                        children: [
                                          _buildStoryCircle(
                                            image: storyGroup['avatar'],
                                            label: storyGroup['name'],
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      StoryViewerPage(
                                                    stories:
                                                        _convertStoriesToMockFormat(
                                                            _realStories),
                                                    initialIndex: index,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          if (index <
                                              _convertStoriesToMockFormat(
                                                          _realStories)
                                                      .length -
                                                  1)
                                            const SizedBox(width: 12),
                                        ],
                                      );
                                    }),
                                  ] else if (_storiesError == null) ...[
                                    // Показываем mock данные если нет реальных историй
                                    ..._storiesData
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final story = entry.value;
                                      return Row(
                                        children: [
                                          _buildStoryCircle(
                                            image: story['avatar'],
                                            label: story['name'],
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      StoryViewerPage(
                                                    stories: _storiesData,
                                                    initialIndex: index,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          if (index < _storiesData.length - 1)
                                            const SizedBox(width: 12),
                                        ],
                                      );
                                    }),
                                  ],

                                  // Показываем ошибку если есть
                                  if (_storiesError != null &&
                                      _realStories.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.grey[400],
                                            size: 24,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Ошибка загрузки',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                      ),

                      const SizedBox(
                        height: 30.0,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Категории",
                            style: TextStyle(
                              fontFamily: "Atyp",
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF183B4E)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const CatalogPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Все",
                                style: TextStyle(
                                  fontFamily: "Atyp",
                                  color: Color(0xFF183B4E),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),

                      Container(
                        height: 120,
                        margin: const EdgeInsets.only(top: 20),
                        child: RefreshIndicator(
                          onRefresh: _fetchCategories,
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF183B4E),
                                    strokeWidth: 2,
                                  ),
                                )
                              : _errorMessage != null
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextButton(
                                            onPressed: _fetchCategories,
                                            child: const Text(
                                              'Повторить',
                                              style: TextStyle(
                                                color: Color(0xFF183B4E),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: _categories.length,
                                      itemBuilder: (context, index) {
                                        final category = _categories[index];
                                        return _buildCategoryCard(category);
                                      },
                                    ),
                        ),
                      ),

                      // MARK: - Marketplace Features Block
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                "Сервисы",
                                style: TextStyle(
                                  fontFamily: "Atyp",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // First row - 2 cards
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SecureDealsPage(),
                                        ),
                                      );
                                    },
                                    child: _buildModernFeatureCard(
                                      icon: Icons.security_rounded,
                                      title: "Безопасные сделки",
                                      subtitle: "Защищённые платежи",
                                      color: const Color(0xFF56A3E6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const MapListingsPage(),
                                        ),
                                      );
                                    },
                                    child: _buildModernFeatureCard(
                                      icon: Icons.map_rounded,
                                      title: "На карте",
                                      subtitle: "Поиск рядом",
                                      color: const Color(0xFFF7B84B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Second row - 2 cards
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TurboSalesPage(),
                                        ),
                                      );
                                    },
                                    child: _buildModernFeatureCard(
                                      icon: Icons.rocket_launch_rounded,
                                      title: "Турбо продажа",
                                      subtitle: "Быстрое продвижение",
                                      color: const Color(0xFFD16DD2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const OnlineStoresPage(),
                                        ),
                                      );
                                    },
                                    child: _buildModernFeatureCard(
                                      icon: Icons.storefront_rounded,
                                      title: "Магазины",
                                      subtitle: "Бизнес-профили",
                                      color: const Color(0xFF5DBB6B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30.0),

                // MARK: - List Product
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom Tab Bar
                      Container(
                        height: 44,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _tabTitles.length,
                          itemBuilder: (context, index) {
                            final isSelected = index == _selectedTabIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTabIndex = index;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 32),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  child: Text(
                                    _tabTitles[index].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.black.withValues(alpha: 0.4),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Показываем товары или магазины в зависимости от выбранного таба
                      _selectedTabIndex == 2
                          ? // Для таба "Магазины" показываем сетку магазинов
                          GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                              ),
                              itemCount: 6, // Показываем 6 магазинов в сетке
                              itemBuilder: (context, index) {
                                final stores = [
                                  {
                                    "image": "assets/images/image.webp",
                                    "name": "TechnoStore",
                                    "rating": 5,
                                    "adsCount": 127
                                  },
                                  {
                                    "image": "assets/images/image.webp",
                                    "name": "FashionHub",
                                    "rating": 4,
                                    "adsCount": 89
                                  },
                                  {
                                    "image": null,
                                    "name": "AutoParts KZ",
                                    "rating": 5,
                                    "adsCount": 156
                                  },
                                  {
                                    "image": null,
                                    "name": "BeautyWorld",
                                    "rating": 4,
                                    "adsCount": 73
                                  },
                                  {
                                    "image": null,
                                    "name": "SportZone",
                                    "rating": 5,
                                    "adsCount": 94
                                  },
                                  {
                                    "image": "assets/images/image.webp",
                                    "name": "HomeDecor",
                                    "rating": 4,
                                    "adsCount": 52
                                  },
                                ];
                                final store = stores[index];
                                return _buildGridStoreCard(
                                  image: store["image"] as String?,
                                  name: store["name"] as String,
                                  rating: store["rating"] as int,
                                  adsCount: store["adsCount"] as int,
                                );
                              },
                            )
                          : // Для остальных табов показываем товары
                          _productsLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF183B4E),
                                    strokeWidth: 2,
                                  ),
                                )
                              : _productsError != null
                                  ? Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            _productsError!,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 10),
                                          TextButton(
                                            onPressed: _fetchProducts,
                                            child: const Text(
                                              'Повторить',
                                              style: TextStyle(
                                                color: Color(0xFF183B4E),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.60,
                                        crossAxisSpacing: 7,
                                        mainAxisSpacing: 7,
                                      ),
                                      itemCount: _getProductsForTab().length,
                                      itemBuilder: (context, index) {
                                        final product =
                                            _getProductsForTab()[index];
                                        return _buildProductCard(
                                          product: product,
                                          favoriteProductIds:
                                              _favoriteProductIds,
                                          onToggleFavorite: _toggleFavorite,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailPage(
                                                  productId: product.id,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                    ],
                  ),
                ),

                const SizedBox(height: 30.0),
              ],
            ),
          ),
        ),
      );

  // --- Category Card ---
  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryPage(category: category),
          ),
        );
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: category.bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: (category.icon.isNotEmpty &&
                        category.icon.startsWith('http') &&
                        Uri.tryParse(category.icon) != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: category.icon,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.category,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.category,
                        size: 32,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Custom Drawer

// --- Story Circle Widget ---
Widget _buildStoryCircle(
    {required String image,
    required String label,
    required VoidCallback onTap}) {
  return Column(
    children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xff56A3E6),
              width: 2.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: image.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 30,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 30,
                          ),
                        ),
                      )
                    : Image.asset(
                        image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 30,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label.length > 12 ? '${label.substring(0, 10)}...' : label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xff1A1A1A),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

// --- Real Story Circle Widget ---
Widget _buildRealStoryCircle({
  required Story story,
  required VoidCallback onTap,
}) {
  return Column(
    children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xff56A3E6),
              width: 2.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: story.userAvatar != null &&
                        story.userAvatar!.isNotEmpty &&
                        story.userAvatar!.startsWith('http') &&
                        Uri.tryParse(story.userAvatar!) != null
                    ? CachedNetworkImage(
                        imageUrl: story.userAvatar!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 30,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 30,
                          ),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 30,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        story.userName.length > 12
            ? '${story.userName.substring(0, 10)}...'
            : story.userName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xff1A1A1A),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

// --- Add Story Button ---
Widget _buildAddStoryButton(BuildContext context, VoidCallback onStoryCreated) {
  return Column(
    children: [
      GestureDetector(
        onTap: () async {
          // Открываем страницу создания истории
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateStoryPage(),
            ),
          );

          // Если история была создана, обновляем список историй
          if (result != null) {
            onStoryCreated(); // Перезагружаем истории
            print('Story created: $result');
          }
        },
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.add,
            color: Colors.grey[600],
            size: 28,
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        "Добавить",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xff1A1A1A),
        ),
      ),
    ],
  );
}

// --- Modern Product Card ---
Widget _buildProductCard({
  required Product product,
  required VoidCallback onTap,
  required Set<int> favoriteProductIds,
  required Function(int) onToggleFavorite,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(1)),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
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
                      width: double.infinity,
                      height: double.infinity,
                      fallbackAsset: 'assets/images/image.webp',
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                ),
                // Enhanced favorite button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => onToggleFavorite(product.id),
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
                        favoriteProductIds.contains(product.id)
                            ? IconlyBold.heart
                            : IconlyBroken.heart,
                        size: 18,
                        color: favoriteProductIds.contains(product.id)
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
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

// --- Video Player Widget ---
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/image.webp',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

Widget _buildFeatureCard({
  required Color color,
  required String image,
  required String title,
  required String subtitle,
}) {
  return Container(
    width: 220,
    margin: const EdgeInsets.only(right: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(
      children: [
        // Полупрозрачная большая иконка как фон
        Positioned(
          right: -1,
          bottom: -1,
          child: Opacity(
            opacity: 0.90,
            child: Image.asset(
              image,
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ),
        // Текст поверх
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
                height: 0.9,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              subtitle,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Colors.white,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Modern minimal feature card
Widget _buildModernFeatureCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
}) {
  return AspectRatio(
    aspectRatio: 1.0, // Делаем квадратными
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12), // Ровные квадратные края
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// --- Store Card ---
Widget _buildStoreCard({
  String? image,
  required String name,
  required int rating,
  required int adsCount,
}) {
  return Container(
    width: 200,
    margin: const EdgeInsets.only(right: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Store avatar
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xff183B4E).withValues(alpha: 0.1),
                      const Color(0xff56A3E6).withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: image != null
                      ? Image.asset(
                          image,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          IconlyBold.bag2,
                          size: 40,
                          color: Color(0xff183B4E),
                        ),
                ),
              ),
              // Verified badge
              if (rating > 3)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5DBB6B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Store name
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xff1A1A1A),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Rating stars
          if (rating > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Icon(
                  i < rating ? IconlyBold.star : IconlyLight.star,
                  size: 16,
                  color:
                      i < rating ? const Color(0xFFFFB800) : Colors.grey[300],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Ads count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff183B4E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$adsCount объявлен${adsCount == 1 ? 'ие' : 'ий'}",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xff183B4E),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// --- Grid Store Card (для таба магазинов) ---
Widget _buildGridStoreCard({
  String? image,
  required String name,
  required int rating,
  required int adsCount,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Store avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xff183B4E).withValues(alpha: 0.1),
                  const Color(0xff56A3E6).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: image != null
                  ? Image.asset(
                      image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      IconlyBold.bag2,
                      size: 30,
                      color: Color(0xff183B4E),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Store name
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 8),

          // Rating and ads count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: 12,
                    color: index < rating
                        ? const Color(0xFFFFB800)
                        : Colors.grey[300],
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            "$adsCount объявлений",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// Метод для конвертации Product в Map для совместимости с DetailPage
Map<String, dynamic> _convertProductToMap(Product product) {
  return {
    'id': product.id,
    'image': product.displayImage,
    'title': product.name,
    'location': product.city.name,
    'price': product.formattedPrice,
    'category': product.category.name,
    'description': product.description,
    'seller': 'Продавец', // В API нет информации о продавце
    'sellerSince': '2023',
    'address': product.address,
    'video_url': product.videoUrl,
    'parameter_values': product.parameterValues,
    'whatsapp_number': product.whatsappNumber,
    'phone_number': product.phoneNumber,
    'ready_for_video_demo': product.readyForVideoDemo,
    'created_at': product.createdAt.toIso8601String(),
  };
}
