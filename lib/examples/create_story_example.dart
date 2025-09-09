import 'package:flutter/material.dart';
import '../pages/create_story_page.dart';

/// Пример использования виджета создания сторис
/// 
/// Этот файл показывает, как интегрировать CreateStoryPage в ваше приложение
class CreateStoryExample extends StatelessWidget {
  const CreateStoryExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пример создания сторис'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Нажмите кнопку ниже, чтобы создать историю',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openCreateStoryPage(context),
              icon: const Icon(Icons.add),
              label: const Text('Создать историю'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF183B4E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateStoryPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStoryPage(),
      ),
    );

    if (result != null && context.mounted) {
      // История была создана успешно
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('История создана! ID: ${result.id}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// Пример интеграции в существующий виджет
class StoryIntegrationExample extends StatefulWidget {
  const StoryIntegrationExample({super.key});

  @override
  State<StoryIntegrationExample> createState() => _StoryIntegrationExampleState();
}

class _StoryIntegrationExampleState extends State<StoryIntegrationExample> {
  List<String> _createdStories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Интеграция сторис'),
        actions: [
          IconButton(
            onPressed: _createStory,
            icon: const Icon(Icons.add),
            tooltip: 'Создать историю',
          ),
        ],
      ),
      body: _createdStories.isEmpty
          ? const Center(
              child: Text(
                'Нет созданных историй.\nНажмите + чтобы создать первую!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _createdStories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF183B4E),
                    child: Icon(Icons.history, color: Colors.white),
                  ),
                  title: Text('История ${index + 1}'),
                  subtitle: Text(_createdStories[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteStory(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createStory,
        backgroundColor: const Color(0xFF183B4E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _createStory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStoryPage(),
      ),
    );

    if (result != null) {
      setState(() {
        _createdStories.add(
          'Создана ${DateTime.now().toString().substring(0, 19)}'
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('История успешно создана!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _deleteStory(int index) {
    setState(() {
      _createdStories.removeAt(index);
    });
  }
}
