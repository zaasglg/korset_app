import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:korset_app/auth/register.dart';
import 'package:korset_app/pages/catalog.dart';
import 'package:korset_app/pages/detail.dart';
import 'package:korset_app/pages/secure_deals.dart';
import 'package:korset_app/pages/map_listings.dart';
import 'package:korset_app/pages/turbo_sales.dart';
import 'package:korset_app/pages/online_stores.dart';
import 'package:korset_app/pages/category_page.dart';
import 'package:korset_app/models/category.dart';
import 'package:korset_app/models/city.dart';
import 'package:korset_app/services/category_service.dart';
import 'package:korset_app/services/cities_service.dart';

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

  // Add selected tab index
  int _selectedTabIndex = 0;

  // Add tab titles
  final List<String> _tabTitles = [
    "Популярные",
    "Свежие",
    "Рекомендации",
  ];

  // Sample products data
  final List<Map<String, dynamic>> _allProducts = [
    {
      'image': "assets/videos/video.mp4",
      'title': "Продам 3к кв в кирпичном доме",
      'location': "Туркестан",
      'price': "17 300 000 ₸",
      'category': 'Недвижимость',
      'description': "Просторная 3-комнатная квартира в кирпичном доме. Отличное состояние, современный ремонт.",
      'seller': "Erdaulet",
      'sellerSince': "2023",
    },
    {
      'image': "assets/images/image.webp",
      'title': "iPhone 15 Pro Max 256GB",
      'location': "Алматы",
      'price': "650 000 ₸",
      'category': 'Электроника',
      'description': "Новый iPhone 15 Pro Max в идеальном состоянии. Все документы в наличии.",
      'seller': "Мурат",
      'sellerSince': "2022",
    },
    {
      'image': "assets/images/image.webp",
      'title': "Toyota Camry 2020",
      'location': "Астана",
      'price': "12 500 000 ₸",
      'category': 'Транспорт',
      'description': "Автомобиль в отличном состоянии, один владелец, все ТО пройдены.",
      'seller': "Асылжан",
      'sellerSince': "2021",
    },
    {
      'image': "assets/images/image.webp",
      'title': "Зимняя куртка Nike",
      'location': "Шымкент",
      'price': "35 000 ₸",
      'category': 'Одежда',
      'description': "Теплая зимняя куртка Nike, размер L, новая с этикетками.",
      'seller': "Айгерим",
      'sellerSince': "2023",
    },
    {
      'image': "assets/images/image.webp",
      'title': "Игровой ноутбук ASUS",
      'location': "Алматы",
      'price': "450 000 ₸",
      'category': 'Электроника',
      'description': "Мощный игровой ноутбук для работы и развлечений. RTX 3060, 16GB RAM.",
      'seller': "Данияр",
      'sellerSince': "2022",
    },
    {
      'image': "assets/images/image.webp",
      'title': "Студия в новостройке",
      'location': "Астана",
      'price': "8 500 000 ₸",
      'category': 'Недвижимость',
      'description': "Уютная студия в новом жилом комплексе с современным ремонтом.",
      'seller': "Жанар",
      'sellerSince': "2023",
    },
  ];

  // Categories list
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshing = false;

  // Cities data
  List<City> _cities = [];
  bool _citiesLoading = false;
  String? _citiesError;

  // No default categories - we'll rely on the API

  // Get products for current tab
  List<Map<String, dynamic>> _getProductsForTab() {
    switch (_selectedTabIndex) {
      case 0: // Популярные
        return _allProducts.take(4).toList();
      case 1: // Свежие
        return _allProducts.reversed.take(4).toList();
      case 2: // Рекомендации
        return _allProducts.where((product) => 
          product['category'] == 'Недвижимость' || 
          product['category'] == 'Электроника'
        ).take(4).toList();
      default:
        return _allProducts.take(4).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchCities();
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
            _citiesError = 'Не удалось загрузить города. Проверьте подключение к интернету.';
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
              'Фильтры',
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
                              Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ошибка загрузки городов',
                                  style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                                ),
                              ),
                              TextButton(
                                onPressed: _fetchCities,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
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
                        borderSide: const BorderSide(color: Color(0xff183B4E), width: 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        borderSide: const BorderSide(color: Color(0xff183B4E), width: 2),
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
                      color: const Color(0xff183B4E)
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply filters logic here
                        // TODO: Implement actual filtering using:
                        // _selectedCity, _selectedCategory, _minPrice, _maxPrice
                        print('Applying filters: City: $_selectedCity, Category: $_selectedCategory, Price: $_minPrice - $_maxPrice');
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
                          color: Colors.grey.withOpacity(0.2),
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
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildAddStoryButton(context),
                            const SizedBox(width: 12),
                            _buildStoryCircle(
                              image: "assets/icons/guest.png",
                              label: "ERDAULET",
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return CupertinoAlertDialog(
                                      title: const Text("Авторизация"),
                                      content: const Text(
                                          "Пожалуйста, авторизуйтесь, чтобы продолжить."),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text("Отмена"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        CupertinoDialogAction(
                                          child: const Text("Войти"),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const RegisterPage())); // Закрыть диалог
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF183B4E).withOpacity(0.08),
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
                                        mainAxisAlignment: MainAxisAlignment.center,
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
                                          builder: (context) => const SecureDealsPage(),
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
                                          builder: (context) => const MapListingsPage(),
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
                                          builder: (context) => const TurboSalesPage(),
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
                                          builder: (context) => const OnlineStoresPage(),
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
                        height: 32,
                        margin: const EdgeInsets.only(bottom: 16),
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
                                margin: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isSelected
                                          ? const Color(0xff183B4E)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    _tabTitles[index],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xff183B4E)
                                          : const Color(0xff2F2D2C),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(
                        height: 10.0,
                      ),

                      Text(
                        _tabTitles[_selectedTabIndex].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xff183B4E),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemCount: _getProductsForTab().length,
                        itemBuilder: (context, index) {
                          final product = _getProductsForTab()[index];
                          return _buildProductCard(
                            image: product['image'],
                            title: product['title'],
                            location: product['location'],
                            price: product['price'],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailPage(
                                    product: product,
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

                // MARK: - Stores Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Магазины",
                            style: TextStyle(
                              fontFamily: "Atyp",
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF183B4E).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const OnlineStoresPage(),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 240,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          children: [
                            _buildStoreCard(
                              image: "assets/images/image.webp",
                              name: "TechnoStore",
                              rating: 5,
                              adsCount: 127,
                            ),
                            _buildStoreCard(
                              image: "assets/images/image.webp",
                              name: "FashionHub",
                              rating: 4,
                              adsCount: 89,
                            ),
                            _buildStoreCard(
                              image: null,
                              name: "AutoParts KZ",
                              rating: 5,
                              adsCount: 156,
                            ),
                            _buildStoreCard(
                              image: null,
                              name: "BeautyWorld",
                              rating: 4,
                              adsCount: 73,
                            ),
                            _buildStoreCard(
                              image: null,
                              name: "SportZone",
                              rating: 5,
                              adsCount: 94,
                            ),
                          ],
                        ),
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
                boxShadow: [
                  BoxShadow(
                    color: category.bgColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: category.icon.startsWith('http') 
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        category.icon,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.category,
                            size: 32,
                            color: Colors.white,
                          );
                        },
                      ),
                    )
                  : Image.asset(
                      category.icon,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
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
            gradient: const LinearGradient(
              colors: [Color(0xff183B4E), Color(0xff56A3E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff183B4E).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                backgroundImage: AssetImage(image),
                radius: 30,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
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
Widget _buildAddStoryButton(BuildContext context) {
  return Column(
    children: [
      GestureDetector(
        onTap: () {
          // TODO: Add story functionality
        },
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: const Color(0xff183B4E), 
              width: 2.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff183B4E).withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            IconlyBold.camera,
            color: Color(0xff183B4E),
            size: 32,
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

// --- Product Card ---
Widget _buildProductCard({
  required String image,
  required String title,
  required String location,
  required String price,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
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
                    child: VideoPlayerWidget(
                      videoUrl: image, 
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
                      price,
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
                    title,
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
                          location,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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
                  color: Colors.white.withOpacity(0.9),
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
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ],
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
                      const Color(0xff183B4E).withOpacity(0.1),
                      const Color(0xff56A3E6).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                  color: i < rating
                      ? const Color(0xFFFFB800)
                      : Colors.grey[300],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Ads count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff183B4E).withOpacity(0.1),
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
