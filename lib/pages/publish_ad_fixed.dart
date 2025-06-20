import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import '../models/category.dart';
import '../models/parameter.dart';
import '../services/category_service.dart';
import '../services/parameter_service.dart';
import '../navigation.dart';

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
  List<String> _images = [];
  
  // Parameters for the last step (if applicable)
  List<Parameter> _categoryParameters = [];
  bool _loadingParameters = false;
  String? _parametersError;

  // API Integration
  final CategoryService _categoryService = CategoryService();
  final ParameterService _parameterService = ParameterService();
  List<Category> _parentCategories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    
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
                  color: selectedParent.bgColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Подкатегории',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selectedParent.bgColor,
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
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selectedParent.bgColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Icon(
                    IconlyBroken.arrowDown2,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selectedParent.bgColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedSubcategory.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: selectedParent.bgColor,
                      ),
                    ),
                  ],
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
                    color: selectedParent.bgColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Выберите точную категорию',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedParent.bgColor,
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
                          color: isSelected ? selectedParent.bgColor.withOpacity(0.07) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? selectedParent.bgColor : Colors.grey[200]!,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: selectedParent.bgColor.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ] : null,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isSelected ? selectedParent.bgColor : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? selectedParent.bgColor : Colors.grey[400]!,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                thirdCategory.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                  color: isSelected ? selectedParent.bgColor : Colors.black87,
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
    return const Center(child: Text('Information Form - TODO'));
  }

  Widget _buildPhotoSelection() {
    return const Center(child: Text('Photo Selection - TODO'));
  }

  Widget _buildParametersForm() {
    return const Center(child: Text('Parameters Form - TODO'));
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
      default:
        return true;
    }
  }

  String _getNextButtonText() {
    return 'Далее';
  }

  void _handleNext() {
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
    
    setState(() {
      _currentStep++;
      _fadeController.reset();
      _fadeController.forward();
    });
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
    super.dispose();
  }
}
