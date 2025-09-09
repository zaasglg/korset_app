import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/story_service.dart';
import '../models/story.dart';

/// Страница для отладки URL изображений в сториях
class UrlDebugTest extends StatefulWidget {
  const UrlDebugTest({super.key});

  @override
  State<UrlDebugTest> createState() => _UrlDebugTestState();
}

class _UrlDebugTestState extends State<UrlDebugTest> {
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

  String _buildImageUrl(String? mediaUrl) {
    if (mediaUrl == null) return 'Нет медиа';
    
    if (mediaUrl.startsWith('http')) {
      return mediaUrl; // Уже полный URL
    } else {
      return 'http://korset.dnmc.kz$mediaUrl'; // Используем HTTP вместо HTTPS
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отладка URL сторис'),
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
                      Text('Ошибка: $_error'),
                      ElevatedButton(
                        onPressed: _loadStories,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _stories.isEmpty
                  ? const Center(child: Text('Нет историй'))
                  : ListView.builder(
                      itemCount: _stories.length,
                      itemBuilder: (context, index) {
                        final story = _stories[index];
                        final imageUrl = _buildImageUrl(story.mediaUrl);
                        
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'История ${index + 1}: ${story.userName}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                _buildInfoRow('ID', story.id.toString()),
                                _buildInfoRow('Пользователь', story.userName),
                                _buildInfoRow('Контент', story.content ?? 'Нет текста'),
                                _buildInfoRow('Тип медиа', story.mediaType ?? 'Нет'),
                                _buildInfoRow('Оригинальный URL', story.mediaUrl ?? 'Нет'),
                                _buildInfoRow('Финальный URL', imageUrl),
                                
                                const SizedBox(height: 16),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _copyToClipboard(imageUrl),
                                        child: const Text('Копировать URL'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _testImageUrl(imageUrl),
                                        child: const Text('Тест изображения'),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Предварительный просмотр изображения
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: imageUrl.startsWith('http')
                                        ? Image.network(
                                            imageUrl,
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
                                                      const Icon(Icons.error, color: Colors.red),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Ошибка загрузки:\n$error',
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Text('Не сетевое изображение'),
                                            ),
                                          ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL скопирован в буфер обмена')),
    );
  }

  void _testImageUrl(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тест изображения'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: url.startsWith('http')
              ? Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('Ошибка: $error'),
                        ],
                      ),
                    );
                  },
                )
              : const Center(child: Text('Не сетевой URL')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
