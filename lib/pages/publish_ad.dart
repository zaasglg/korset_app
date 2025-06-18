import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class PublishAdPage extends StatefulWidget {
  const PublishAdPage({super.key});

  @override
  State<PublishAdPage> createState() => _PublishAdPageState();
}

class _PublishAdPageState extends State<PublishAdPage> {
  int _currentStep = 0;
  String? _selectedParentCategory;
  String? _selectedSubCategory;
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<String> _images = [];

  // API Integration
  final CategoryService _categoryService = CategoryService();
  List<Category> _parentCategories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getStepTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Step content
          Expanded(
            child: _buildStepContent(),
          ),
          
          // Bottom navigation
          _buildBottomNavigation(),
        ],
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
        return 'Информация';
      case 3:
        return 'Фотографии';
      default:
        return 'Публикация';
    }
  }

  Widget _buildProgressIndicator() {
    int percentage = ((_currentStep / 4) * 100).round();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Percentage text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Шаг ${_currentStep + 1} из 4',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xff183B4E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: List.generate(4, (index) {
              bool isActive = index <= _currentStep;
              
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isActive 
                      ? const Color(0xff183B4E) 
                      : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildCategorySelection();
      case 1:
        return _buildSubCategorySelection();
      case 2:
        return _buildInformationForm();
      case 3:
        return _buildPhotoSelection();
      default:
        return _buildCategorySelection();
    }
  }

  Widget _buildCategorySelection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            color: Color(0xff183B4E),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchCategories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff183B4E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_parentCategories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Категории не найдены',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите категорию',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Что вы хотите продать или предложить?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _parentCategories.length,
              itemBuilder: (context, index) {
                final category = _parentCategories[index];
                final isSelected = _selectedParentCategory == category.id.toString();
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedParentCategory = category.id.toString();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? category.bgColor.withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? category.bgColor : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? category.bgColor : Colors.grey[400],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: category.photo != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    category.icon,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.category,
                                        color: Colors.white,
                                        size: 24,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.category,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? category.bgColor : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  Widget _buildSubCategorySelection() {
    if (_selectedParentCategory == null) return Container();
    
    // Найдем выбранную родительскую категорию
    final selectedParent = _parentCategories.firstWhere(
      (category) => category.id.toString() == _selectedParentCategory,
      orElse: () => _parentCategories.first,
    );
    
    final subcategories = selectedParent.children;
    
    if (subcategories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Подкатегории',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Подкатегории не найдены',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите подкатегорию',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Уточните категорию товара или услуги',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: subcategories.length,
              itemBuilder: (context, index) {
                final subcategory = subcategories[index];
                final isSelected = _selectedSubCategory == subcategory.id.toString();
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSubCategory = subcategory.id.toString();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? selectedParent.bgColor.withOpacity(0.1) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? selectedParent.bgColor : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isSelected ? selectedParent.bgColor : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? selectedParent.bgColor : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              subcategory.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? selectedParent.bgColor : Colors.black87,
                              ),
                            ),
                          ),
                        ],
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
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Заполните основную информацию',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16.0, 
              horizontal: 16.0
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xff183B4E),
                width: 2,
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
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте до 10 фотографий товара',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Photo grid
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
                  // Add photo button
                  return GestureDetector(
                    onTap: () {
                      // TODO: Implement image picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Функция добавления фото в разработке'),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 32,
                            color: Color(0xff183B4E),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Добавить\nфото',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff183B4E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Photo item
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(_images[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _images.removeAt(index);
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xff183B4E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Назад',
                  style: TextStyle(
                    color: Color(0xff183B4E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _handleNext : null,
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
                _getNextButtonText(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
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
        // Можно продолжить, если выбрана подкатегория ИЛИ если подкатегорий нет
        if (_selectedParentCategory != null) {
          final selectedParent = _parentCategories.firstWhere(
            (category) => category.id.toString() == _selectedParentCategory,
            orElse: () => _parentCategories.first,
          );
          return _selectedSubCategory != null || selectedParent.children.isEmpty;
        }
        return false;
      case 2:
        return _titleController.text.isNotEmpty &&
               _descController.text.isNotEmpty &&
               _priceController.text.isNotEmpty;
      case 3:
        return true; // Photos are optional
      default:
        return false;
    }
  }

  String _getNextButtonText() {
    if (_currentStep == 3) {
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
    if (_currentStep == 3) {
      // Publish ad
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Объявление отправлено на модерацию!'),
          backgroundColor: Color(0xff183B4E),
        ),
      );
      Navigator.pop(context);
    } else if (_currentStep == 1 && _selectedSubCategory == null) {
      // Если нет подкатегорий, пропускаем шаг
      final selectedParent = _parentCategories.firstWhere(
        (category) => category.id.toString() == _selectedParentCategory,
        orElse: () => _parentCategories.first,
      );
      
      if (selectedParent.children.isEmpty) {
        setState(() {
          _currentStep += 2; // Переходим сразу к шагу 3 (информация)
        });
        return;
      }
    }
    
    setState(() {
      _currentStep++;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
