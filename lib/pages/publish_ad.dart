import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/category.dart';
import '../models/parameter.dart';
import '../models/city.dart';
import '../services/category_service.dart';
import '../services/parameter_service.dart';
import '../services/city_service.dart';
import '../navigation.dart';
import 'map_location_picker.dart';

class PublishAdPage extends StatefulWidget {
  const PublishAdPage({super.key});

  @override
  State<PublishAdPage> createState() => _PublishAdPageState();
}

class _PublishAdPageState extends State<PublishAdPage> with TickerProviderStateMixin {
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
  List<String> _images = [];
  List<File> _imageFiles = []; // For storing actual image files
  final ImagePicker _picker = ImagePicker();
  
  // Parameters for the last step (if applicable)
  List<Parameter> _categoryParameters = [];
  bool _loadingParameters = false;
  String? _parametersError;

  // API Integration
  final CategoryService _categoryService = CategoryService();
  final ParameterService _parameterService = ParameterService();
  final CityService _cityService = CityService();
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

      final parameters = await _parameterService.getCategoryParameters(categoryId);

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
                  filteredCities = _cities.where((city) =>
                    city.name.toLowerCase().contains(query.toLowerCase())
                  ).toList();
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
                              horizontal: 16, 
                              vertical: 16
                            ),
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
                                    backgroundColor: const Color(0xff183B4E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24, 
                                      vertical: 12
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredCities.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey[100],
                            ),
                            itemBuilder: (context, index) {
                              final city = filteredCities[index];
                              final isSelected = _selectedCity?.id == city.id;
                              
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? const Color(0xFF3366FF).withOpacity(0.1)
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
        if (_addressController.text.trim().isEmpty && _selectedMapAddress != null) {
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
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        if (_currentStep > 0) {
          setState(() {
            _currentStep--;
          });
          return false;
        }
        _handleExit();
        return false;
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
            _buildBottomNavigation(),
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
        return 'Фотографии';
      case 5:
        return 'Параметры';
      default:
        return 'Публикация';
    }
  }

  Widget _buildStepContent() {
    _fadeController.reset();
    _fadeController.forward();
    
    switch (_currentStep) {
      case 0:
        return _buildCategorySelection();
      case 1:
        return _buildSubCategorySelection();
      case 2:
        // Dedicated step for 3rd level category selection
        if (_selectedSubCategory != null) {
          final selectedParent = _parentCategories.firstWhere(
            (category) => category.id.toString() == _selectedParentCategory,
            orElse: () => _parentCategories.first,
          );
          
          try {
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
        return _buildPhotoSelection();
      case 5:
        return _buildParametersForm();
      default:
        return _buildCategorySelection();
    }
  }

  Widget _buildSubCategorySelection() {
    if (_selectedParentCategory == null) return Container();
    
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
              Text(
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
                final isSelected = _selectedSubCategory == subcategory.id.toString();
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
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF3366FF).withOpacity(0.12) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF3366FF) : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: const Color(0xFF3366FF).withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ] : null,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF3366FF) : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF3366FF) : Colors.grey[400]!,
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
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? const Color(0xFF3366FF) : const Color(0xFF1A1A1A),
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
                                  color: isSelected ? const Color(0xFF3366FF) : Colors.grey[500],
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
                  color: const Color(0xff183B4E).withOpacity(0.06),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
              final isSelected = _selectedParentCategory == category.id.toString();
              
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
                  splashColor: category.bgColor.withOpacity(0.08),
                  highlightColor: category.bgColor.withOpacity(0.04),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? category.bgColor.withOpacity(0.06)
                          : Colors.grey[50]?.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected 
                            ? category.bgColor.withOpacity(0.4)
                            : Colors.grey[200]!.withOpacity(0.6),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: category.bgColor.withOpacity(0.12),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        )
                      ] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
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
                                color: (isSelected ? category.bgColor : Colors.grey[300]!)
                                    .withOpacity(0.25),
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
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.category_outlined,
                                          color: isSelected ? Colors.white : Colors.grey[500],
                                          size: 28,
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.category_outlined,
                                    color: isSelected ? Colors.white : Colors.grey[500],
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
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected 
                                      ? category.bgColor.computeLuminance() > 0.7 
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
                Text(
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
                final isSelected = _selectedThirdLevelCategory == thirdCategory.id.toString();
                
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
                          _selectedThirdLevelCategory = thirdCategory.id.toString();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF3366FF).withOpacity(0.12) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF3366FF) : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: const Color(0xFF3366FF).withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ] : null,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF3366FF) : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF3366FF) : Colors.grey[400]!,
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
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? const Color(0xFF3366FF) : const Color(0xFF1A1A1A),
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
                    borderSide: const BorderSide(color: Color(0xff183B4E), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  hintText: 'Подробно опишите товар, его состояние и особенности',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    borderSide: const BorderSide(color: Color(0xff183B4E), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            borderSide: const BorderSide(color: Color(0xff183B4E), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    borderSide: const BorderSide(color: Color(0xff183B4E), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      ? const Color(0xFF3366FF).withOpacity(0.05) 
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
                    color: const Color(0xFF3366FF).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF3366FF).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        IconlyBroken.tickSquare,
                        color: const Color(0xFF3366FF),
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
          
          const SizedBox(height: 40),
          
          // Form validation note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff183B4E).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xff183B4E).withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  IconlyBroken.infoCircle,
                  color: const Color(0xff183B4E),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Поля отмеченные * обязательны для заполнения. Адрес поможет покупателям найти вас быстрее.',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xff183B4E),
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

  Widget _buildPhotoSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фотографии товара',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте качественные фото для привлечения покупателей',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 32),
          
          // Photo grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _images.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              if (index == _images.length) {
                // Add photo button
                return InkWell(
                  onTap: _addPhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
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
                          IconlyBroken.camera,
                          size: 32,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Добавить\nфото',
                          textAlign: TextAlign.center,
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
              } else {
                // Photo item
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: index < _imageFiles.length
                            ? Image.file(
                                _imageFiles[index],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      IconlyBroken.image,
                                      size: 32,
                                      color: Colors.grey[500],
                                    ),
                                  );
                                },
                              )
                            : Image.network(
                                _images[index],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      IconlyBroken.image,
                                      size: 32,
                                      color: Colors.grey[500],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    // Delete button
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: () => _removePhoto(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    // Main photo indicator
                    if (index == 0)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xff183B4E).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Главное',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
            },
          ),
          
          const SizedBox(height: 24),
          
          // Photo count info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff183B4E).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xff183B4E).withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      IconlyBroken.image,
                      color: const Color(0xff183B4E),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Фотографии (${_images.length}/10)',
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
                  'Первое фото будет главным в объявлении. Вы можете добавить до 10 фотографий.',
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
          
          // Photo tips
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
                      'Советы для лучших фото',
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
                  '• Избегайте размытых изображений',
                  '• Демонстрируйте все дефекты честно',
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
  
  void _addPhoto() async {
    if (_images.length >= 10) return;
    
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
                'Выберите источник фото',
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
                        _pickImage(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              IconlyBroken.camera,
                              size: 32,
                              color: const Color(0xff183B4E),
                            ),
                            const SizedBox(height: 8),
                            const Text(
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
                        _pickImage(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              IconlyBroken.image,
                              size: 32,
                              color: const Color(0xff183B4E),
                            ),
                            const SizedBox(height: 8),
                            const Text(
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
  
  void _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imageFiles.add(File(image.path));
          _images.add(image.path); // For display purposes
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при выборе изображения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _removePhoto(int index) {
    setState(() {
      _images.removeAt(index);
      if (index < _imageFiles.length) {
        _imageFiles.removeAt(index);
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
                  color: const Color(0xff183B4E).withOpacity(0.06),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
                  color: const Color(0xFF3366FF).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconlyBroken.tickSquare,
                  size: 32,
                  color: const Color(0xFF3366FF),
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
              color: const Color(0xff183B4E).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xff183B4E).withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  IconlyBroken.infoCircle,
                  color: const Color(0xff183B4E),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Заполнение дополнительных параметров поможет покупателям быстрее найти ваш товар',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xff183B4E),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        }).toList() ?? [],
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
        }).toList() ?? [],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                        _fadeController.reset();
                        _fadeController.forward();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: const Color(0xff183B4E).withOpacity(0.5),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconlyBroken.arrowLeft,
                          size: 16,
                          color: Color(0xff183B4E),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Назад',
                          style: TextStyle(
                            color: Color(0xff183B4E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _canProceed() ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff183B4E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getNextButtonText(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        IconlyBroken.arrowRight,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
        if (_selectedParentCategory != null) {
          final selectedParent = _parentCategories.firstWhere(
            (category) => category.id.toString() == _selectedParentCategory,
            orElse: () => _parentCategories.first,
          );
          
          if (selectedParent.children.isEmpty) {
            return true;
          }
          
          return _selectedSubCategory != null;
        }
        return false;
      case 2:
        if (_selectedSubCategory != null) {
          final selectedParent = _parentCategories.firstWhere(
            (category) => category.id.toString() == _selectedParentCategory,
            orElse: () => _parentCategories.first,
          );
          
          try {
            final selectedSubcategory = selectedParent.children.firstWhere(
              (subcat) => subcat.id.toString() == _selectedSubCategory,
            );
            
            if (selectedSubcategory.children.isNotEmpty) {
              return _selectedThirdLevelCategory != null;
            }
            
            return true;
          } catch (e) {
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
        // Photo selection - at least one photo required
        return _images.isNotEmpty;
      case 5:
        // Parameters form validation - check required parameters
        return _validateParameters();
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
      if (parameter.isRequired && (parameter.value == null || parameter.value!.trim().isEmpty)) {
        return false;
      }
    }
    
    return true;
  }

  String _getNextButtonText() {
    if (_currentStep == 5) {
      return 'Опубликовать';
    }
    return 'Далее';
  }

  void _handleNext() {
    if (_currentStep == 5) {
      // Final step - publish the ad
      _publishAd();
      return;
    }
    
    if (_currentStep == 0) {
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
    }
    
    if (_currentStep == 1) {
      if (_selectedSubCategory != null) {
        final selectedParent = _parentCategories.firstWhere(
          (category) => category.id.toString() == _selectedParentCategory,
          orElse: () => _parentCategories.first,
        );
        
        try {
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
    
    setState(() {
      _currentStep++;
      _fadeController.reset();
      _fadeController.forward();
    });
  }

  Future<void> _publishAd() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xff183B4E).withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff183B4E),
                      strokeWidth: 2.5,
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
                  'Пожалуйста, подождите...',
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

    try {
      // Prepare ad data
      final adData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'city_id': _selectedCity?.id,
        'city_name': _selectedCity?.name,
        'region_id': _selectedCity?.region?.id,
        'address': _addressController.text.trim().isNotEmpty 
            ? _addressController.text.trim() 
            : _selectedMapAddress ?? '',
        'location_coordinates': _selectedMapLocation != null 
            ? {
                'latitude': _selectedMapLocation!['latitude'],
                'longitude': _selectedMapLocation!['longitude'],
              } 
            : null,
        'category_id': _finalSelectedCategoryId,
        'images': _images,
        'parameters': _categoryParameters
            .where((param) => param.value != null && param.value!.isNotEmpty)
            .map((param) => {
                  'parameter_id': param.id,
                  'value': param.value,
                })
            .toList(),
      };

      // TODO: Replace with actual API call
      print('Publishing ad with data: $adData'); // Debug log
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show success dialog
      _showSuccessDialog();
      
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error dialog
      _showErrorDialog('Ошибка при публикации объявления: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3366FF).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconlyBroken.tickSquare,
                    size: 40,
                    color: const Color(0xFF3366FF),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      _images.clear();
      _imageFiles.clear();
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
      MaterialPageRoute(builder: (context) => const NavigationMenu(initialIndex: 0)),
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
        MaterialPageRoute(builder: (context) => const NavigationMenu(initialIndex: 0)),
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
    super.dispose();
  }
}
