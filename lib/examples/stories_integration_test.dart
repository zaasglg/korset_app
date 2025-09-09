import 'package:flutter/material.dart';
import '../services/story_service.dart';
import '../models/story.dart';

/// Тестовая страница для проверки интеграции сторис с API
class StoriesIntegrationTest extends StatefulWidget {
  const StoriesIntegrationTest({super.key});

  @override
  State<StoriesIntegrationTest> createState() => _StoriesIntegrationTestState();
}

class _StoriesIntegrationTestState extends State<StoriesIntegrationTest> {
  List<Story> _stories = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stories = await StoryService.getStories();
      setState(() {
        _stories = stories;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест сторис API'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStories,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка загрузки:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStories,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _stories.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_edu,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Нет историй',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Создайте первую историю!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _stories.length,
                      itemBuilder: (context, index) {
                        final story = _stories[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                story.userName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(story.userName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (story.content != null) ...[
                                  Text(story.content!),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  'Тип: ${story.mediaType ?? "текст"} • '
                                  'Создано: ${_formatDate(story.createdAt)} • '
                                  'Истекает: ${_formatDate(story.expiresAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: story.isExpired
                                ? const Icon(Icons.timer_off, color: Colors.red)
                                : const Icon(Icons.timer, color: Colors.green),
                          ),
                        );
                      },
                    ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Виджет для быстрого тестирования API
class QuickStoriesTest extends StatelessWidget {
  const QuickStoriesTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Быстрый тест API'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _testGetStories(context),
              child: const Text('Тест GET /api/stories-guest'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StoriesIntegrationTest(),
                  ),
                );
              },
              child: const Text('Полный тест интеграции'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testGetStories(BuildContext context) async {
    try {
      final stories = await StoryService.getStories();
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Результат теста'),
            content: Text(
              'Загружено историй: ${stories.length}\n\n'
              'Детали:\n${stories.map((s) => '• ${s.userName}: ${s.content ?? "медиа"}').join('\n')}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ошибка'),
            content: Text('Ошибка загрузки: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
