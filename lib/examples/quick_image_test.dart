import 'package:flutter/material.dart';
import '../pages/story_viewer.dart';

/// Быстрый тест для проверки загрузки изображений в сториях
class QuickImageTest extends StatelessWidget {
  const QuickImageTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Быстрый тест изображений'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Тестирование загрузки изображений:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () => _testPicsumImages(context),
              child: const Text('Тест Picsum (должно работать)'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () => _testServerImages(context),
              child: const Text('Тест сервера korset.dnmc.kz'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () => _testDirectImageView(context),
              child: const Text('Прямой тест изображения'),
            ),
            
            const SizedBox(height: 30),
            
            // Прямой тест изображения прямо на этой странице
            const Text(
              'Прямой тест загрузки:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://picsum.photos/400/600?random=1',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.red[100],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Ошибка загрузки:\n$error',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testPicsumImages(BuildContext context) {
    final testStories = [
      {
        'name': 'Тест Picsum',
        'avatar': 'https://picsum.photos/150?random=100',
        'stories': [
          {
            'image': 'https://picsum.photos/400/600?random=1',
            'time': '1ч',
            'text': 'Тестовое изображение Picsum #1',
            'isVideo': false,
          }
        ],
      },
      {
        'name': 'Тест Picsum 2',
        'avatar': 'https://picsum.photos/150?random=101',
        'stories': [
          {
            'image': 'https://picsum.photos/400/600?random=2',
            'time': '2ч',
            'text': 'Тестовое изображение Picsum #2',
            'isVideo': false,
          }
        ],
      },
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerPage(
          stories: testStories,
          initialIndex: 0,
        ),
      ),
    );
  }

  void _testServerImages(BuildContext context) {
    final testStories = [
      {
        'name': 'Тест сервера',
        'avatar': 'assets/icons/guest.png',
        'stories': [
          {
            'image': 'https://korset.dnmc.kz/storage/stories/XYQFCr486WoJKQKuc3gX9WdHSHicAaCKi6I2redY.jpg',
            'time': '1ч',
            'text': 'Изображение с сервера korset.dnmc.kz',
            'isVideo': false,
          }
        ],
      },
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerPage(
          stories: testStories,
          initialIndex: 0,
        ),
      ),
    );
  }

  void _testDirectImageView(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 300,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Прямой тест изображения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: Image.network(
                  'https://korset.dnmc.kz/storage/stories/XYQFCr486WoJKQKuc3gX9WdHSHicAaCKi6I2redY.jpg',
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Загрузка... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes ?? 0}',
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Ошибка:\n$error',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
