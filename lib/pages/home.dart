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
import 'package:korset_app/models/category.dart';
import 'package:korset_app/services/category_service.dart';

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

  // Add selected tab index
  int _selectedTabIndex = 0;

  // Add tab titles
  final List<String> _tabTitles = [
    "Популярные",
    "Свежие",
    "Рекомендации",
  ];

  // Categories list
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshing = false;

  // No default categories - we'll rely on the API

  @override
  void initState() {
    super.initState();
    _fetchCategories();
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

  // Filter variables
  String? _selectedCity;
  String? _selectedCategory;
  double _minPrice = 0;
  double _maxPrice = 100000000;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Cities list
  final List<String> _cities = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Актобе',
    'Тараз',
    'Павлодар',
    'Усть-Каменогорск',
    'Семей',
    'Атырау',
    'Костанай',
    'Петропавловск',
    'Орал',
    'Темиртау',
    'Туркестан',
    'Актау',
    'Кокшетау',
    'Талдыкорган',
    'Экибастуз',
    'Рудный',
    'Жезказган'
  ];

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
              child: DropdownButton<String>(
                value: _selectedCity,
                hint: Text(
                  'Выберите город',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                items: _cities.map((city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
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
                                  color: Colors.white,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Поиск',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFB6B6C1),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: _categories.length,
                                      itemBuilder: (context, index) {
                                        final category = _categories[index];
                                        return _buildCategoryCard(
                                          icon: category.icon,
                                          label: category.label,
                                          bgColor: category.bgColor,
                                        );
                                      },
                                    ),
                        ),
                      ),

                      // MARK: - Marketplace Features Block
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        height: 180,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SecureDealsPage(),
                                  ),
                                );
                              },
                              child: _buildFeatureCard(
                                color: const Color(0xFF56A3E6),
                                image: "./assets/icons/wallet.png",
                                title: "Безопасные\nсделки",
                                subtitle: "Это просто и безопасно!",
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MapListingsPage(),
                                  ),
                                );
                              },
                              child: _buildFeatureCard(
                                color: const Color(0xFFF7B84B),
                                image: "./assets/icons/map.png",
                                title: "Объявления\nна карте",
                                subtitle: "Все объявления в одном месте!",
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TurboSalesPage(),
                                  ),
                                );
                              },
                              child: _buildFeatureCard(
                                color: const Color(0xFFD16DD2),
                                image: "./assets/icons/rocket.png",
                                title: "Турбо\nпродажа",
                                subtitle: "Ваше предложение увидит максимум посетителей!",
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const OnlineStoresPage(),
                                  ),
                                );
                              },
                              child: _buildFeatureCard(
                                color: const Color(0xFF5DBB6B),
                                image: "./assets/icons/shop.png",
                                title: "Онлайн-\nмагазины",
                                subtitle: "Превратите свой профиль в полноценный магазин",
                              ),
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
                        itemCount: 1,
                        itemBuilder: (context, index) {
                          return _buildProductCard(
                            image: "assets/videos/video.mp4",
                            title: "Продам 3к кв в кирпичном доме",
                            location: "Туркестан",
                            price: "17 300 000 ₸",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DetailPage(
                                    product: {
                                      'image': "assets/videos/video.mp4",
                                      'title': "Продам 3к кв в кирпичном доме",
                                      'location': "Туркестан, Жарылкапова 10",
                                      'price': "17 300 000 ₸",
                                      'description':
                                          "Просторная 3-комнатная квартира в кирпичном доме. Отличное состояние, современный ремонт. Район с развитой инфраструктурой, рядом школа, детский сад, магазины. Свободная продажа.",
                                      'seller': "Erdaulet",
                                      'sellerSince': "2023",
                                    },
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
                            "МАГАЗИНЫ",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xff2F2D2C),
                            ),
                          ),
                          TextButton(
                            child: const Text(
                              "ВСЕ",
                              style: TextStyle(
                                color: Color(0xff003092),
                              ),
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildStoreCard(
                              image: null,
                              name: "VV19771325@",
                              rating: 0,
                              adsCount: 0,
                            ),
                            _buildStoreCard(
                              image: null,
                              name: "milan",
                              rating: 0,
                              adsCount: 1,
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
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xffFF8C00), Color(0xff003092)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: CircleAvatar(
              backgroundImage: AssetImage(image),
              radius: 28,
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 12),
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
          // ... existing code ...
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xffF1F1F1),
            border: Border.all(color: const Color(0xff183B4E), width: 2),
          ),
          child: const Icon(
            IconlyBold.camera,
            color: Color(0xff183B4E),
            size: 30.0,
          ),
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        "Ваша история",
        style: TextStyle(fontSize: 12),
      ),
    ],
  );
}

// --- Category Card ---
Widget _buildCategoryCard({
  required String icon,
  required String label,
  required Color bgColor,
}) {
  return Container(
    width: 90,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: icon.startsWith('http') 
              ? ClipOval(
                  child: Image.network(
                    icon,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.category,
                        size: 30,
                        color: Colors.white,
                      );
                    },
                  ),
                )
              : Image.asset(
                  icon,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: VideoPlayerWidget(
                    videoUrl: image, 
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    IconlyBroken.heart,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                      color: Color(0xff2F2D2C),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.location_on,
                          size: 12.0,
                          color: Color(0xff183B4E),
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Color(0xff2F2D2C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xff183B4E).withOpacity(0.1),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        color: Color(0xff183B4E),
                        fontWeight: FontWeight.w700,
                        fontSize: 14.0,
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
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: image != null
              ? Image.asset(
                  image,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 70,
                  height: 70,
                  color: const Color(0xFFF6F8F7),
                  child: const Icon(
                    IconlyBold.camera,
                    size: 40,
                    color: Color(0xFFBFC9CE),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              5,
              (i) => Icon(
                    IconlyBold.star,
                    size: 20,
                    color: i < rating
                        ? const Color(0xFFFFB800)
                        : const Color(0xFFD9D9D9),
                  )),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "$adsCount объявлен${adsCount == 1 ? 'ие' : 'ий'}",
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 15,
            color: Color(0xFFBFC9CE),
          ),
        ),
      ],
    ),
  );
}
