import '../config/api_config.dart';

class ImageUrlHelper {
  /// Генерирует полный URL для изображения
  static String getImageUrl(String? imagePath, {bool useSecure = false}) {
    if (imagePath == null || imagePath.isEmpty || imagePath == 'null') {
      return '';
    }
    // Нормализуем пробелы
    final p = imagePath.trim();

    // Если уже полный URL
    if (p.startsWith('http://') || p.startsWith('https://')) {
      return p;
    }

    final baseUrl = ApiConfig.getBaseUrl(useSecure: useSecure);

    // Если путь уже начинается с /storage/
    if (p.startsWith('/storage/')) {
      return '$baseUrl$p';
    }

    // Если путь начинается с storage/
    if (p.startsWith('storage/')) {
      return '$baseUrl/$p';
    }

    // Если путь начинается с корня
    if (p.startsWith('/')) {
      return '$baseUrl$p';
    }

    // Обычный относительный путь (сохраняем совместимость)
    return '$baseUrl/storage/$p';
  }

  /// Генерирует полный URL для видео
  static String getVideoUrl(String? videoPath, {bool useSecure = false}) {
    if (videoPath == null || videoPath.isEmpty || videoPath == 'null') {
      return '';
    }

    // Если уже полный URL
    if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
      return videoPath;
    }

    // Формируем URL относительно базового API URL
    final baseUrl = ApiConfig.getBaseUrl(useSecure: useSecure);
    return '$baseUrl/storage/$videoPath';
  }

  /// Проверяет, является ли путь валидным
  static bool isValidPath(String? path) {
    return path != null && path.isNotEmpty && path != 'null';
  }
}
