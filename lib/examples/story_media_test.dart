import 'package:flutter/material.dart';
import '../pages/story_viewer.dart';

/// Тестовая страница для проверки отображения медиа в сториях
class StoryMediaTest extends StatelessWidget {
  const StoryMediaTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест медиа в сториях'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Тестирование различных типов медиа в сториях:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () => _testNetworkImages(context),
              child: const Text('Тест сетевых изображений'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () => _testAssetImages(context),
              child: const Text('Тест локальных изображений'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () => _testMixedImages(context),
              child: const Text('Тест смешанных изображений'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () => _testRealApiFormat(context),
              child: const Text('Тест формата реального API'),
            ),
            
            const SizedBox(height: 30),
            const Text(
              'Инструкции:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Нажмите на любую кнопку для тестирования\n'
              '2. Проверьте, что изображения загружаются\n'
              '3. Если видите черный экран - проблема с URL\n'
              '4. Проверьте консоль для отладочной информации',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _testNetworkImages(BuildContext context) {
    final testStories = [
      {
        'name': 'Тест сети',
        'avatar': 'https://via.placeholder.com/150',
        'stories': [
          {
            'image': 'https://via.placeholder.com/400x600/FF5733/FFFFFF?text=Test+Image+1',
            'time': '2ч',
            'text': 'Тестовое изображение из сети',
            'isVideo': false,
          }
        ],
      },
      {
        'name': 'Тест 2',
        'avatar': 'https://via.placeholder.com/150',
        'stories': [
          {
            'image': 'https://picsum.photos/400/600?random=1',
            'time': '1ч',
            'text': 'Случайное изображение',
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

  void _testAssetImages(BuildContext context) {
    final testStories = [
      {
        'name': 'Локальные',
        'avatar': 'assets/icons/guest.png',
        'stories': [
          {
            'image': 'assets/images/image.webp',
            'time': '3ч',
            'text': 'Локальное изображение',
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

  void _testMixedImages(BuildContext context) {
    final testStories = [
      {
        'name': 'Сеть',
        'avatar': 'https://via.placeholder.com/150',
        'stories': [
          {
            'image': 'https://picsum.photos/400/600?random=2',
            'time': '1ч',
            'text': 'Сетевое изображение',
            'isVideo': false,
          }
        ],
      },
      {
        'name': 'Локальное',
        'avatar': 'assets/icons/guest.png',
        'stories': [
          {
            'image': 'assets/images/image.webp',
            'time': '2ч',
            'text': 'Локальное изображение',
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

  void _testRealApiFormat(BuildContext context) {
    // Имитируем формат данных из реального API
    final testStories = [
      {
        'name': 'Erdauletter',
        'avatar': 'assets/icons/guest.png',
        'stories': [
          {
            'image': 'https://korset.dnmc.kz/storage/stories/XYQFCr486WoJKQKuc3gX9WdHSHicAaCKi6I2redY.jpg',
            'time': '1ч',
            'text': 'ergerg',
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
}

/// Простой виджет для быстрого тестирования
class QuickStoryTest extends StatelessWidget {
  const QuickStoryTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Быстрый тест')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StoryMediaTest(),
              ),
            );
          },
          child: const Text('Открыть тест медиа'),
        ),
      ),
    );
  }
}
