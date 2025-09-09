import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Страница для отладки загрузки изображений
class ImageLoadingDebug extends StatefulWidget {
  const ImageLoadingDebug({super.key});

  @override
  State<ImageLoadingDebug> createState() => _ImageLoadingDebugState();
}

class _ImageLoadingDebugState extends State<ImageLoadingDebug> {
  final List<String> testUrls = [
    'https://korset.dnmc.kz/storage/stories/XYQFCr486WoJKQKuc3gX9WdHSHicAaCKi6I2redY.jpg',
    'http://korset.dnmc.kz/storage/stories/XYQFCr486WoJKQKuc3gX9WdHSHicAaCKi6I2redY.jpg',
    'https://picsum.photos/400/600?random=1',
    'https://via.placeholder.com/400x600/FF5733/FFFFFF?text=Test',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отладка загрузки изображений'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: testUrls.length,
        itemBuilder: (context, index) {
          final url = testUrls[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Тест ${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      url,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _copyUrl(url),
                          child: const Text('Копировать'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _testInBrowser(url),
                          child: const Text('Открыть в браузере'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildTestImage(url),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return Stack(
            children: [
              child,
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ЗАГРУЖЕНО',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        
        final progress = loadingProgress.cumulativeBytesLoaded / 
            (loadingProgress.expectedTotalBytes ?? 1);
        
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 16),
                Text(
                  'Загрузка... ${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${loadingProgress.cumulativeBytesLoaded} / ${loadingProgress.expectedTotalBytes ?? 0} байт',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.red[50],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[400],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'ОШИБКА ЗАГРУЗКИ',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    error.toString(),
                    style: TextStyle(
                      color: Colors.red[800],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL скопирован в буфер обмена'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _testInBrowser(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тест в браузере'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Скопируйте URL и откройте в браузере:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _copyUrl(url);
              Navigator.pop(context);
            },
            child: const Text('Копировать и закрыть'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
