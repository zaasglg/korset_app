import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:korset_app/services/video_thumbnail_service.dart';

class ProductImageWidget extends StatefulWidget {
  final String? imageUrl;
  final String? videoUrl;
  final String? videoPath; // Дополнительное поле для video из Product
  final double? width;
  final double? height;
  final BoxFit fit;
  final String fallbackAsset;
  final BorderRadius? borderRadius;

  const ProductImageWidget({
    super.key,
    this.imageUrl,
    this.videoUrl,
    this.videoPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackAsset = 'assets/images/image.webp',
    this.borderRadius,
  });

  @override
  State<ProductImageWidget> createState() => _ProductImageWidgetState();
}

class _ProductImageWidgetState extends State<ProductImageWidget> {
  Uint8List? _thumbnailData;
  bool _isLoadingThumbnail = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProductImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.videoPath != widget.videoPath) {
      _loadImage();
    }
  }

  // Helper method to get a valid icon size
  double _getValidIconSize(double? width, double multiplier, double fallback) {
    if (width == null) return fallback;
    final calculatedSize = width * multiplier;
    return calculatedSize.isFinite && calculatedSize > 0
        ? calculatedSize
        : fallback;
  }

  String? get _effectiveVideoUrl {
    // Приоритет: videoUrl > videoPath
    if (widget.videoUrl != null &&
        widget.videoUrl!.isNotEmpty &&
        widget.videoUrl != 'null') {
      return widget.videoUrl;
    }
    if (widget.videoPath != null &&
        widget.videoPath!.isNotEmpty &&
        widget.videoPath != 'null') {
      return widget.videoPath;
    }
    return null;
  }

  Future<void> _loadImage() async {
    debugPrint('=== ProductImageWidget: Loading image ===');
    debugPrint('Image URL: ${widget.imageUrl}');
    debugPrint('Video URL: ${widget.videoUrl}');
    debugPrint('Video Path: ${widget.videoPath}');
    debugPrint('Effective Video URL: $_effectiveVideoUrl');

    // Сначала проверяем, есть ли основное изображение
    if (widget.imageUrl != null &&
        widget.imageUrl!.isNotEmpty &&
        widget.imageUrl != 'null') {
      debugPrint('Using main image: ${widget.imageUrl}');
      return; // Используем основное изображение
    }

    // Если нет основного изображения, но есть видео, пытаемся генерировать превью
    final videoUrl = _effectiveVideoUrl;
    if (videoUrl != null) {
      debugPrint(
          'Found video URL, attempting to generate thumbnail: $videoUrl');
      await _generateVideoThumbnail();
    } else {
      debugPrint('No valid video URL found, using fallback');
    }
  }

  Future<void> _generateVideoThumbnail() async {
    if (_isLoadingThumbnail) return;

    setState(() {
      _isLoadingThumbnail = true;
    });

    try {
      final videoUrl = _effectiveVideoUrl!;
      debugPrint('Attempting to generate thumbnail for: $videoUrl');

      // Попробуем сгенерировать превью с таймаутом
      final thumbnailData = await VideoThumbnailService.generateThumbnailData(
        videoUrl,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Thumbnail generation timed out');
          return null;
        },
      );

      if (mounted) {
        setState(() {
          _thumbnailData = thumbnailData;
          _isLoadingThumbnail = false;
        });

        if (thumbnailData != null) {
          debugPrint(
              'Thumbnail generated successfully, size: ${thumbnailData.length} bytes');
        } else {
          debugPrint(
              'Thumbnail generation returned null - will show video placeholder');
        }
      }
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
      }
    }
  }

  Widget _buildImage() {
    Widget imageWidget;

    // Приоритет: основное изображение > превью видео > fallback
    if (widget.imageUrl != null &&
        widget.imageUrl!.isNotEmpty &&
        widget.imageUrl != 'null' &&
        Uri.tryParse(widget.imageUrl!) != null &&
        (widget.imageUrl!.startsWith('http') ||
            widget.imageUrl!.startsWith('/'))) {
      // Основное изображение с CachedNetworkImage
      imageWidget = CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) {
          debugPrint(
              'CachedNetworkImage error for URL ${widget.imageUrl}: $error');
          return _buildFallbackImage();
        },
      );
    } else if (_thumbnailData != null) {
      // Превью из видео
      imageWidget = Stack(
        alignment: Alignment.center,
        children: [
          Image.memory(
            _thumbnailData!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          ),
          // Иконка воспроизведения
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      );
    } else if (_isLoadingThumbnail) {
      // Загрузка превью
      imageWidget = _buildLoadingWidget();
    } else if (_effectiveVideoUrl != null) {
      // Есть видео - показываем видео плейсхолдер
      debugPrint('Showing video placeholder for: $_effectiveVideoUrl');
      imageWidget = _buildVideoPlaceholder();
    } else {
      // Fallback изображение
      imageWidget = _buildFallbackImage();
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF183B4E)),
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF183B4E),
            Color(0xFF2A5A73),
          ],
        ),
        borderRadius: widget.borderRadius,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Паттерн в фоне
          Positioned.fill(
            child: CustomPaint(
              painter: VideoPatternPainter(),
            ),
          ),
          // Фоновая иконка видео
          Icon(
            Icons.videocam_outlined,
            size: _getValidIconSize(widget.width, 0.25, 50),
            color: Colors.white.withValues(alpha: 0.2),
          ),
          // Иконка воспроизведения
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Color(0xFF183B4E),
              size: 28,
            ),
          ),
          // Текст "Видео"
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ВИДЕО',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: Image.asset(
        widget.fallbackAsset,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: widget.borderRadius,
            ),
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 32,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildImage();
  }
}

class VideoPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Рисуем диагональные линии
    for (double i = -size.height; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
