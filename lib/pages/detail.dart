import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:video_player/video_player.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:korset_app/components/product_image_widget.dart';
import 'package:korset_app/services/favorites_service.dart';
import 'package:korset_app/services/auth_service.dart';
import 'package:korset_app/services/image_url_helper.dart';
import 'package:korset_app/services/product_service.dart';
import 'package:korset_app/services/share_service.dart';
import 'package:korset_app/services/chat_service.dart';
import 'package:korset_app/services/booking_commission_service.dart';
import 'package:korset_app/models/booking_commission.dart';
import 'package:korset_app/models/booking_status.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  final int? productId;

  const DetailPage({
    Key? key,
    this.product,
    this.productId,
  })  : assert(product != null || productId != null,
            'Either product or productId must be provided'),
        super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool isFavorite = false;
  bool _favoriteLoading = false;
  bool _shareLoading = false;
  bool _messageLoading = false;
  VideoPlayerController? _controller;
  YandexMapController? _mapController;
  final List<MapObject> _mapObjects = [];
  static const Point _defaultLocation =
      Point(latitude: 43.2220, longitude: 76.8512); // Алматы
  final TextEditingController _messageController = TextEditingController();

  // Video controls visibility
  bool _showVideoControls = false;
  Timer? _hideControlsTimer;
  Timer? _videoProgressTimer;
  bool _isFullScreen = false;

  // API Integration
  final ProductService _productService = ProductService();
  final BookingCommissionService _bookingService = BookingCommissionService();
  Map<String, dynamic>? _productData;
  BookingStatus? _productBookingStatus;
  bool _isLoading = false;
  String? _error;

  // Кэшируем пользователя чтобы избежать постоянных обновлений
  Map<String, dynamic>? _currentUser;
  bool _userLoading = true;

  // Получаем данные продукта
  String get productName => _productData?['name'] ?? 'Без названия';
  String get productPrice =>
      _productData?['price'] != null ? '${_productData!['price']} ₸' : '0 ₸';
  String get productLocation => _productData?['city']?['name'] ?? 'Не указано';
  String get productDescription =>
      _productData?['description'] ?? 'Описание отсутствует';
  String get productAddress => _productData?['address'] ?? productLocation;
  String get sellerName => _productData?['user']?['name'] ?? 'Продавец';
  String get sellerSince =>
      '2023'; // Можно вычислить из created_at пользователя
  String? get productImage => _productData?['main_photo'];
  String? get productVideo => _productData?['video'];
  String? get productVideoUrl => _productData?['video_url'];
  int get productId => _productData?['id'] ?? 0;
  List<dynamic> get parameterValues => _productData?['parameter_values'] ?? [];

  // Contact fields
  String? get whatsappNumber => _productData?['whatsapp_number'];
  String? get phoneNumber => _productData?['phone_number'];
  bool get readyForVideoDemo =>
      _productData?['is_video_call_available'] ?? false;
  int? get sellerId => _productData?['user']?['id'];

  // Check if this is a sublease (Субаренда) category
  bool get isSubleaseCategory =>
      _productData?['category']?['name'] == 'Субаренда';

  // Получить дату создания в читаемом формате
  String get formattedDate {
    try {
      final now = DateTime.now();
      final createdAt = _productData?['created_at'];
      final difference =
          now.difference(DateTime.parse(createdAt ?? now.toIso8601String()));

      if (difference.inDays > 0) {
        return '${difference.inDays} дн. назад';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ч. назад';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} мин. назад';
      } else {
        return 'Только что';
      }
    } catch (e) {
      return 'Недавно';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeProductData();
    _loadCurrentUser(); // Добавляем загрузку пользователя
  }

  // Добавляем метод для загрузки текущего пользователя
  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _userLoading = false;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
      if (mounted) {
        setState(() {
          _currentUser = null;
          _userLoading = false;
        });
      }
    }
  }

  Future<void> _initializeProductData() async {
    if (widget.product != null) {
      // Use provided product data
      _productData = widget.product;
      _printProductData();
      _initializeVideo();
      _initializeMapObjects();
      _checkFavoriteStatus();
      // Загружаем статус бронирования для категории "Субаренда"
      if (isSubleaseCategory) {
        _loadBookingStatus();
      }
    } else if (widget.productId != null) {
      // Fetch product data from API
      await _fetchProductFromAPI();
    }
  }

  Future<void> _fetchProductFromAPI() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productData =
          await _productService.getProductByIdRaw(widget.productId!);
      setState(() {
        _productData = productData;
        _isLoading = false;
      });

      _printProductData();
      _initializeVideo();
      _initializeMapObjects();
      _checkFavoriteStatus();
      _loadBookingStatus();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error fetching product: $e');
    }
  }

  void _printProductData() {
    print('=== Product Data Debug ===');
    print('Full Product Data: $_productData');
    print('Product Image: $productImage');
    print('Product Video: $productVideo');
    print('Product Video URL: $productVideoUrl');
    print('Parameter Values: $parameterValues');
    print('Parameter Values Length: ${parameterValues.length}');
    print('WhatsApp: $whatsappNumber');
    print('Phone: $phoneNumber');
    print('Ready for video demo: $readyForVideoDemo');
    print('Category: ${_productData?['category']?['name']}');
    print('City: ${_productData?['city']?['name']}');
    print('User: ${_productData?['user']?['name']}');

    // Проверим каждый параметр отдельно
    if (parameterValues.isNotEmpty) {
      print('Parameters details:');
      for (int i = 0; i < parameterValues.length; i++) {
        final param = parameterValues[i];
        print('  Parameter $i: $param');
        if (param is Map) {
          print('    Parameter name: ${param['parameter']?['name']}');
          print('    Parameter value: ${param['value']}');
        }
      }
    }
    print('========================');
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isInFavorites = await FavoritesService.isFavorite(productId);
      if (mounted) {
        setState(() {
          isFavorite = isInFavorites;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _loadBookingStatus() async {
    if (widget.productId == null) return;

    try {
      print('Loading booking status for product ${widget.productId}');
      final status = await _bookingService.getBookingStatus(widget.productId!);

      if (mounted) {
        setState(() {
          _productBookingStatus = status;
        });
        print(
            'Booking status loaded: ${status.isBookable} - ${status.bookingStatus}');
      }
    } catch (e) {
      print('Error loading booking status: $e');
      // Не показываем ошибку пользователю, просто логируем
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading) return;

    setState(() {
      _favoriteLoading = true;
    });

    try {
      final newFavoriteStatus =
          await FavoritesService.toggleFavorite(productId, isFavorite);

      if (mounted) {
        setState(() {
          isFavorite = newFavoriteStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newFavoriteStatus
                ? 'Добавлено в избранное'
                : 'Удалено из избранного'),
            backgroundColor: newFavoriteStatus
                ? const Color(0xFF4CAF50)
                : const Color(0xFF757575),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _favoriteLoading = false;
        });
      }
    }
  }

  Future<void> _initializeVideo() async {
    print('=== Video Initialization Debug ===');
    print('Product Video: $productVideo');
    print('Product Video URL: $productVideoUrl');
    print('Product Video isEmpty: ${productVideo?.isEmpty}');
    print('Product Video != null: ${productVideo != null}');

    // Используем video_url если доступен, иначе пытаемся построить из video
    String? videoUrl;
    if (productVideoUrl != null && productVideoUrl!.isNotEmpty) {
      videoUrl = productVideoUrl;
      print('Using direct video URL: $videoUrl');
    } else if (ImageUrlHelper.isValidPath(productVideo)) {
      videoUrl = ImageUrlHelper.getVideoUrl(productVideo);
      print('Using constructed video URL: $videoUrl');
    }

    if (videoUrl != null && videoUrl.isNotEmpty) {
      try {
        print('Final video URL: $videoUrl');

        // Создаем контроллер для сетевого видео
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

        // Добавляем слушатель для отслеживания состояния
        _controller!.addListener(() {
          if (_controller!.value.hasError) {
            print('Video player error: ${_controller!.value.errorDescription}');
          }
        });

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            // Контроллер теперь инициализирован
          });

          // Автоматически воспроизводим видео при загрузке страницы
          _controller!.setVolume(0.0); // По умолчанию без звука
          _controller!.setLooping(true); // Зацикливаем видео
          _controller!.play(); // Автовоспроизведение при загрузке страницы

          // Запускаем таймер для обновления прогресса
          _startVideoProgressTimer();

          print(
              'Video initialized successfully. Duration: ${_controller!.value.duration}');
          print(
              'Video autoplay enabled. Volume: ${_controller!.value.volume}, Looping: ${_controller!.value.isLooping}');
        }
      } catch (error) {
        print('Error initializing video: $error');
        _controller = null;
        if (mounted) {
          setState(() {
            // Сбрасываем состояние при ошибке
          });
        }
      }
    } else {
      print('No product video found');
      _controller = null;
    }
  }

  void _initializeMapObjects() {
    _mapObjects.add(
      PlacemarkMapObject(
        mapId: const MapObjectId('location'),
        point: _defaultLocation,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('assets/images/marker.png'),
            scale: 1.0,
          ),
        ),
        text: PlacemarkText(
          text: productLocation,
          style: const PlacemarkTextStyle(
            color: Colors.black,
            size: 12,
          ),
        ),
      ),
    );
  }

  void _onMapCreated(YandexMapController controller) {
    _mapController = controller;
    controller.moveCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: _defaultLocation,
          zoom: 14,
        ),
      ),
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() {
          _showVideoControls = false;
        });
      }
    });
  }

  void _showVideoControlsTemporarily() {
    setState(() {
      _showVideoControls = true;
    });
    _startHideControlsTimer();
  }

  void _startVideoProgressTimer() {
    _videoProgressTimer?.cancel();
    _videoProgressTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_controller != null && _controller!.value.isInitialized && mounted) {
        setState(() {
          // Обновляем UI для отображения текущего прогресса
        });
        // Также обновляем полноэкранный режим, если он активен
        if (_isFullScreen) {
          // Принудительно перестраиваем полноэкранный плеер
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }
      }
    });
  }

  void _stopVideoProgressTimer() {
    _videoProgressTimer?.cancel();
    _videoProgressTimer = null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      // Выход из полноэкранного режима
      Navigator.of(context).pop();
      setState(() {
        _isFullScreen = false;
      });
    } else {
      // Переход в полноэкранный режим
      setState(() {
        _isFullScreen = true;
      });
      Navigator.of(context)
          .push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return _buildFullScreenVideoPlayer();
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      )
          .then((_) {
        // Когда полноэкранный режим закрывается
        setState(() {
          _isFullScreen = false;
        });
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      });
    }
  }

  Widget _buildFullScreenVideoPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StatefulBuilder(
          builder: (context, setFullscreenState) {
            // Скрываем системные элементы в полноэкранном режиме
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

            // Добавляем слушатель для автоматического обновления UI
            if (_controller != null) {
              _controller!.addListener(() {
                if (mounted) {
                  setFullscreenState(() {});
                }
              });
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                // Видео на весь экран
                if (_controller != null && _controller!.value.isInitialized)
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                // Центральная кнопка play/pause для полноэкранного режима
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (_controller!.value.isPlaying) {
                        _controller!.pause();
                        _stopVideoProgressTimer();
                        setFullscreenState(() {
                          _showVideoControls = true;
                        });
                        _hideControlsTimer?.cancel();
                      } else {
                        _controller!.play();
                        _startVideoProgressTimer();
                        setFullscreenState(() {
                          _showVideoControls = false;
                        });
                      }
                    },
                    child: AnimatedOpacity(
                      opacity:
                          (!_controller!.value.isPlaying || _showVideoControls)
                              ? 1.0
                              : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _controller!.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Элементы управления внизу для полноэкранного режима (всегда видимые)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Ползунок прогресса
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor:
                                    Colors.white.withValues(alpha: 0.3),
                                thumbColor: Colors.white,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8),
                                trackHeight: 4,
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14),
                              ),
                              child: Slider(
                                value: _controller != null &&
                                        _controller!.value.isInitialized
                                    ? _controller!.value.position.inMilliseconds
                                        .toDouble()
                                    : 0.0,
                                min: 0.0,
                                max: _controller != null &&
                                        _controller!.value.isInitialized
                                    ? _controller!.value.duration.inMilliseconds
                                        .toDouble()
                                    : 1.0,
                                onChangeStart: (value) {
                                  // Приостанавливаем автоматическое обновление при начале изменения
                                  _stopVideoProgressTimer();
                                },
                                onChanged: (value) {
                                  if (_controller != null &&
                                      _controller!.value.isInitialized) {
                                    final position =
                                        Duration(milliseconds: value.toInt());
                                    _controller!.seekTo(position);
                                    // Обновляем состояние для реактивного отображения
                                    setFullscreenState(() {});
                                  }
                                },
                                onChangeEnd: (value) {
                                  // Возобновляем автоматическое обновление после изменения
                                  if (_controller != null &&
                                      _controller!.value.isPlaying) {
                                    _startVideoProgressTimer();
                                  }
                                },
                              ),
                            ),
                            // Нижняя панель с кнопками и временем
                            Row(
                              children: [
                                // Текущее время
                                Text(
                                  _controller != null &&
                                          _controller!.value.isInitialized
                                      ? _formatDuration(
                                          _controller!.value.position)
                                      : '00:00',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                // Кнопка звука
                                GestureDetector(
                                  onTap: () {
                                    if (_controller != null) {
                                      setFullscreenState(() {
                                        if (_controller!.value.volume == 0) {
                                          _controller!.setVolume(1.0);
                                        } else {
                                          _controller!.setVolume(0.0);
                                        }
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      _controller?.value.volume == 0
                                          ? Icons.volume_off_rounded
                                          : Icons.volume_up_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Кнопка выхода из полноэкранного режима
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen_exit_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Общая продолжительность
                                Text(
                                  _controller != null &&
                                          _controller!.value.isInitialized
                                      ? _formatDuration(
                                          _controller!.value.duration)
                                      : '00:00',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  void _showMessageDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seller info
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xff183B4E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          IconlyBold.profile,
                          size: 20,
                          color: Color(0xff183B4E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sellerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Онлайн",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Message input
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _messageController,
                          maxLines: 3,
                          minLines: 1,
                          maxLength: 1000,
                          decoration: const InputDecoration(
                            hintText: 'Напишите сообщение...',
                            hintStyle: TextStyle(
                              color: Color(0xff6B7280),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                            counterText: '', // Скрываем стандартный счетчик
                          ),
                        ),
                        // Кастомный счетчик символов
                        Padding(
                          padding: const EdgeInsets.only(right: 12, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _messageController,
                                builder: (context, value, child) {
                                  final length = value.text.length;
                                  final isOverLimit = length > 1000;
                                  return Text(
                                    '$length/1000',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOverLimit
                                          ? Colors.red
                                          : Colors.grey[500],
                                      fontWeight: isOverLimit
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Send button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _messageLoading
                          ? null
                          : () async {
                              final messageText =
                                  _messageController.text.trim();
                              if (messageText.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Введите текст сообщения'),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              if (messageText.length > 1000) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Сообщение слишком длинное (максимум 1000 символов)'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }

                              await _sendMessageToSeller(messageText);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff183B4E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _messageLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Отправить",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog() {
    print('=== Show Booking Dialog Debug ===');
    print('Product ID: $productId');
    print('Product Name: $productName');
    print('Product Price: $productPrice');
    print('Is Sublease Category: $isSubleaseCategory');
    print('Product Category: ${_productData?['category']?['name']}');
    print('Product Status: ${_productData?['status']}');
    print('Product Expires At: ${_productData?['expires_at']}');
    print('Product Is Promoted: ${_productData?['is_promoted']}');
    print('Full Product Data: $_productData');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingDialog(
        productId: productId,
        productName: productName,
        productPrice: productPrice,
        sellerId: sellerId,
        onContactPressed: () {
          Navigator.pop(context);
          _showMessageDialog();
        },
        onBookingStatusUpdated: () {
          // Обновляем статус бронирования в основном виджете
          _loadBookingStatus();
        },
      ),
    );
  }

  Widget _buildMediaWidget() {
    // Определяем, есть ли видео
    String? videoUrl;
    if (productVideoUrl?.isNotEmpty == true) {
      videoUrl = productVideoUrl;
    } else if (ImageUrlHelper.isValidPath(productVideo)) {
      videoUrl = ImageUrlHelper.getVideoUrl(productVideo);
    }

    // Определяем, есть ли изображение
    String? imageUrl;
    if (ImageUrlHelper.isValidPath(productImage)) {
      imageUrl = ImageUrlHelper.getImageUrl(productImage);
    }

    // Если есть видео, показываем видео плеер с полным покрытием
    if (videoUrl != null &&
        _controller != null &&
        _controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Видео с полным покрытием (аналог CSS background-size: cover)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
            // Центральная кнопка play/pause
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_controller!.value.isPlaying) {
                    // Если видео играет, поставить на паузу и показать элементы управления
                    _controller!.pause();
                    _stopVideoProgressTimer();
                    setState(() {
                      _showVideoControls = true;
                    });
                    _hideControlsTimer?.cancel();
                  } else {
                    // Если видео на паузе, начать воспроизведение и скрыть элементы управления
                    _controller!.play();
                    _startVideoProgressTimer();
                    setState(() {
                      _showVideoControls = false;
                    });
                  }
                },
                child: AnimatedOpacity(
                  opacity: (!_controller!.value.isPlaying || _showVideoControls)
                      ? 1.0
                      : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _controller!.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Ползунок прогресса видео внизу (всегда видимый)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Текущее время
                      Text(
                        _formatDuration(_controller!.value.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Ползунок прогресса
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.3),
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            trackHeight: 3,
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                          ),
                          child: Slider(
                            value: _controller!.value.position.inMilliseconds
                                .toDouble(),
                            min: 0.0,
                            max: _controller!.value.duration.inMilliseconds
                                .toDouble(),
                            onChanged: (value) {
                              final position =
                                  Duration(milliseconds: value.toInt());
                              _controller!.seekTo(position);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Общая продолжительность
                      Text(
                        _formatDuration(_controller!.value.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Маленькая кнопка звука (самая вправо)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_controller!.value.volume == 0) {
                              _controller!.setVolume(1.0);
                            } else {
                              _controller!.setVolume(0.0);
                            }
                          });
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _controller!.value.volume == 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Кнопка полноэкранного режима
                      GestureDetector(
                        onTap: _toggleFullScreen,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _isFullScreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
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
    // Если есть только изображение
    if (imageUrl != null) {
      return ProductImageWidget(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Если нет ни видео, ни изображения
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 64,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalParameterRow(dynamic param) {
    try {
      final String parameterName = param['parameter']?['name'] ?? 'Параметр';
      final String value = param['value']?.toString() ?? '';

      if (value.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                parameterName,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error building parameter row: $e');
      return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _hideControlsTimer?.cancel();
    _stopVideoProgressTimer();
    // Сброс системных элементов при выходе
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _mapController?.dispose();
    try {
      _controller?.dispose();
    } catch (e) {
      print('Error disposing video controller: $e');
    }
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    if (whatsappNumber == null || whatsappNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Номер WhatsApp не указан'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Очищаем номер от лишних символов и форматируем для WhatsApp
    String cleanNumber = whatsappNumber!.replaceAll(RegExp(r'[^\d+]'), '');

    // Если номер не начинается с +, добавляем код Казахстана
    if (!cleanNumber.startsWith('+')) {
      if (cleanNumber.startsWith('7') || cleanNumber.startsWith('8')) {
        cleanNumber = '+7${cleanNumber.substring(1)}';
      } else {
        cleanNumber = '+7$cleanNumber';
      }
    }

    // Формируем URL для WhatsApp
    final whatsappUrl = 'https://wa.me/${cleanNumber.replaceAll('+', '')}';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Пробуем альтернативный способ через схему whatsapp://
        final alternativeUrl =
            'whatsapp://send?phone=${cleanNumber.replaceAll('+', '')}';
        final alternativeUri = Uri.parse(alternativeUrl);

        if (await canLaunchUrl(alternativeUri)) {
          await launchUrl(alternativeUri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('WhatsApp не установлен на устройстве'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error opening WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка открытия WhatsApp: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall() async {
    if (phoneNumber == null || phoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Номер телефона не указан'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Очищаем номер от лишних символов
    String cleanNumber = phoneNumber!.replaceAll(RegExp(r'[^\d+]'), '');

    // Если номер не начинается с +, добавляем код Казахстана
    if (!cleanNumber.startsWith('+')) {
      if (cleanNumber.startsWith('7') || cleanNumber.startsWith('8')) {
        cleanNumber = '+7${cleanNumber.substring(1)}';
      } else {
        cleanNumber = '+7$cleanNumber';
      }
    }

    // Формируем URL для звонка
    final phoneUrl = 'tel:$cleanNumber';

    print('Making phone call to: $phoneUrl');

    try {
      final uri = Uri.parse(phoneUrl);

      // Проверяем, можем ли мы запустить URL
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Показываем успешное сообщение
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Звонок на номер $cleanNumber'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Не можем запустить URL - возможно симулятор
        if (mounted) {
          _showPhoneCallDialog(cleanNumber);
        }
      }
    } catch (e) {
      print('Error making phone call: $e');
      if (mounted) {
        // Проверяем, работаем ли мы в симуляторе/эмуляторе
        if (kIsWeb || (kDebugMode && !kReleaseMode)) {
          _showPhoneCallDialog(cleanNumber);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при звонке: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showPhoneCallDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.phone,
                color: const Color(0xff183B4E),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Звонок',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Номер телефона продавца:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        phoneNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phoneNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Номер скопирован в буфер обмена'),
                            backgroundColor: Color(0xFF4CAF50),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.copy,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (kIsWeb || (kDebugMode && !kReleaseMode)) ...[
                Text(
                  'Примечание: Прямые звонки недоступны в симуляторе/веб-версии. Скопируйте номер и используйте приложение телефона.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Закрыть',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phoneNumber));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Номер скопирован в буфер обмена'),
                    backgroundColor: Color(0xFF4CAF50),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff183B4E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Скопировать'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareProduct() async {
    if (_shareLoading) return;

    setState(() {
      _shareLoading = true;
    });

    try {
      await ShareService.shareProductComplete(productId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Объявление успешно поделено'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при поделиться: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _shareLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessageToSeller(String messageText) async {
    if (_messageLoading) return;

    print('=== Send Message Debug ===');
    print('Product ID: $productId');
    print('Seller ID: $sellerId');
    print('Message text: $messageText');
    print('Product data user: ${_productData?['user']}');
    print('========================');

    // Проверяем авторизацию
    final isAuthenticated = await AuthService.isAuthenticated();
    if (!isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Для отправки сообщений требуется авторизация'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Проверяем, что есть ID продавца
    if (sellerId == null || sellerId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Информация о продавце недоступна'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Проверяем, что есть ID продукта
    if (productId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Информация о продукте недоступна'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _messageLoading = true;
    });

    try {
      await ChatService.sendMessageToProduct(
        productId: productId,
        recipientId: sellerId!,
        text: messageText,
      );

      if (mounted) {
        Navigator.pop(context); // Закрываем диалог
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сообщение успешно отправлено'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
        _messageController.clear(); // Очищаем поле ввода
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при отправке сообщения: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _messageLoading = false;
        });
      }
    }
  }

  Widget _buildSubleaseBottomBar() {
    // Если у кого-то есть активное бронирование
    if (_productBookingStatus?.activeBooking != null) {
      // Проверяем, является ли текущий пользователь тем, кто забронировал
      if (_userLoading) {
        return Container(
          height: 52,
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xff183B4E),
            ),
          ),
        );
      }

      final currentUserId = _currentUser?['id'];
      final bookedByUserId = _productBookingStatus?.activeBooking?.userId;

      print('=== Booking Access Check ===');
      print('Current user ID: $currentUserId');
      print('Booked by user ID: $bookedByUserId');
      print(
          'Active booking: ${_productBookingStatus?.activeBooking?.userName}');
      print(
          'Is same user: ${currentUserId != null && currentUserId == bookedByUserId}');

      // Если текущий пользователь забронировал - показываем контакты
      if (currentUserId != null && currentUserId == bookedByUserId) {
        return Row(
          children: [
            // Phone call button (if phone number available)
            if (phoneNumber != null && phoneNumber!.isNotEmpty) ...[
              Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xff183B4E),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _makePhoneCall,
                  icon: const Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],

            // WhatsApp button (if WhatsApp number available)
            if (whatsappNumber != null && whatsappNumber!.isNotEmpty) ...[
              Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _openWhatsApp,
                  icon: const Icon(
                    Icons.message,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],

            // Message button
            Expanded(
              child: Container(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showMessageDialog,
                  icon: const Icon(Icons.chat, size: 20),
                  label: const Text(
                    'Написать',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff183B4E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        // Если забронировал кто-то другой - показываем "Не свободна"
        return Container(
          height: 52,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Не свободна",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    }

    // Если нельзя забронировать по другим причинам - показываем "Не свободна"
    if (_productBookingStatus != null && !_productBookingStatus!.isBookable) {
      return Container(
        height: 52,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Не свободна",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // По умолчанию - показываем кнопку бронирования (свободно)
    return Container(
      height: 52,
      child: ElevatedButton(
        onPressed: _showBookingDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff183B4E),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Забронировать",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              IconlyBroken.arrowLeft,
              color: Color(0xff183B4E),
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xff183B4E),
          ),
        ),
      );
    }

    // Show error state
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              IconlyBroken.arrowLeft,
              color: Color(0xff183B4E),
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconlyBroken.danger,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Ошибка загрузки',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (widget.productId != null) {
                    _fetchProductFromAPI();
                  }
                },
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

    // Show product data is not available
    if (_productData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              IconlyBroken.arrowLeft,
              color: Color(0xff183B4E),
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Данные продукта недоступны',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // Show main product detail UI
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Minimalist Hero image section
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(12),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildMediaWidget(),
            ),
          ),

          // Minimalist Content section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product basic info
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location first (minimalist)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              productLocation,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            // Date badge (minimal)
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Product name (clean typography)
                        Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Price (prominent but clean)
                        Text(
                          productPrice,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action buttons (favorite and share)
                        Row(
                          children: [
                            // Favorite button
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: _favoriteLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? Colors.red
                                            : Colors.grey[600],
                                        size: 22,
                                      ),
                                onPressed:
                                    _favoriteLoading ? null : _toggleFavorite,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Share button
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: _shareLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : Icon(
                                        Icons.share_outlined,
                                        color: Colors.grey[600],
                                        size: 22,
                                      ),
                                onPressed: _shareLoading ? null : _shareProduct,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Description (minimalist)
                  if (productDescription.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productDescription,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Parameters (minimalist)
                  if (parameterValues.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Характеристики",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...parameterValues
                              .map((param) => _buildMinimalParameterRow(param)),
                        ],
                      ),
                    ),
                  ],

                  // Location section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Местоположение",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          productAddress.isNotEmpty
                              ? productAddress
                              : productLocation,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xff6B7280),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: YandexMap(
                              onMapCreated: _onMapCreated,
                              mapObjects: _mapObjects,
                              onMapTap: (Point point) {},
                              onMapLongTap: (Point point) {},
                              onCameraPositionChanged: (CameraPosition position,
                                  CameraUpdateReason reason, bool finished) {},
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    height: 1,
                    color: Colors.grey[100],
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                  ),

                  // Seller section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Продавец",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xff183B4E)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                IconlyBold.profile,
                                size: 24,
                                color: Color(0xff183B4E),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sellerName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "На сайте с $sellerSince",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xff6B7280),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Contact options (hide for sublease category)
                        if (!isSubleaseCategory &&
                            (phoneNumber != null ||
                                whatsappNumber != null ||
                                readyForVideoDemo)) ...[
                          const SizedBox(height: 16),

                          // Phone
                          if (phoneNumber != null &&
                              phoneNumber!.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    phoneNumber!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xff1A1A1A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // WhatsApp
                          if (whatsappNumber != null &&
                              whatsappNumber!.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.video_call,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    whatsappNumber!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xff1A1A1A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Video demo
                          if (readyForVideoDemo) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xff183B4E)
                                        .withValues(alpha: 0.1),
                                    const Color(0xff56A3E6)
                                        .withValues(alpha: 0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xff183B4E)
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xff183B4E)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.videocam_rounded,
                                      size: 18,
                                      color: Color(0xff183B4E),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Готов показать по видеозвонку",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xff183B4E),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Продавец готов провести видеодемонстрацию",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),

      // Minimalist Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: isSubleaseCategory
              ? // For sublease category - show booking, unavailable, or contact buttons
              _buildSubleaseBottomBar()
              : // For regular categories - show contact buttons
              Row(
                  children: [
                    // Phone call button (if phone number available)
                    if (phoneNumber != null && phoneNumber!.isNotEmpty) ...[
                      Container(
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xff183B4E),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _makePhoneCall,
                          icon: const Icon(Icons.phone,
                              size: 24, color: Colors.white),
                        ),
                      ),
                    ],

                    // WhatsApp button (if WhatsApp number available)
                    if (whatsappNumber != null &&
                        whatsappNumber!.isNotEmpty) ...[
                      Container(
                        width: 52,
                        height: 52,
                        margin: EdgeInsets.only(
                          left: (phoneNumber != null && phoneNumber!.isNotEmpty)
                              ? 8
                              : 0,
                          right: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff25D366),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _openWhatsApp,
                          icon: const Icon(Icons.chat_bubble,
                              size: 24, color: Colors.white),
                        ),
                      ),
                    ],

                    // Message button
                    Expanded(
                      child: Container(
                        height: 52,
                        margin: EdgeInsets.only(
                          left: ((phoneNumber != null &&
                                      phoneNumber!.isNotEmpty) ||
                                  (whatsappNumber != null &&
                                      whatsappNumber!.isNotEmpty))
                              ? 8
                              : 0,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _showMessageDialog,
                          icon: const Icon(Icons.message, size: 20),
                          label: const Text(
                            "Сообщение",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BookingDialog extends StatefulWidget {
  final int productId;
  final String productName;
  final String productPrice;
  final int? sellerId;
  final VoidCallback onContactPressed;
  final VoidCallback? onBookingStatusUpdated;

  const _BookingDialog({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.sellerId,
    required this.onContactPressed,
    this.onBookingStatusUpdated,
  });

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  final BookingCommissionService _bookingService = BookingCommissionService();
  BookingCommission? _commission;
  BookingStatus? _bookingStatus;
  bool _isLoading = true;
  bool _isBookingLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('=== Booking Dialog InitState ===');
    print('Product ID: ${widget.productId}');
    print('Product Name: ${widget.productName}');
    print('Product Price: ${widget.productPrice}');
    _loadCommission();
  }

  Future<void> _loadCommission() async {
    try {
      // Загружаем и тарифы, и статус бронирования параллельно
      final futures = await Future.wait([
        _bookingService.getFirstBookingCommission(),
        _bookingService.getBookingStatus(widget.productId),
      ]);

      final commission = futures[0] as BookingCommission?;
      final bookingStatus = futures[1] as BookingStatus;

      if (mounted) {
        setState(() {
          _commission = commission;
          _bookingStatus = bookingStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBookingStatus() async {
    try {
      final status = await _bookingService.getBookingStatus(widget.productId);
      if (mounted) {
        setState(() {
          _bookingStatus = status;
        });
      }
    } catch (e) {
      print('Error loading booking status: $e');
    }
  }

  Future<void> _sendBookingNotificationToSeller() async {
    try {
      if (widget.sellerId == null || widget.sellerId == 0) {
        print('No seller ID available for booking notification');
        return;
      }

      // Отправляем уведомление продавцу о бронировании
      await ChatService.sendMessageToProduct(
        productId: widget.productId,
        recipientId: widget.sellerId!,
        text:
            'Ваше объявление "${widget.productName}" забронировано! Покупатель готов обсудить детали.',
      );

      print(
          'Booking notification sent to seller for product ${widget.productId}');
    } catch (e) {
      print('Error sending booking notification: $e');
      // Не показываем ошибку пользователю, так как основное действие (бронирование) прошло успешно
    }
  }

  void _showBookingSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF4CAF50),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Бронирование успешно!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ваше бронирование подтверждено. Теперь вы можете связаться с продавцом:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Закрыть',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createBooking() async {
    print('=== Booking Creation Debug ===');
    print('Product ID: ${widget.productId}');
    print('Is booking loading: $_isBookingLoading');
    print('Booking status: ${_bookingStatus?.isBookable}');
    print('Booking status message: ${_bookingStatus?.bookingStatus}');

    if (_isBookingLoading) return;

    // Проверяем статус бронирования перед попыткой создания
    if (_bookingStatus != null && !_bookingStatus!.isBookable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_bookingStatus!.bookingStatus.isNotEmpty
                ? _bookingStatus!.bookingStatus
                : 'Данное объявление не подлежит бронированию'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() {
      _isBookingLoading = true;
    });

    try {
      print('Attempting to create booking...');
      await _bookingService.createBooking(
        productId: widget.productId,
        notes: 'Бронирование через приложение',
      );

      print('Booking created successfully');

      // Отправляем сообщение продавцу о бронировании
      await _sendBookingNotificationToSeller();

      // Обновляем статус бронирования в основном виджете
      if (widget.onBookingStatusUpdated != null) {
        widget.onBookingStatusUpdated!();
      }

      // Небольшая задержка для обеспечения корректного обновления UI
      await Future.delayed(const Duration(milliseconds: 500));

      // Обновляем статус бронирования в диалоге
      await _loadBookingStatus();

      if (mounted) {
        Navigator.pop(context);
        // Показываем диалог с контактами
        _showBookingSuccessDialog();
      }
    } catch (e) {
      print('Booking creation error: $e');
      print('Error type: ${e.runtimeType}');
      print('Error string contains 422: ${e.toString().contains('422')}');
      print(
          'Error string contains не подлежит: ${e.toString().contains('не подлежит')}');

      if (mounted) {
        String errorMessage =
            'Данное объявление не подлежит бронированию'; // По умолчанию для 422 ошибки

        // Извлекаем читаемое сообщение об ошибке
        final errorString = e.toString();

        // Проверяем на конкретные ошибки
        if (errorString.contains('не подлежит бронированию') ||
            errorString.contains('422')) {
          errorMessage = 'Данное объявление не подлежит бронированию';
        } else if (errorString.contains('Требуется авторизация') ||
            errorString.contains('401')) {
          errorMessage = 'Для бронирования необходимо войти в аккаунт';
        } else if (errorString.contains('Exception:')) {
          // Извлекаем текст после последнего "Exception:"
          final parts = errorString.split('Exception:');
          if (parts.length > 1) {
            final lastPart = parts.last.trim();
            // Если в сообщении есть читаемый текст, используем его
            if (lastPart.isNotEmpty &&
                !lastPart.startsWith('Не удалось создать')) {
              errorMessage = lastPart;
            }
          }
        }

        print('Final error message: $errorMessage');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBookingLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xff183B4E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Color(0xff183B4E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Бронирование',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.productName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Price info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Стоимость аренды:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.productPrice,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff183B4E),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Booking Status info
                if (_bookingStatus != null && !_bookingStatus!.isBookable)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.block,
                          color: Colors.red[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Недоступно для бронирования',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                              if (_bookingStatus!.bookingStatus.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _bookingStatus!.bookingStatus,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_bookingStatus != null &&
                    _bookingStatus!.activeBooking != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bookmark,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Уже забронировано',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Пользователь: ${_bookingStatus!.activeBooking!.userName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                ),
                              ),
                              Text(
                                'Статус: ${_bookingStatus!.activeBooking!.statusName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                if ((_bookingStatus?.isBookable ?? true))
                  const SizedBox(height: 16),

                // Commission info
                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange[700]!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Загружаем информацию о комиссии...',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ошибка загрузки тарифа',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_commission != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Наша комиссия',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                            Text(
                              _commission!.formattedPrice,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        if (_commission!.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _commission!.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Contact message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Попробуйте оплатить комиссию для бронирования. Если объявление не подлежит бронированию, свяжитесь с арендодателем',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Contact button
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: (_isBookingLoading ||
                            (_bookingStatus != null &&
                                !_bookingStatus!.isBookable))
                        ? null
                        : _createBooking,
                    icon: _isBookingLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.monetization_on, size: 20),
                    label: Text(
                      _isBookingLoading
                          ? "Обработка..."
                          : (_bookingStatus != null &&
                                  !_bookingStatus!.isBookable)
                              ? "Недоступно для бронирования"
                              : "Оплатить комиссию",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff183B4E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
}
