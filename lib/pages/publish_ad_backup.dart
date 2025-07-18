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
  
  // Build the parameters form based on the category
  Widget _buildParametersForm() {
    if (_finalSelectedCategoryId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Пожалуйста, сначала выберите категорию',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (_loadingParameters) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xff183B4E),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Загрузка параметров...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    if (_parametersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
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
            const SizedBox(height: 8),
            Text(
              'Пожалуйста, повторите попытку',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _fetchParameters(_finalSelectedCategoryId!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff183B4E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'Повторить',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Colors.blue[400],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Для данной категории нет дополнительных параметров',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Вы можете продолжить публикацию объявления',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green[400],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Нажмите "Опубликовать" для продолжения',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Дополнительные параметры',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Укажите дополнительную информацию о товаре',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 24),
          
          // Required parameters section
          if (_categoryParameters.any((p) => p.isRequired)) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50]!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[100]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.priority_high_rounded,
                        size: 18,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Обязательные параметры',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ...List.generate(
                    _categoryParameters.where((p) => p.isRequired).length,
                    (index) {
                      final parameter = _categoryParameters
                          .where((p) => p.isRequired)
                          .elementAt(index);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parameter.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildParameterInput(parameter),
                          if (index < _categoryParameters.where((p) => p.isRequired).length - 1)
                            const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Optional parameters
          if (_categoryParameters.any((p) => !p.isRequired)) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Дополнительная информация',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ...List.generate(
                    _categoryParameters.where((p) => !p.isRequired).length,
                    (index) {
                      final parameter = _categoryParameters
                          .where((p) => !p.isRequired)
                          .elementAt(index);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parameter.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildParameterInput(parameter),
                          if (index < _categoryParameters.where((p) => !p.isRequired).length - 1)
                            const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Build the input widget based on parameter type
  Widget _buildParameterInput(Parameter parameter) {
    switch (parameter.type) {
      case 'text':
      case 'number':
        return TextFormField(
          keyboardType: parameter.type == 'number'
              ? TextInputType.number
              : TextInputType.text,
          initialValue: parameter.value,
          onChanged: (value) {
            setState(() {
              parameter.value = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Введите ${parameter.name.toLowerCase()}',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0, 
              horizontal: 16.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: const Color(0xff183B4E).withOpacity(0.6),
                width: 1.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: Colors.red.withOpacity(0.6),
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: Colors.red.withOpacity(0.8),
                width: 1.5,
              ),
            ),
            errorText: parameter.isRequired && 
                     (parameter.value == null || parameter.value!.isEmpty) ? 
                     'Обязательное поле' : null,
            errorStyle: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
        
      case 'select':
        if (parameter.options == null || parameter.options!.isEmpty) {
          return const SizedBox();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: parameter.isRequired && (parameter.value == null || parameter.value!.isEmpty) ?
                  Border.all(color: Colors.red.withOpacity(0.6), width: 1.0) :
                  null,
          ),
          child: DropdownButtonFormField<String>(
            value: parameter.value,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              errorText: parameter.isRequired && 
                       (parameter.value == null || parameter.value!.isEmpty) ? 
                       'Обязательное поле' : null,
              errorStyle: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: parameter.isRequired && (parameter.value == null || parameter.value!.isEmpty) ?
                    Colors.red :
                    const Color(0xFF2C2C2C),
              size: 20,
            ),
            isExpanded: true,
            hint: Text(
              'Выберите ${parameter.name.toLowerCase()}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF2C2C2C),
              fontSize: 15,
            ),
            items: parameter.options!.map((ParameterOption option) {
              return DropdownMenuItem<String>(
                value: option.value,
                child: Text(option.label),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                parameter.value = newValue;
              });
            },
          ),
        );
        
      case 'checkbox':
        return CheckboxListTile(
          title: Text(
            parameter.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          value: parameter.value == 'true',
          activeColor: const Color(0xff183B4E),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (bool? newValue) {
            setState(() {
              parameter.value = newValue.toString();
            });
          },
        );
        
      default:
        return const SizedBox();
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
                // If we're in a sub-step, go back to previous step
                setState(() {
                  _currentStep--;
                });
              } else {
                // Handle exiting the form properly to avoid black screen
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
            // Step content with fade transition
            Expanded(
              child: FadeTransition(
                opacity: _fadeController,
                child: _buildStepContent(),
              ),
            ),
            
            // Bottom navigation
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
        return 'Уточните выбор'; // Always show this title for the 3rd level step
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
    // Before changing step, trigger animation
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
        return Container();  // Empty container as fallback
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

    if (_errorMessage != null) {
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
                _errorMessage!,
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
                label: const Text(
                  'Повторить',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_parentCategories.isEmpty) {
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
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.category_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Категории не найдены',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
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
          // Minimalist header section
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
          
          // Clean list design
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
                      // Reset subcategory and third level when changing parent category
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
                        // Icon container with improved design
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
                        
                        // Text content
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
                        
                        // Selection indicator
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
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSubCategorySelection() {
    if (_selectedParentCategory == null) return Container();
    
    // Find the selected parent category
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
              const SizedBox(height: 8),
              Text(
                'Вы можете продолжить без выбора подкатегории',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
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
          
          // 2nd level category header with minimalist design
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
          
          // 2nd level categories list - takes full space
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
                          _selectedThirdLevelCategory = null; // Reset 3rd level selection when changing 2nd level
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? selectedParent.bgColor.withOpacity(0.08) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? selectedParent.bgColor : Colors.grey[200]!,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: selectedParent.bgColor.withOpacity(0.1),
                              blurRadius: 6,
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
                                subcategory.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                  color: isSelected ? selectedParent.bgColor : const Color(0xFF1A1A1A),
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
                                  color: isSelected ? selectedParent.bgColor : Colors.grey[500],
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
              const SizedBox(height: 8),
              Text(
                'Вы можете продолжить без выбора',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Get the parent category for consistent styling
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
          
          // Category selection path (breadcrumbs)
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
                // First level (parent category)
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
                // Arrow down
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Icon(
                    IconlyBroken.arrowDown2,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ),
                // Second level (subcategory)
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
          
          // Title for 3rd level choices
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
          
          // 3rd level category list with improved styling
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Информация о товаре',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Заполните основную информацию',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 36),
          
          // Title field
          _buildTextField(
            label: 'Заголовок',
            controller: _titleController,
            hint: 'Например, "Продам iPhone 14 Pro"',
          ),
          
          const SizedBox(height: 24),
          
          // Description field
          _buildTextField(
            label: 'Описание',
            controller: _descController,
            hint: 'Подробно опишите товар или услугу',
            maxLines: 4,
          ),
          
          const SizedBox(height: 24),
          
          // Price field
          _buildTextField(
            label: 'Цена',
            controller: _priceController,
            hint: 'Укажите цену в ₸',
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 24),
          
          // Location field
          _buildTextField(
            label: 'Местоположение',
            controller: _locationController,
            hint: 'Город, район',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2C),
              letterSpacing: 0.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1A1A1A),
            letterSpacing: 0.1,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16.0, 
              horizontal: 16.0
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: const Color(0xff183B4E).withOpacity(0.6),
                width: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Добавьте фотографии',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте до 10 фотографий товара',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 28),
          
          // Photo grid with improved minimal design
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _images.length + 1,
              itemBuilder: (context, index) {
                if (index == _images.length) {
                  // Add photo button with minimalist design
                  return GestureDetector(
                    onTap: () {
                      // TODO: Implement image picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Функция добавления фото в разработке'),
                          backgroundColor: const Color(0xff183B4E),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(milliseconds: 1800),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xff183B4E).withOpacity(0.15),
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xff183B4E).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 22,
                              color: Color(0xff183B4E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Добавить фото',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff183B4E),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Photo item with minimalist design
                return Stack(
                  children: [
                    Hero(
                      tag: 'photo_${_images[index]}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(_images[index]),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // Show photo in fullscreen view
                                // TODO: Implement fullscreen photo view
                              },
                              splashColor: Colors.white.withOpacity(0.1),
                              highlightColor: Colors.white.withOpacity(0.1),
                              child: Container(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Subtle gradient overlay
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                            ],
                            stops: const [0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Delete button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _images.removeAt(index);
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
          // Minimalist divider
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconlyBroken.arrowLeft,
                          size: 16,
                          color: const Color(0xff183B4E).withOpacity(0.8),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Назад',
                          style: TextStyle(
                            color: Color(0xff183B4E),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            fontSize: 15,
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
                    shadowColor: const Color(0xff183B4E).withOpacity(0.3),
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
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == 3 ? Icons.check_circle_outline : IconlyBroken.arrowRight,
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
        // Can proceed if subcategory is selected
        if (_selectedParentCategory != null) {
          final selectedParent = _parentCategories.firstWhere(
            (category) => category.id.toString() == _selectedParentCategory,
            orElse: () => _parentCategories.first,
          );
          
          // If no subcategories at all, can proceed
          if (selectedParent.children.isEmpty) {
            return true;
          }
          
          // Must select a subcategory to proceed
          return _selectedSubCategory != null;
        }
        return false;
        
      case 2:
        // For dedicated 3rd level category step
        if (_selectedSubCategory != null) {
          final selectedParent = _parentCategories.firstWhere(
            (category) => category.id.toString() == _selectedParentCategory,
            orElse: () => _parentCategories.first,
          );
          
          try {
            final selectedSubcategory = selectedParent.children.firstWhere(
              (subcat) => subcat.id.toString() == _selectedSubCategory,
            );
            
            // If has 3rd level categories, require selection
            if (selectedSubcategory.children.isNotEmpty) {
              return _selectedThirdLevelCategory != null;
            }
            
            // If no 3rd level categories, can always proceed
            return true;
          } catch (e) {
            return false;
          }
        }
        return false;
        
      case 3:
        return _titleController.text.isNotEmpty &&
               _descController.text.isNotEmpty &&
               _priceController.text.isNotEmpty;
               
      case 4:
        return true; // Photos are optional
        
      case 5:
        // Check if all required parameters have values
        if (_loadingParameters) return false;
        
        if (_categoryParameters.isEmpty) return true; // No parameters to fill
        
        // Check if all required parameters have values
        bool allRequiredParametersFilled = _categoryParameters
          .where((param) => param.isRequired)
          .every((param) => param.value != null && param.value!.isNotEmpty);
          
        return allRequiredParametersFilled;
        
      default:
        return false;
    }
  }

  String _getNextButtonText() {
    if (_currentStep == 4) {
      return 'Опубликовать';
    }
    
    if (_currentStep == 1 && _selectedParentCategory != null) {
      final selectedParent = _parentCategories.firstWhere(
        (category) => category.id.toString() == _selectedParentCategory,
        orElse: () => _parentCategories.first,
      );
      
      if (selectedParent.children.isEmpty) {
        return 'Пропустить';
      }
    }
    
    return 'Далее';
  }

  void _handleNext() {
    if (_currentStep == 5) {
      // Validate all parameters one last time
      bool canSubmit = true;
      String errorMessage = '';
      
      for (var param in _categoryParameters.where((p) => p.isRequired)) {
        if (param.value == null || param.value!.isEmpty) {
          canSubmit = false;
          errorMessage = 'Пожалуйста, заполните все обязательные поля';
          break;
        }
      }
      
      if (!canSubmit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }
      
      // Prepare data for submission
      final Map<String, dynamic> adData = {
        'title': _titleController.text,
        'description': _descController.text,
        'price': _priceController.text,
        'location': _locationController.text,
        'category_id': _finalSelectedCategoryId,
        'images': _images,
        'parameters': _collectParameterData(),
      };
      
      // You would typically call your API service here to submit the ad
      // For example: _adService.createAd(adData);
      
      print('Publishing ad with data: $adData');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Объявление отправлено на модерацию!'),
          backgroundColor: Color(0xff183B4E),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Return to home screen
      _handleExit();
      return;
    }
    
    // When moving to parameters screen (from photos), load parameters
    if (_currentStep == 4 && _finalSelectedCategoryId != null) {
      _fetchParameters(_finalSelectedCategoryId!);
    }
    
    // Handle navigation from parent category to subcategory step
    if (_currentStep == 1) {
      // Get selected parent category
      final selectedParent = _parentCategories.firstWhere(
        (category) => category.id.toString() == _selectedParentCategory,
        orElse: () => _parentCategories.first,
      );
      
      // If no subcategories exist at all, skip to information step
      if (selectedParent.children.isEmpty) {
        setState(() {
          _currentStep = 3; // Skip to information step
          _fadeController.reset();
          _fadeController.forward();
        });
        return;
      }
    }
    
    // Handle navigation from subcategory to 3rd level category step
    if (_currentStep == 1) {
      // Check if selected subcategory has 3rd level categories
      if (_selectedSubCategory != null) {
        final selectedParent = _parentCategories.firstWhere(
          (category) => category.id.toString() == _selectedParentCategory,
          orElse: () => _parentCategories.first,
        );
        
        try {
          final selectedSubcategory = selectedParent.children.firstWhere(
            (subcat) => subcat.id.toString() == _selectedSubCategory,
          );
          
          // If no 3rd level categories exist, skip directly to information step
          if (selectedSubcategory.children.isEmpty) {
            setState(() {
              _currentStep = 3; // Skip to information step (step 2 would be 3rd level categories)
              _fadeController.reset();
              _fadeController.forward();
            });
            return;
          }
        } catch (e) {
          print('Error in navigation from subcategory to 3rd level: $e');
        }
      }
    }
    
    // Proceed to next step
    setState(() {
      _currentStep++;
      _fadeController.reset();
      _fadeController.forward();
    });
  }

  // Helper method to prepare parameter data for submission to API
  Map<String, dynamic> _collectParameterData() {
    final Map<String, dynamic> paramData = {};
    
    for (var param in _categoryParameters) {
      if (param.value != null && param.value!.isNotEmpty) {
        // Add parameter to the collection
        paramData[param.id.toString()] = param.value;
      }
    }
    
    return paramData;
  }
  
  // Helper method to reset form state
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
      _images = [];
    });
  }

  // Helper method to handle exiting the form safely
  void _handleExit() {
    // Reset the form for next time
    _resetForm();
    
    // Check if we can simply pop this screen (e.g., if opened directly)
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If we can't pop, use pushAndRemoveUntil to clear the stack and avoid black screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const NavigationMenu(initialIndex: 0)),
        (route) => false, // This predicate means "remove all routes"
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
