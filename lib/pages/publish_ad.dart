import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:io';
import 'dart:async';
import '../models/category.dart';
import '../models/parameter.dart';
import '../models/city.dart';
import '../models/publication_price.dart';
import '../services/category_service.dart';
import '../services/parameter_service.dart';
import '../services/city_service.dart';
import '../services/product_service.dart';
import '../services/publication_price_service.dart';
import '../navigation.dart';
import 'map_location_picker.dart';
import '../utils/video_compression_helper.dart';

class PublishAdPage extends StatefulWidget {
  const PublishAdPage({super.key});

  @override
  State<PublishAdPage> createState() => _PublishAdPageState();
}

class _PublishAdPageState extends State<PublishAdPage>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  String? _selectedParentCategory;
  String? _selectedSubCategory;
  String? _selectedThirdLevelCategory;

  // Animation controllers for transitions
  late AnimationController _fadeController;

  // Get the most specific selected category ID
  String? get _finalSelectedCategoryId {
    if (_selectedThirdLevelCategory != null) {
      return _selectedThirdLevelCategory;
    } else if (_selectedSubCategory != null) {
      return _selectedSubCategory;
    } else {
      return _selectedParentCategory;
    }
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<String> _videos = [];

  // Phone number formatters
  final MaskTextInputFormatter _phoneFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final MaskTextInputFormatter _whatsappFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Helper method to get clean phone number
  String _getCleanPhoneNumber(String maskedNumber) {
    return maskedNumber.replaceAll(RegExp(r'[^\d]'), '');
  }

  List<File> _videoFiles = []; // For storing actual video files
  VideoPlayerController? _videoController;
  final ImagePicker _picker = ImagePicker();

  // New boolean field for video demo
  bool _readyForVideoDemo = false;

  // Parameters for the last step (if applicable)
  List<Parameter> _categoryParameters = [];
  bool _loadingParameters = false;
  String? _parametersError;

  // API Integration
  final CategoryService _categoryService = CategoryService();
  final ParameterService _parameterService = ParameterService();
  final CityService _cityService = CityService();
  final ProductService _productService = ProductService();
  List<Category> _parentCategories = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Cities data
  List<City> _cities = [];
  City? _selectedCity;
  bool _loadingCities = false;

  // Map location data
  Map<String, dynamic>? _selectedMapLocation;
  String? _selectedMapAddress;

  // Publication price data
  List<PublicationPrice> _publicationPrices = [];
  PublicationPrice? _selectedPublicationPrice;
  bool _loadingPublicationPrices = false;
  String? _publicationPricesError;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchCities();

    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final categories = await _categoryService.getCategories();

      if (mounted) {
        setState(() {
          _parentCategories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки категорий';
          _isLoading = false;
        });
      }
      print('Error fetching categories: $e');
    }
  }

  // Fetch parameters for specific category
  Future<void> _fetchParameters(String categoryId) async {
    if (categoryId.isEmpty) return;

    try {
      setState(() {
        _loadingParameters = true;
        _parametersError = null;
      });

      final parameters =
          await _parameterService.getCategoryParameters(categoryId);

      if (mounted) {
        setState(() {
          _categoryParameters = parameters;
          _loadingParameters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _parametersError = 'Ошибка загрузки параметров';
          _loadingParameters = false;
        });
      }
      print('Error fetching parameters: $e');
    }
  }

  // Fetch cities from API
  Future<void> _fetchCities() async {
    try {
      setState(() {
        _loadingCities = true;
      });

      final cities = await _cityService.getCities();
      print('Loaded ${cities.length} cities'); // Debug print

      if (mounted) {
        setState(() {
          _cities = cities;
          _loadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCities = false;
        });
      }
      print('Error fetching cities: $e');
    }
  }

  // Fetch publication prices from API
  Future<void> _fetchPublicationPrices() async {
    try {
      setState(() {
        _loadingPublicationPrices = true;
        _publicationPricesError = null;
      });

      final prices = await PublicationPriceService.getPublicationPrices();
      print('Loaded ${prices.length} publication prices'); // Debug print

      if (mounted) {
        setState(() {
          _publicationPrices = prices;
          _loadingPublicationPrices = false;
          // Auto-select first price (usually free)
          if (prices.isNotEmpty) {
            _selectedPublicationPrice = prices.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _publicationPricesError = 'Ошибка загрузки цен публикации';
          _loadingPublicationPrices = false;
        });
      }
      print('Error fetching publication prices: $e');
    }
  }

  // Select city and update location controller
  void _selectCity(City city) {
    setState(() {
      _selectedCity = city;
      _locationController.text = city.name;
    });
    Navigator.of(context).pop(); // Close bottom sheet
  }

  // Show city selection bottom sheet
  void _showCityBottomSheet() {
    final TextEditingController searchController = TextEditingController();
    List<City> filteredCities = List.from(_cities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterCities(String query) {
              setModalState(() {
                if (query.isEmpty) {
                  filteredCities = List.from(_cities);
                } else {
                  filteredCities = _cities
                      .where((city) =>
                          city.name.toLowerCase().contains(query.toLowerCase()))
                      .toList();
                }
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Выберите город',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Cities count info
                        if (!_loadingCities && _cities.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Найдено: ${filteredCities.length} из ${_cities.length} городов',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // Search field
                        TextField(
                          controller: searchController,
                          onChanged: filterCities,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Поиск городов...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              IconlyBroken.search,
                              color: Color(0xff183B4E),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cities list
                  Expanded(
                    child: _loadingCities
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xff183B4E),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Загрузка городов...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _cities.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      IconlyBroken.location,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Не удалось загрузить города',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Проверьте подключение к интернету',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _fetchCities();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xff183B4E),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text('Повторить'),
                                    ),
                                  ],
                                ),
                              )
                            : filteredCities.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          IconlyBroken.search,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Города не найдены',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Попробуйте изменить запрос',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    itemCount: filteredCities.length,
                                    separatorBuilder: (context, index) =>
                                        Divider(
                                      height: 1,
                                      color: Colors.grey[100],
                                    ),
                                    itemBuilder: (context, index) {
                                      final city = filteredCities[index];
                                      final isSelected =
                                          _selectedCity?.id == city.id;

                                      return ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 0,
                                          vertical: 8,
                                        ),
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF3366FF)
                                                    .withValues(alpha: 0.1)
                                                : Colors.grey[100],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            IconlyBroken.location,
                                            size: 20,
                                            color: isSelected
                                                ? const Color(0xFF3366FF)
                                                : const Color(0xff183B4E),
                                          ),
                                        ),
                                        title: Text(
                                          city.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFF3366FF)
                                                : const Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        subtitle: city.region != null
                                            ? Text(
                                                city.region!.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              )
                                            : null,
                                        trailing: isSelected
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF3366FF),
                                                size: 24,
                                              )
                                            : null,
                                        onTap: () => _selectCity(city),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Open map location picker
  Future<void> _openMapLocationPicker() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          selectedCity: _selectedCity,
          selectedAddress: _selectedMapAddress,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedMapLocation = result;
        _selectedMapAddress = result['address'] as String?;

        // Auto-fill address field if it's empty
        if (_addressController.text.trim().isEmpty &&
            _selectedMapAddress != null) {
          _addressController.text = _selectedMapAddress!;
        }
      });
    }
  }

  // Clear selected map location
  void _clearMapLocation() {
    setState(() {
      _selectedMapLocation = null;
      _selectedMapAddress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Handle back button press
        if (_currentStep > 0) {
          setState(() {
            _currentStep--;
          });
          return;
        }
        _handleExit();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(IconlyBroken.arrowLeft, color: Color(0xFF1A1A1A)),
            padding: const EdgeInsets.all(4),
            onPressed: () {
              if (_currentStep > 0) {
                setState(() {
                  _currentStep--;
                });
              } else {
                _handleExit();
              }
            },
          ),
          title: Text(
            _getStepTitle(),
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xff183B4E),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${((_currentStep + 1) / 6 * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _fadeController,
                child: _buildStepContent(),
              ),
            ),
            SafeArea(
              child: _buildBottomNavigation(),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Выберите категорию';
      case 1:
        return 'Подкатегория';
      case 2:
        return 'Уточните выбор';
      case 3:
        return 'Информация';
      case 4:
        return 'Видео';
      case 5:
        return 'Параметры';
      case 6:
        return 'Тариф публикации';
      default:
        return 'Публикация';
    }
  }

  Widget _buildStepContent() {
    // Only reset and forward animation controller if it's not already animating
    if (!_fadeController.isAnimating) {
      _fadeController.reset();
      _fadeController.forward();
    }

    switch (_currentStep) {
      case 0:
        return _buildCategorySelection();
      case 1:
        return _buildSubCategorySelection();
      case 2:
        // Dedicated step for 3rd level category selection
        if (_selectedSubCategory != null && _selectedParentCategory != null) {
          try {
            final selectedParent = _parentCategories.firstWhere(
              (category) => category.id.toString() == _selectedParentCategory,
            );

            final selectedSubcategory = selectedParent.children.firstWhere(
              (subcat) => subcat.id.toString() == _selectedSubCategory,
            );

            return _buildThirdLevelCategorySelection(selectedSubcategory);
          } catch (e) {
            print('Error in _buildStepContent: $e');
          }
        }
        return Container();
      case 3:
        return _buildInformationForm();
      case 4:
        return _buildVideoSelection();
      case 5:
        return _buildParametersForm();
      case 6:
        return _buildPublicationPriceSelection();
      default:
        return _buildCategorySelection();
    }
  }

  Widget _buildSubCategorySelection() {
    if (_selectedParentCategory == null || _parentCategories.isEmpty) return Container();

    try {
      final selectedParent = _parentCategories.firstWhere(
        (category) => category.id.toString() == _selectedParentCategory,
        orElse: () => _parentCategories.first,
      );

      final subcategories = selectedParent.children;

    if (subcategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconlyBroken.category,
                  size: 32,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'В данной категории нет подкатегорий',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите подкатегорию',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Уточните категорию товара или услуги',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Подкатегории',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: subcategories.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final subcategory = subcategories[index];
                final isSelected =
                    _selectedSubCategory == subcategory.id.toString();
                final hasChildren = subcategory.children.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSubCategory = subcategory.id.toString();
                          _selectedThirdLevelCategory = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3366FF).withValues(alpha: 0.12)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3366FF)
                                : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF3366FF)
                                        .withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF3366FF)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF3366FF)
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                subcategory.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? const Color(0xFF3366FF)
                                      : const Color(0xFF1A1A1A),
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            if (hasChildren)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: isSelected ? 1.0 : 0.6,
                                child: Icon(
                                  IconlyBroken.arrowRight2,
                                  size: 16,
                                  color: isSelected
                                      ? const Color(0xFF3366FF)
                                      : Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
    } catch (e) {
      print('Error in _buildSubCategorySelection: $e');
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки подкатегорий',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCategorySelection() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xff183B4E).withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff183B4E),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Загружаем категории',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _parentCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage ?? 'Категории не найдены',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchCategories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff183B4E),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Категория товара',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Выберите подходящую категорию для размещения',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _parentCategories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final category = _parentCategories[index];
              final isSelected =
                  _selectedParentCategory == category.id.toString();

              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedParentCategory = category.id.toString();
                      _selectedSubCategory = null;
                      _selectedThirdLevelCategory = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(18),
                  splashColor: category.bgColor.withValues(alpha: 0.08),
                  highlightColor: category.bgColor.withValues(alpha: 0.04),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category.bgColor.withValues(alpha: 0.06)
                          : Colors.grey[50]?.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? category.bgColor.withValues(alpha: 0.4)
                            : Colors.grey[200]!.withValues(alpha: 0.6),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: category.bgColor.withValues(alpha: 0.12),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? category.bgColor
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected
                                        ? category.bgColor
                                        : Colors.grey[300]!)
                                    .withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: category.photo != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      category.icon,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(
                                          Icons.category_outlined,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[500],
                                          size: 28,
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.category_outlined,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[500],
                                    size: 28,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? category.bgColor.computeLuminance() >
                                              0.7
                                          ? const Color(0xFF1A1A1A)
                                          : category.bgColor
                                      : const Color(0xFF1A1A1A),
                                  letterSpacing: 0.1,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${category.children.length} подкатегорий',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? category.bgColor
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? category.bgColor
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThirdLevelCategorySelection(Category selectedSubcategory) {
    final thirdLevelCategories = selectedSubcategory.children;

    if (thirdLevelCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconlyBroken.category,
                  size: 32,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'В данной подкатегории нет дополнительных разделов',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedParentCategory == null || _parentCategories.isEmpty) {
      return Container();
    }

    try {
      final selectedParent = _parentCategories.firstWhere(
        (category) => category.id.toString() == _selectedParentCategory,
        orElse: () => _parentCategories.first,
      );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Детальная категория',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите наиболее точную категорию для вашего объявления',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Текущий выбор:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedParent.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Выберите точную категорию',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: thirdLevelCategories.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final thirdCategory = thirdLevelCategories[index];
                final isSelected =
                    _selectedThirdLevelCategory == thirdCategory.id.toString();

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutQuart,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedThirdLevelCategory =
                              thirdCategory.id.toString();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3366FF).withValues(alpha: 0.12)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3366FF)
                                : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF3366FF)
                                        .withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF3366FF)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF3366FF)
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                thirdCategory.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? const Color(0xFF3366FF)
                                      : const Color(0xFF1A1A1A),
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
    } catch (e) {
      print('Error in _buildThirdLevelCategorySelection: $e');
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки категорий',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildInformationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Основная информация',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Заполните детали вашего объявления',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 32),

          // Title field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Название объявления *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLength: 70,
                decoration: InputDecoration(
                  hintText: 'Краткое и точное название товара',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xff183B4E), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Description field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Описание *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText:
                      'Подробно опишите товар, его состояние и особенности',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xff183B4E), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Price field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Цена *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Укажите стоимость',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  suffixText: '₸',
                  suffixStyle: const TextStyle(
                    color: Color(0xff183B4E),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xff183B4E), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Location field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Местоположение *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _showCityBottomSheet(),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: _selectedCity != null
                              ? _selectedCity!.name
                              : 'Выберите город',
                          hintStyle: TextStyle(
                            color: _selectedCity != null
                                ? const Color(0xFF1A1A1A)
                                : Colors.grey[500],
                            fontSize: 15,
                            fontWeight: _selectedCity != null
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            IconlyBroken.location,
                            color: Color(0xff183B4E),
                            size: 20,
                          ),
                          suffixIcon: _loadingCities
                              ? Container(
                                  width: 20,
                                  height: 20,
                                  padding: const EdgeInsets.all(12),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xff183B4E),
                                  ),
                                )
                              : _selectedCity != null
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF3366FF),
                                      size: 20,
                                    )
                                  : const Icon(
                                      IconlyBroken.arrowDown2,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xff183B4E), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Address field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Адрес',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Укажите точный адрес (район, улица, дом)',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    IconlyBroken.home,
                    color: Color(0xff183B4E),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xff183B4E), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),

              // Map location button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openMapLocationPicker,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: _selectedMapLocation != null
                          ? const Color(0xFF3366FF)
                          : Colors.grey[300]!,
                      width: _selectedMapLocation != null ? 2 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: _selectedMapLocation != null
                        ? const Color(0xFF3366FF).withValues(alpha: 0.05)
                        : null,
                  ),
                  icon: Icon(
                    IconlyBroken.location,
                    color: _selectedMapLocation != null
                        ? const Color(0xFF3366FF)
                        : const Color(0xff183B4E),
                    size: 20,
                  ),
                  label: Text(
                    _selectedMapLocation != null
                        ? 'Местоположение выбрано на карте'
                        : 'Выбрать на карте',
                    style: TextStyle(
                      color: _selectedMapLocation != null
                          ? const Color(0xFF3366FF)
                          : const Color(0xff183B4E),
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              // Selected map location info
              if (_selectedMapAddress != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3366FF).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF3366FF).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        IconlyBroken.tickSquare,
                        color: Color(0xFF3366FF),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedMapAddress!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3366FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _clearMapLocation,
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFF3366FF),
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Phone number field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Номер телефона',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneFormatter],
                decoration: InputDecoration(
                  hintText: '+7 (777) 123-45-67',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    IconlyBroken.call,
                    color: Color(0xff183B4E),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xff183B4E), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // WhatsApp number field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WhatsApp номер',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                inputFormatters: [_whatsappFormatter],
                decoration: InputDecoration(
                  hintText: '+7 (777) 123-45-67',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  prefixIcon: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      IconlyBroken.message,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xff183B4E), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Ready for video demo checkbox
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Дополнительные возможности',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _readyForVideoDemo,
                  onChanged: (bool? value) {
                    setState(() {
                      _readyForVideoDemo = value ?? false;
                    });
                  },
                  title: const Text(
                    'Готов показать товар по видеозвонку',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Покупатели смогут запросить видеодемонстрацию товара',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  activeColor: const Color(0xff183B4E),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Form validation note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff183B4E).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xff183B4E).withValues(alpha: 0.1),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  IconlyBroken.infoCircle,
                  color: Color(0xff183B4E),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Поля отмеченные * обязательны для заполнения. Адрес поможет покупателям найти вас быстрее.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff183B4E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Видео товара',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте качественные видео для привлечения покупателей',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 32),

          // Video section - single video only
          if (_videos.isEmpty)
            // Add video button when no video
            InkWell(
              onTap: _addVideo,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 48,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Добавить видео',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Нажмите, чтобы выбрать видео',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Show video when uploaded
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        final double defaultHeight = 200;
                        if (_videoController != null &&
                            _videoController!.value.isInitialized) {
                          final double aspect =
                              _videoController!.value.aspectRatio;
                          final double height = width / aspect;
                          return Center(
                            child: SizedBox(
                              width: width,
                              height: height > defaultHeight
                                  ? defaultHeight
                                  : height,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: width,
                                  height: width / aspect,
                                  child: VideoPlayer(_videoController!),
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            width: width,
                            height: defaultHeight,
                            color: Colors.grey[300],
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: Color(0xff183B4E),
                                ),
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.videocam,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Загрузка...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  // Play/Pause button overlay
                  if (_videoController != null &&
                      _videoController!.value.isInitialized)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity:
                                  _videoController!.value.isPlaying ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _videoController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Video info overlay
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.videocam,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Видео',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Delete button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: InkWell(
                      onTap: () => _removeVideo(0),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // Replace button
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: InkWell(
                      onTap: _addVideo,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xff183B4E).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Заменить',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Video count info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff183B4E).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xff183B4E).withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.videocam,
                      color: Color(0xff183B4E),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _videos.isEmpty
                          ? 'Видео не загружено'
                          : 'Видео загружено',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff183B4E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Загрузите одно видео для демонстрации товара.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Video tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      IconlyBroken.star,
                      color: Colors.orange[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Советы для лучших видео',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...const [
                  '• Снимайте при хорошем освещении',
                  '• Показывайте товар с разных сторон',
                  '• Используйте стабильную съемку',
                  '• Демонстрируйте функции товара',
                ].map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                          height: 1.3,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addVideo() async {
    // If video already exists, replace it
    if (_videos.isNotEmpty) {
      _videos.clear();
      _videoFiles.clear();
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Выберите источник видео',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideo(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.videocam,
                              size: 32,
                              color: Color(0xff183B4E),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Камера',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideo(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.video_library,
                              size: 32,
                              color: Color(0xff183B4E),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Галерея',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _pickVideo(ImageSource source) async {
    try {
      XFile? video;

      if (source == ImageSource.camera) {
        // Record video with camera
        video = await _picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 2), // 2 minute max for camera
        );
      } else {
        // Pick video from gallery
        video = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5), // 5 minute max for gallery
        );
      }

      if (video != null) {
        // Clear existing video and controller if any
        if (_videoController != null) {
          await _videoController!.pause();
          await _videoController!.dispose();
          _videoController = null;
        }
        if (_videos.isNotEmpty) {
          _videos.clear();
          _videoFiles.clear();
        }

        final videoFile = File(video.path);
        final videoPath = video.path;
        setState(() {
          _videoFiles.add(videoFile);
          _videos.add(videoPath);
        });
        // Инициализация VideoPlayerController
        _videoController = VideoPlayerController.file(videoFile);
        await _videoController!.initialize();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Видео успешно загружено'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      String errorMessage;

      if (e.toString().contains('MissingPluginException')) {
        errorMessage = 'Ошибка плагина: функция недоступна на этом устройстве';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Нет разрешения на доступ к камере или галерее';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Выбор видео отменен';
      } else {
        errorMessage = 'Ошибка при выборе видео. Попробуйте еще раз.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      print('Video picker error: $e');
    }
  }

  void _removeVideo(int index) {
    setState(() {
      _videos.removeAt(index);
      if (index < _videoFiles.length) {
        _videoFiles.removeAt(index);
      }
      if (_videoController != null) {
        _videoController!.pause();
        _videoController!.dispose();
        _videoController = null;
      }
    });
  }

  Widget _buildParametersForm() {
    if (_loadingParameters) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xff183B4E).withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff183B4E),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Загружаем параметры',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_parametersError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _parametersError!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_finalSelectedCategoryId != null) {
                    _fetchParameters(_finalSelectedCategoryId!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff183B4E),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_categoryParameters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF3366FF).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconlyBroken.tickSquare,
                  size: 32,
                  color: Color(0xFF3366FF),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Дополнительные параметры не требуются',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Для данной категории нет специальных параметров',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Дополнительные параметры',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Заполните специфичные характеристики для вашей категории',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 32),

          // Parameters list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categoryParameters.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final parameter = _categoryParameters[index];
              return _buildParameterField(parameter);
            },
          ),

          const SizedBox(height: 40),

          // Required fields note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff183B4E).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xff183B4E).withValues(alpha: 0.1),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  IconlyBroken.infoCircle,
                  color: Color(0xff183B4E),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Заполнение дополнительных параметров поможет покупателям быстрее найти ваш товар',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff183B4E),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterField(Parameter parameter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              parameter.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (parameter.isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        if (parameter.type == 'text')
          _buildTextParameter(parameter)
        else if (parameter.type == 'number')
          _buildNumberParameter(parameter)
        else if (parameter.type == 'select')
          _buildSelectParameter(parameter)
        else if (parameter.type == 'checkbox')
          _buildCheckboxParameter(parameter)
        else
          _buildTextParameter(parameter), // Default fallback
      ],
    );
  }

  Widget _buildTextParameter(Parameter parameter) {
    return TextFormField(
      initialValue: parameter.value,
      onChanged: (value) {
        setState(() {
          parameter.value = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Введите ${parameter.name.toLowerCase()}',
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 15,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff183B4E), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildNumberParameter(Parameter parameter) {
    return TextFormField(
      initialValue: parameter.value,
      keyboardType: TextInputType.number,
      onChanged: (value) {
        setState(() {
          parameter.value = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Введите число',
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 15,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff183B4E), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildSelectParameter(Parameter parameter) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonFormField<String>(
        value: parameter.value,
        onChanged: (value) {
          setState(() {
            parameter.value = value;
          });
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        hint: Text(
          'Выберите ${parameter.name.toLowerCase()}',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1A1A1A),
        ),
        items: parameter.options?.map((option) {
              return DropdownMenuItem<String>(
                value: option.value,
                child: Text(option.label),
              );
            }).toList() ??
            [],
      ),
    );
  }

  Widget _buildCheckboxParameter(Parameter parameter) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: parameter.options?.map((option) {
              // For checkbox parameters, we store multiple values as comma-separated string
              final currentValues = parameter.value?.split(',') ?? [];
              final isSelected = currentValues.contains(option.value);

              return CheckboxListTile(
                title: Text(
                  option.label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                value: isSelected,
                activeColor: const Color(0xff183B4E),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      if (!isSelected) {
                        currentValues.add(option.value);
                      }
                    } else {
                      currentValues.remove(option.value);
                    }
                    parameter.value = currentValues.join(',');
                  });
                },
              );
            }).toList() ??
            [],
      ),
    );
  }

  Widget _buildPublicationPriceSelection() {
    if (_loadingPublicationPrices) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xff183B4E).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xff183B4E)),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Загружаем тарифы публикации',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_publicationPricesError != null || _publicationPrices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconlyBroken.closeSquare,
                  size: 36,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _publicationPricesError ?? 'Тарифы публикации не найдены',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchPublicationPrices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff183B4E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите тариф публикации',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите подходящий тариф для размещения вашего объявления',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 32),

          // Publication prices list
          ..._publicationPrices.asMap().entries.map((entry) {
            final index = entry.key;
            final price = entry.value;
            return Column(
              children: [
                if (index > 0)
                  const SizedBox(height: 12), // Уменьшили с 16 до 12
                _buildPublicationPriceCard(price),
              ],
            );
          }).toList(),

          const SizedBox(height: 32),

          // Info container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff183B4E).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xff183B4E).withValues(alpha: 0.1),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  IconlyBroken.infoSquare,
                  size: 20,
                  color: Color(0xff183B4E),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Выбранный тариф определяет длительность размещения и дополнительные возможности вашего объявления',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff183B4E),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicationPriceCard(PublicationPrice price) {
    final isSelected = _selectedPublicationPrice?.id == price.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPublicationPrice = price;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16), // Уменьшили с 20 до 16
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Уменьшили с 16 до 12
          border: Border.all(
            color: isSelected ? const Color(0xff183B4E) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xff183B4E).withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 15 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя часть - только название и длительность
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            price.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? const Color(0xff183B4E)
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price.durationText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Только иконка выбора справа
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xff183B4E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Описание
            Text(
              price.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.2,
              ),
            ),
            // Особенности
            if (price.features != null) ...[
              const SizedBox(height: 12),
              ...price.features!.entries
                  .take(3)
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: isSelected
                                  ? const Color(0xff183B4E)
                                  : Colors.grey[400],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
            // Цена внизу
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Стоимость:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  price.formattedPrice,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? const Color(0xff183B4E)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            // Минималистичная кнопка "Назад"
            InkWell(
              onTap: () {
                setState(() {
                  _currentStep--;
                  _fadeController.reset();
                  _fadeController.forward();
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      IconlyBroken.arrowLeft,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Назад',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Минималистичная кнопка "Далее"
          Expanded(
            child: InkWell(
              onTap: _canProceed() ? _handleNext : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _canProceed()
                      ? const Color(0xff183B4E)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getNextButtonText(),
                      style: TextStyle(
                        color: _canProceed() ? Colors.white : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      IconlyBroken.arrowRight,
                      size: 14,
                      color: _canProceed() ? Colors.white : Colors.grey[500],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedParentCategory != null && !_isLoading;
      case 1:
        if (_selectedParentCategory != null && _parentCategories.isNotEmpty) {
          try {
            final selectedParent = _parentCategories.firstWhere(
              (category) => category.id.toString() == _selectedParentCategory,
              orElse: () => _parentCategories.first,
            );

            if (selectedParent.children.isEmpty) {
              return true;
            }

            return _selectedSubCategory != null;
          } catch (e) {
            print('Error in _canProceed case 1: $e');
            return false;
          }
        }
        return false;
      case 2:
        if (_selectedSubCategory != null && _selectedParentCategory != null && _parentCategories.isNotEmpty) {
          try {
            final selectedParent = _parentCategories.firstWhere(
              (category) => category.id.toString() == _selectedParentCategory,
              orElse: () => _parentCategories.first,
            );

            final selectedSubcategory = selectedParent.children.firstWhere(
              (subcat) => subcat.id.toString() == _selectedSubCategory,
            );

            if (selectedSubcategory.children.isNotEmpty) {
              return _selectedThirdLevelCategory != null;
            }
            return true;
          } catch (e) {
            print('Error in _canProceed case 2: $e');
            return false;
          }
        }
        return false;
      case 3:
        // Information form validation
        return _titleController.text.trim().isNotEmpty &&
            _descController.text.trim().isNotEmpty &&
            _priceController.text.trim().isNotEmpty &&
            _selectedCity != null;
      case 4:
        // Video selection - at least one video required
        return _videos.isNotEmpty;
      case 5:
        // Parameters form validation - check required parameters
        return _validateParameters();
      case 6:
        // Publication price selection
        return _selectedPublicationPrice != null && !_loadingPublicationPrices;
      default:
        return true;
    }
  }

  bool _validateParameters() {
    if (_loadingParameters || _parametersError != null) {
      return false;
    }

    // Check if all required parameters are filled
    for (Parameter parameter in _categoryParameters) {
      if (parameter.isRequired &&
          (parameter.value == null || parameter.value!.trim().isEmpty)) {
        return false;
      }
    }

    return true;
  }

  String _getNextButtonText() {
    if (_currentStep == 6) {
      return 'Опубликовать';
    }
    return 'Далее';
  }

  void _handleNext() {
    if (_currentStep == 6) {
      // Final step - publish the ad
      _publishAd();
      return;
    }

    if (_currentStep == 0) {
      if (_selectedParentCategory != null && _parentCategories.isNotEmpty) {
        try {
          final selectedParent = _parentCategories.firstWhere(
            (category) => category.id.toString() == _selectedParentCategory,
            orElse: () => _parentCategories.first,
          );

          if (selectedParent.children.isEmpty) {
            setState(() {
              _currentStep = 3;
              _fadeController.reset();
              _fadeController.forward();
            });
            return;
          }
        } catch (e) {
          print('Error in _handleNext case 0: $e');
        }
      }
    }

    if (_currentStep == 1) {
      if (_selectedSubCategory != null && _selectedParentCategory != null && _parentCategories.isNotEmpty) {
        try {
          final selectedParent = _parentCategories.firstWhere(
            (category) => category.id.toString() == _selectedParentCategory,
            orElse: () => _parentCategories.first,
          );

          final selectedSubcategory = selectedParent.children.firstWhere(
            (subcat) => subcat.id.toString() == _selectedSubCategory,
          );

          if (selectedSubcategory.children.isEmpty) {
            setState(() {
              _currentStep = 3;
              _fadeController.reset();
              _fadeController.forward();
            });
            return;
          }
        } catch (e) {
          print('Error in navigation: $e');
        }
      }
    }

    // Load parameters when reaching step 5
    if (_currentStep == 4) {
      if (_finalSelectedCategoryId != null) {
        _fetchParameters(_finalSelectedCategoryId!);
      }
    }

    // Load publication prices when reaching step 6
    if (_currentStep == 5) {
      _fetchPublicationPrices();
    }

    setState(() {
      _currentStep++;
      _fadeController.reset();
      _fadeController.forward();
    });
  }

  Future<void> _publishAd() async {
    // Create progress stream controller
    final StreamController<int> progressController = StreamController<int>.broadcast();

    // Show loading dialog with progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StreamBuilder<int>(
          stream: progressController.stream,
          initialData: 0,
          builder: (context, snapshot) {
            final progress = snapshot.data ?? 0;
            
            String message;
            if (progress < 30) {
              message = 'Подготавливаем данные...';
            } else if (progress < 70) {
              message = 'Загружаем видео...';
            } else if (progress < 90) {
              message = 'Создаем объявление...';
            } else {
              message = 'Завершаем публикацию...';
            }

            return Dialog(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xff183B4E).withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress / 100.0,
                              color: const Color(0xff183B4E),
                              strokeWidth: 2.5,
                              backgroundColor: Colors.grey[200],
                            ),
                            Text(
                              '$progress%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff183B4E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Публикуем объявление',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Start progress updates
    
    // Function to update progress
    void updateProgress(int progress) {
      if (!progressController.isClosed) {
        progressController.add(progress);
      }
    }

    try {
      // Initial progress
      updateProgress(10);
      await Future.delayed(const Duration(milliseconds: 300));
      // Prepare parameters for API
      updateProgress(25);
      await Future.delayed(const Duration(milliseconds: 200));
      
      final parameters = _categoryParameters
          .where((param) => param.value != null && param.value!.isNotEmpty)
          .map((param) => {
                'parameter_id': param.id,
                'value': param.value!,
              })
          .toList();

      // Start uploading
      updateProgress(40);
      await Future.delayed(const Duration(milliseconds: 300));

      // Call API to create product
      updateProgress(60);
      final result = await _productService.createProduct(
        categoryId: _finalSelectedCategoryId!,
        cityId: _selectedCity!.id.toString(),
        name: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: _priceController.text.trim(),
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : _selectedMapAddress ?? '',
        videoFile: _videoFiles.isNotEmpty ? _videoFiles.first : null,
        isVideoCallAvailable: _readyForVideoDemo,
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _getCleanPhoneNumber(_phoneController.text.trim())
            : null,
        whatsappNumber: _whatsappController.text.trim().isNotEmpty
            ? _getCleanPhoneNumber(_whatsappController.text.trim())
            : null,
        readyForVideoDemo: _readyForVideoDemo,
        parameters: parameters.isNotEmpty ? parameters : null,
        publicationPriceId: _selectedPublicationPrice?.id,
      );

      print('Product created successfully: $result');

      // Complete progress
      updateProgress(90);
      await Future.delayed(const Duration(milliseconds: 300));
      
      updateProgress(100);
      await Future.delayed(const Duration(milliseconds: 500));

      // Close progress stream
      if (!progressController.isClosed) {
        progressController.close();
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success dialog
      _showSuccessDialog();
    } catch (e) {
      // Close progress stream
      if (!progressController.isClosed) {
        progressController.close();
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error dialog
      String errorMessage = 'Ошибка при публикации объявления';
      if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      _showErrorDialog(errorMessage);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3366FF).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    IconlyBroken.tickSquare,
                    size: 40,
                    color: Color(0xFF3366FF),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Объявление опубликовано!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Ваше объявление успешно размещено и теперь доступно другим пользователям.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          _resetForm();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Создать еще',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          _goToHome();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff183B4E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'На главную',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ошибка публикации',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff183B4E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Попробовать снова',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _selectedParentCategory = null;
      _selectedSubCategory = null;
      _selectedThirdLevelCategory = null;
      _titleController.clear();
      _descController.clear();
      _priceController.clear();
      _locationController.clear();
      _addressController.clear();
      _phoneController.clear();
      _whatsappController.clear();
      _readyForVideoDemo = false;
      _videos.clear();
      _videoFiles.clear();
      _categoryParameters.clear();
      _loadingParameters = false;
      _parametersError = null;
      _selectedCity = null;
      _selectedMapLocation = null;
      _selectedMapAddress = null;
    });
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) => const NavigationMenu(initialIndex: 0)),
      (route) => false,
    );
  }

  void _handleExit() {
    setState(() {
      _currentStep = 0;
      _selectedParentCategory = null;
      _selectedSubCategory = null;
      _selectedThirdLevelCategory = null;
    });

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => const NavigationMenu(initialIndex: 0)),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
    }
    // Cancel any ongoing video compression
    VideoCompressionHelper.cancelCompression();
    super.dispose();
  }
}
