import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../models/product.dart';
import '../models/category.dart';
import '../models/city.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/city_service.dart';

class EditAdPage extends StatefulWidget {
  final Product product;

  const EditAdPage({
    super.key,
    required this.product,
  });

  @override
  State<EditAdPage> createState() => _EditAdPageState();
}

class _EditAdPageState extends State<EditAdPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final CityService _cityService = CityService();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _addressController;
  late TextEditingController _whatsappController;
  late TextEditingController _phoneController;

  // Form data
  Category? _selectedCategory;
  City? _selectedCity;
  File? _selectedImage;
  List<File> _selectedPhotos = [];
  File? _selectedVideo;
  bool _isVideoCallAvailable = false;
  bool _readyForVideoDemo = false;
  String _status = 'active';

  // Lists
  List<Category> _categories = [];
  List<City> _cities = [];

  // Loading states
  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  bool _isCitiesLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _addressController = TextEditingController(text: widget.product.address);
    _whatsappController =
        TextEditingController(text: widget.product.whatsappNumber);
    _phoneController = TextEditingController(text: widget.product.phoneNumber);

    _isVideoCallAvailable = widget.product.isVideoCallAvailable;
    _readyForVideoDemo = widget.product.readyForVideoDemo;
    _status = widget.product.status;
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCategories(),
      _loadCities(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      setState(() {
        _categories = categories;
        _selectedCategory = categories.firstWhere(
          (cat) => cat.id == widget.product.category.id,
          orElse: () => categories.first,
        );
        _isCategoriesLoading = false;
      });
    } catch (e) {
      setState(() {
        _isCategoriesLoading = false;
      });
      _showErrorSnackBar('Ошибка загрузки категорий: $e');
    }
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _cityService.getCities();
      setState(() {
        _cities = cities;
        _selectedCity = cities.firstWhere(
          (city) => city.id == widget.product.city.id,
          orElse: () => cities.first,
        );
        _isCitiesLoading = false;
      });
    } catch (e) {
      setState(() {
        _isCitiesLoading = false;
      });
      _showErrorSnackBar('Ошибка загрузки городов: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора изображения: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedPhotos = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора изображений: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        setState(() {
          _selectedVideo = File(video.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора видео: $e');
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null || _selectedCity == null) {
      _showErrorSnackBar('Пожалуйста, выберите категорию и город');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _productService.updateProduct(
        productId: widget.product.id,
        categoryId: _selectedCategory!.id,
        cityId: _selectedCity!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        address: _addressController.text.trim(),
        whatsappNumber: _whatsappController.text.trim().isNotEmpty
            ? _whatsappController.text.trim()
            : null,
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        isVideoCallAvailable: _isVideoCallAvailable,
        readyForVideoDemo: _readyForVideoDemo,
        status: _status,
        mainPhoto: _selectedImage,
        photos: _selectedPhotos.isNotEmpty ? _selectedPhotos : null,
        video: _selectedVideo,
      );

      if (success && mounted) {
        Navigator.pop(context, true); // Возвращаем true для обновления списка
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Объявление успешно обновлено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка обновления: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _whatsappController.dispose();
    _phoneController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Редактировать объявление',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProduct,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Сохранить',
                    style: TextStyle(
                      color: Color(0xFF183B4E),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Видео
              _buildVideoSection(),
              const SizedBox(height: 24),

              // Основная информация
              _buildBasicInfoSection(),
              const SizedBox(height: 24),

              // Контакты
              _buildContactSection(),
              const SizedBox(height: 24),

              // Дополнительные опции
              _buildAdditionalOptionsSection(),
              const SizedBox(height: 24),

              // Статус
              _buildStatusSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Главное фото',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF183B4E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Оставьте пустым, чтобы сохранить текущее фото',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : widget.product.mainPhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.product.mainPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPhotoPlaceholder();
                          },
                        ),
                      )
                    : _buildPhotoPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          IconlyBroken.camera,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Нажмите чтобы выбрать фото',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дополнительные фото (опционально)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF183B4E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Можно выбрать несколько фотографий товара',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),

        // Показать выбранные фото
        if (_selectedPhotos.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedPhotos[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPhotos.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
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
          const SizedBox(height: 12),
        ],

        // Кнопка для выбора фото
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconlyBroken.camera,
                  size: 32,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedPhotos.isEmpty
                      ? 'Нажмите чтобы выбрать фотографии'
                      : 'Добавить еще фотографии',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    final String? dbVideoUrl = widget.product.videoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Видео (опционально)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF183B4E),
          ),
        ),
        const SizedBox(height: 12),
        
        // Показать выбранное видео
        if (_selectedVideo != null) ...[
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _VideoPlayerWidget(videoFile: _selectedVideo!),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Выбрать другое видео'),
                  onPressed: _pickVideo,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _selectedVideo = null;
                  });
                },
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ] else if (dbVideoUrl != null && dbVideoUrl.isNotEmpty) ...[
          // Показать текущее видео из базы
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _NetworkVideoPlayerWidget(videoUrl: dbVideoUrl),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF183B4E),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.videocam),
            label: const Text('Заменить видео'),
            onPressed: _pickVideo,
          ),
        ] else ...[
          // Кнопка для выбора видео
          GestureDetector(
            onTap: _pickVideo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    IconlyBroken.video,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите чтобы выбрать видео',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Основная информация',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF183B4E),
          ),
        ),
        const SizedBox(height: 16),

        // Категория
        _buildDropdownField(
          label: 'Категория',
          value: _selectedCategory,
          items: _categories,
          isLoading: _isCategoriesLoading,
          onChanged: (Category? category) {
            setState(() {
              _selectedCategory = category;
            });
          },
          itemBuilder: (category) => Text(category.name),
        ),
        const SizedBox(height: 16),

        // Город
        _buildDropdownField(
          label: 'Город',
          value: _selectedCity,
          items: _cities,
          isLoading: _isCitiesLoading,
          onChanged: (City? city) {
            setState(() {
              _selectedCity = city;
            });
          },
          itemBuilder: (city) => Text(city.name),
        ),
        const SizedBox(height: 16),

        // Название
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Название товара',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF183B4E)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Введите название товара';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Описание
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Описание',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF183B4E)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Цена
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Цена (₸)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF183B4E)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Введите цену';
            }
            if (double.tryParse(value.trim()) == null) {
              return 'Введите корректную цену';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Адрес
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Адрес',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF183B4E)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Контактная информация',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF183B4E),
          ),
        ),
        const SizedBox(height: 16),

        // WhatsApp
        TextFormField(
          controller: _whatsappController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'WhatsApp номер',
            prefixText: '+',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF183B4E)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Телефон
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Номер телефона',
            prefixText: '+',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF183B4E)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дополнительные опции',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF183B4E),
          ),
        ),
        const SizedBox(height: 16),

        // Видеозвонок
        SwitchListTile(
          title: const Text('Доступен видеозвонок'),
          value: _isVideoCallAvailable,
          onChanged: (value) {
            setState(() {
              _isVideoCallAvailable = value;
            });
          },
          activeColor: const Color(0xFF183B4E),
        ),

        // Видеодемонстрация
        SwitchListTile(
          title: const Text('Готов к видеодемонстрации'),
          value: _readyForVideoDemo,
          onChanged: (value) {
            setState(() {
              _readyForVideoDemo = value;
            });
          },
          activeColor: const Color(0xFF183B4E),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Статус объявления',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF183B4E),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF183B4E)),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'active',
              child: Text('Активно'),
            ),
            DropdownMenuItem(
              value: 'inactive',
              child: Text('Неактивно'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _status = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required bool isLoading,
    required ValueChanged<T?> onChanged,
    required Widget Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        isLoading
            ? Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : DropdownButtonFormField<T>(
                value: value,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF183B4E)),
                  ),
                ),
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: itemBuilder(item),
                  );
                }).toList(),
                onChanged: onChanged,
                validator: (value) {
                  if (value == null) {
                    return 'Выберите $label';
                  }
                  return null;
                },
              ),
      ],
    );
  }
}

// Виджет для воспроизведения локального видео
class _VideoPlayerWidget extends StatefulWidget {
  final File videoFile;

  const _VideoPlayerWidget({required this.videoFile});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(widget.videoFile);
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Ошибка инициализации видео: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}

// Виджет для воспроизведения сетевого видео
class _NetworkVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _NetworkVideoPlayerWidget({required this.videoUrl});

  @override
  State<_NetworkVideoPlayerWidget> createState() => _NetworkVideoPlayerWidgetState();
}

class _NetworkVideoPlayerWidgetState extends State<_NetworkVideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Ошибка инициализации сетевого видео: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 32),
              SizedBox(height: 8),
              Text('Ошибка загрузки видео'),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}