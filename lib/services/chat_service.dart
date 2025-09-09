import 'package:korset_app/services/api_service.dart';
import 'package:korset_app/services/auth_service.dart';
import '../models/chat.dart';

class ChatService {
  static final ApiService _apiService = ApiService();

  /// Получить все чаты пользователя
  static Future<List<Chat>> getAllChats() async {
    try {
      print('=== Get All Chats Request ===');

      final response = await _apiService.get(
        '/api/chats',
        requiresAuth: true,
      );

      print('Get all chats response type: ${response.runtimeType}');
      print('Get all chats response: $response');

      if (response != null) {
        List<dynamic> chatsData;

        // Handle different response formats
        if (response is Map &&
            response['success'] == true &&
            response['data'] is List) {
          chatsData = response['data'];
          print('Using response[data] format, found ${chatsData.length} chats');
        } else if (response is List) {
          chatsData = response;
          print('Using direct list format, found ${chatsData.length} chats');
        } else if (response is Map && response['chats'] is List) {
          chatsData = response['chats'];
          print(
              'Using response[chats] format, found ${chatsData.length} chats');
        } else {
          print('Unexpected response format: ${response.runtimeType}');
          print(
              'Response keys: ${response is Map ? response.keys.toList() : 'Not a Map'}');
          throw Exception('Неожиданный формат ответа от сервера');
        }

        List<Chat> parsedChats = [];
        for (int i = 0; i < chatsData.length; i++) {
          try {
            print('Parsing chat $i: ${chatsData[i]}');
            final chat = Chat.fromJson(chatsData[i]);
            parsedChats.add(chat);
            print('Successfully parsed chat $i');
          } catch (e, stackTrace) {
            print('Error parsing chat $i: $e');
            print('Chat JSON: ${chatsData[i]}');
            print('Stack trace: $stackTrace');
            // Skip this chat and continue with others
            continue;
          }
        }

        return parsedChats;
      } else {
        throw Exception('Пустой ответ от сервера');
      }
    } catch (e, stackTrace) {
      print('Error getting all chats: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Ошибка при загрузке чатов: ${e.toString()}');
    }
  }

  /// Создать новый чат с продавцом товара
  static Future<Map<String, dynamic>> createChat({
    required int productId,
  }) async {
    try {
      print('=== Create Chat Request ===');
      print('Product ID: $productId');

      final response = await _apiService.post(
        '/api/chats',
        body: {
          'product_id': productId,
        },
        requiresAuth: true,
      );

      print('Create chat response: $response');

      if (response != null) {
        if (response['status'] == 'success') {
          return response['data'];
        } else if (response['success'] == true) {
          return response['data'] ?? response['chat'];
        } else if (response['id'] != null) {
          // Если нет поля success, но есть id - значит чат создан успешно
          return response;
        } else {
          throw Exception(response['message'] ?? 'Ошибка при создании чата');
        }
      } else {
        throw Exception('Пустой ответ от сервера');
      }
    } catch (e) {
      print('Error creating chat: $e');
      throw Exception('Ошибка при создании чата: ${e.toString()}');
    }
  }

  /// Отправить сообщение в чат
  static Future<Map<String, dynamic>> sendMessage({
    required int chatId,
    required String text,
  }) async {
    try {
      print('=== Send Message Request ===');
      print('Chat ID: $chatId');
      print('Text: $text');

      final response = await _apiService.post(
        '/api/chats/$chatId/messages',
        body: {
          'chat_id': chatId,
          'content': text,
        },
        requiresAuth: true,
      );

      print('Send message response: $response');

      if (response != null) {
        if (response['status'] == 'success') {
          return response['data'];
        } else if (response['success'] == true) {
          return response['data'] ?? response['message'];
        } else if (response['id'] != null || response['content'] != null) {
          // Если нет поля success, но есть id или content - значит сообщение отправлено
          return response;
        } else {
          throw Exception(
              response['message'] ?? 'Ошибка при отправке сообщения');
        }
      } else {
        throw Exception('Пустой ответ от сервера');
      }
    } catch (e) {
      print('Error sending message: $e');

      // Обрабатываем специфичные ошибки
      if (e.toString().contains('404')) {
        throw Exception('Чат не найден или нет доступа');
      } else if (e.toString().contains('422')) {
        throw Exception('Сообщение слишком длинное (максимум 1000 символов)');
      } else if (e.toString().contains('401')) {
        throw Exception('Требуется авторизация');
      } else {
        throw Exception('Ошибка при отправке сообщения: ${e.toString()}');
      }
    }
  }

  /// Отправить сообщение напрямую (альтернативный способ)
  static Future<Map<String, dynamic>> sendDirectMessage({
    required int productId,
    required int recipientId,
    required String text,
  }) async {
    try {
      print('=== Send Direct Message Request ===');
      print('Product ID: $productId');
      print('Recipient ID: $recipientId');
      print('Text: $text');

      final response = await _apiService.post(
        '/api/messages',
        body: {
          'product_id': productId,
          'recipient_id': recipientId,
          'content': text,
        },
        requiresAuth: true,
      );

      print('Send direct message response: $response');

      if (response != null) {
        if (response['status'] == 'success') {
          return response['data'];
        } else if (response['success'] == true) {
          return response['data'] ?? response['message'];
        } else if (response['id'] != null || response['content'] != null) {
          // Если нет поля success, но есть id или content - значит сообщение отправлено
          return response;
        } else {
          throw Exception(
              response['message'] ?? 'Ошибка при отправке сообщения');
        }
      } else {
        throw Exception('Пустой ответ от сервера');
      }
    } catch (e) {
      print('Error sending direct message: $e');

      // Обрабатываем специфичные ошибки
      if (e.toString().contains('422')) {
        throw Exception('Сообщение слишком длинное (максимум 1000 символов)');
      } else if (e.toString().contains('401')) {
        throw Exception('Требуется авторизация');
      } else {
        throw Exception('Ошибка при отправке сообщения: ${e.toString()}');
      }
    }
  }

  /// Полный процесс отправки сообщения (создать чат + отправить сообщение)
  static Future<Map<String, dynamic>> sendMessageToProduct({
    required int productId,
    required int recipientId,
    required String text,
  }) async {
    try {
      print('=== Starting message sending process ===');
      print('Product ID: $productId, Recipient ID: $recipientId');
      print('Message text: $text');

      // Проверяем, не пытается ли пользователь написать самому себе
      final currentUser = await AuthService.getUser();
      if (currentUser != null && currentUser['id'] == recipientId) {
        print('User trying to send message to themselves - blocking');
        throw Exception('Нельзя отправить сообщение самому себе');
      }

      // Метод 1: Попробуем отправить сообщение напрямую (часто это самый простой способ)
      try {
        print('Trying direct message approach first...');
        final result = await sendDirectMessage(
          productId: productId,
          recipientId: recipientId,
          text: text,
        );
        print('Direct message sent successfully');

        return {
          'message': result,
          'success': true,
        };
      } catch (e) {
        print('Direct message failed: $e');
      }

      // Метод 2: Создаем чат для продукта и отправляем сообщение
      try {
        print('Creating chat for product...');
        final chat = await createChat(productId: productId);
        print('Chat created/found successfully: ${chat['id']}');

        final message = await sendMessage(
          chatId: chat['id'],
          text: text,
        );
        print('Message sent via chat successfully');

        return {
          'chat': chat,
          'message': message,
          'success': true,
        };
      } catch (e) {
        print('Failed to create chat and send message: $e');

        // Проверяем специфичные ошибки
        if (e.toString().contains('400')) {
          throw Exception('Нельзя отправить сообщение по собственному товару');
        } else if (e.toString().contains('404')) {
          throw Exception('Товар не найден');
        } else if (e.toString().contains('401')) {
          throw Exception('Требуется авторизация');
        } else {
          throw Exception(
              'Не удалось отправить сообщение. Возможно, у продавца отключены сообщения или возникла техническая проблема. Попробуйте связаться через телефон или WhatsApp.');
        }
      }
    } catch (e) {
      print('Error in complete message process: $e');
      rethrow;
    }
  }

  /// Удалить чат
  static Future<bool> deleteChat(int chatId) async {
    try {
      print('=== Delete Chat Request ===');
      print('Chat ID: $chatId');

      final response = await _apiService.delete(
        '/api/chats/$chatId',
        requiresAuth: true,
      );

      print('Delete chat response: $response');

      if (response != null) {
        if (response['success'] == true) {
          return true;
        } else if (response is Map && response.containsKey('message')) {
          throw Exception(response['message']);
        } else {
          return true; // Считаем успешным если нет явной ошибки
        }
      }

      return true;
    } catch (e) {
      print('Error deleting chat: $e');
      throw Exception('Ошибка при удалении чата: ${e.toString()}');
    }
  }

  /// Удалить все чаты
  static Future<bool> deleteAllChats() async {
    try {
      print('=== Delete All Chats Request ===');

      final response = await _apiService.delete(
        '/api/chats',
        requiresAuth: true,
      );

      print('Delete all chats response: $response');

      if (response != null) {
        if (response['success'] == true) {
          return true;
        } else if (response is Map && response.containsKey('message')) {
          throw Exception(response['message']);
        } else {
          return true; // Считаем успешным если нет явной ошибки
        }
      }

      return true;
    } catch (e) {
      print('Error deleting all chats: $e');
      throw Exception('Ошибка при удалении всех чатов: ${e.toString()}');
    }
  }

  /// Получить сообщения чата
  static Future<List<ChatMessage>> getChatMessages(int chatId) async {
    try {
      print('=== Get Chat Messages Request ===');
      print('Chat ID: $chatId');

      final response = await _apiService.get(
        '/api/chats/$chatId/messages',
        requiresAuth: true,
      );

      print('Get chat messages response: $response');

      if (response != null) {
        List<dynamic> messagesData;

        if (response['status'] == 'success' && response['data'] is List) {
          messagesData = response['data'];
        } else if (response['success'] == true && response['data'] is List) {
          messagesData = response['data'];
        } else if (response is List) {
          messagesData = response;
        } else {
          throw Exception('Неожиданный формат ответа от сервера');
        }

        List<ChatMessage> messages = [];
        for (var messageData in messagesData) {
          try {
            final message = ChatMessage.fromJson(messageData);
            messages.add(message);
          } catch (e) {
            print('Error parsing message: $e');
            print('Message data: $messageData');
            // Пропускаем сообщения с ошибками парсинга
            continue;
          }
        }

        return messages;
      } else {
        throw Exception('Пустой ответ от сервера');
      }
    } catch (e) {
      print('Error getting chat messages: $e');
      throw Exception('Ошибка при загрузке сообщений: ${e.toString()}');
    }
  }
}
