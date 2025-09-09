import 'package:flutter/foundation.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class VideoThumbnailService {
  /// Генерирует превью изображение из видео файла
  static Future<String?> generateThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_thumbnail.jpg';
      final thumbnailPath = path.join(tempDir.path, fileName);

      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300, // Ограничиваем высоту для оптимизации
        quality: 75, // Качество изображения
        timeMs: 1000, // Берем кадр на 1 секунде
      );

      return thumbnail;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  /// Генерирует превью из URL видео
  static Future<String?> generateThumbnailFromUrl(String videoUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_thumbnail.jpg';
      final thumbnailPath = path.join(tempDir.path, fileName);

      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 75,
        timeMs: 1000,
      );

      return thumbnail;
    } catch (e) {
      debugPrint('Error generating video thumbnail from URL: $e');
      return null;
    }
  }

  /// Генерирует превью в виде Uint8List для отображения в виджете
  static Future<Uint8List?> generateThumbnailData(String videoPath) async {
    try {
      debugPrint('VideoThumbnailService: Generating thumbnail for: $videoPath');
      
      // Проверяем валидность URL/пути
      if (videoPath.isEmpty || videoPath == 'null') {
        debugPrint('VideoThumbnailService: Empty or null video path');
        return null;
      }
      
      // Если это URL, проверяем его валидность
      if (videoPath.startsWith('http')) {
        final uri = Uri.tryParse(videoPath);
        if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
          debugPrint('VideoThumbnailService: Invalid video URL: $videoPath');
          return null;
        }
      }
      
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200, // Уменьшаем размер для быстрой загрузки
        quality: 60,    // Уменьшаем качество для быстрой загрузки
        timeMs: 500,    // Берем кадр раньше
      );

      if (thumbnailData != null) {
        debugPrint('VideoThumbnailService: Thumbnail generated successfully, size: ${thumbnailData.length} bytes');
      } else {
        debugPrint('VideoThumbnailService: Thumbnail generation returned null');
      }

      return thumbnailData;
    } catch (e) {
      debugPrint('VideoThumbnailService: Error generating video thumbnail data: $e');
      
      // Попробуем с другими параметрами
      try {
        debugPrint('VideoThumbnailService: Trying alternative parameters...');
        final thumbnailData = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.PNG,
          maxHeight: 150,
          quality: 50,
          timeMs: 0, // Первый кадр
        );
        
        if (thumbnailData != null) {
          debugPrint('VideoThumbnailService: Alternative thumbnail generated successfully');
        }
        
        return thumbnailData;
      } catch (e2) {
        debugPrint('VideoThumbnailService: Alternative method also failed: $e2');
        return null;
      }
    }
  }

  /// Проверяет, является ли файл видео
  static bool isVideoFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv', '.webm']
        .contains(extension);
  }

  /// Проверяет, является ли URL видео файлом
  static bool isVideoUrl(String url) {
    debugPrint('VideoThumbnailService.isVideoUrl: Checking URL: $url');
    
    if (url.isEmpty || url == 'null') {
      debugPrint('VideoThumbnailService.isVideoUrl: Empty or null URL');
      return false;
    }
    
    final uri = Uri.tryParse(url);
    if (uri == null) {
      debugPrint('VideoThumbnailService.isVideoUrl: Invalid URI');
      return false;
    }
    
    final urlLower = url.toLowerCase();
    
    // Расширенная проверка видео форматов
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv', '.webm', '.m4v', '.3gp', '.mpg', '.mpeg'];
    final hasVideoExtension = videoExtensions.any((ext) => urlLower.contains(ext));
    
    // Также проверяем наличие слова "video" в URL или пути
    final hasVideoInPath = urlLower.contains('video') || urlLower.contains('/videos/');
    
    // Проверяем MIME type в URL (��сли есть)
    final hasMimeType = urlLower.contains('video/');
    
    // Проверяем поле video из базы данных (может содержать путь к видео без расширения)
    final hasVideoField = url.contains('storage/') && (hasVideoExtension || hasVideoInPath);
    
    // Дополнительная проверка: если URL содержит storage/ и не содержит изображения
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    final hasImageExtension = imageExtensions.any((ext) => urlLower.contains(ext));
    final isStorageVideo = url.contains('storage/') && !hasImageExtension;
    
    final isVideo = hasVideoExtension || hasVideoInPath || hasMimeType || hasVideoField || isStorageVideo;
    debugPrint('VideoThumbnailService.isVideoUrl: Has video extension: $hasVideoExtension');
    debugPrint('VideoThumbnailService.isVideoUrl: Has video in path: $hasVideoInPath');
    debugPrint('VideoThumbnailService.isVideoUrl: Has MIME type: $hasMimeType');
    debugPrint('VideoThumbnailService.isVideoUrl: Has video field: $hasVideoField');
    debugPrint('VideoThumbnailService.isVideoUrl: Is storage video: $isStorageVideo');
    debugPrint('VideoThumbnailService.isVideoUrl: Result: $isVideo');
    
    return isVideo;
  }
}
