class Chat {
  final int id;
  final int userId;
  final int productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatUser user;
  final ChatUser seller;
  final ChatProduct product;
  final List<ChatMessage> messages;

  Chat({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.seller,
    required this.product,
    required this.messages,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing Chat JSON: $json');

      final id = _parseInt(json['id']);
      print('Parsed id: $id');

      final userId = _parseInt(json['user_id']);
      print('Parsed userId: $userId');

      final productId = _parseInt(json['product_id']);
      print('Parsed productId: $productId');

      final createdAt = DateTime.parse(json['created_at']);
      print('Parsed createdAt: $createdAt');

      final updatedAt = DateTime.parse(json['updated_at']);
      print('Parsed updatedAt: $updatedAt');

      print('Parsing user: ${json['user']}');
      final user = ChatUser.fromJson(json['user']);
      print('Parsed user: ${user.name}');

      print('Parsing seller: ${json['seller']}');
      final seller = ChatUser.fromJson(json['seller']);
      print('Parsed seller: ${seller.name}');

      print('Parsing product: ${json['product']}');
      final product = ChatProduct.fromJson(json['product']);
      print('Parsed product: ${product.title}');

      print('Parsing messages: ${json['messages']}');
      final messages = (json['messages'] as List? ?? []).map((message) {
        print('Parsing message: $message');
        return ChatMessage.fromJson(message);
      }).toList();
      print('Parsed ${messages.length} messages');

      return Chat(
        id: id,
        userId: userId,
        productId: productId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        user: user,
        seller: seller,
        product: product,
        messages: messages,
      );
    } catch (e, stackTrace) {
      print('Error in Chat.fromJson: $e');
      print('JSON: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper methods for UI
  String get lastMessage {
    if (messages.isEmpty) return '';
    return messages.last.content;
  }

  String get lastMessageTime {
    if (messages.isEmpty) return '';
    final lastMsg = messages.last;
    final now = DateTime.now();
    final diff = now.difference(lastMsg.createdAt);

    if (diff.inDays > 0) {
      return '${diff.inDays}д назад';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}ч назад';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}м назад';
    } else {
      return 'Сейчас';
    }
  }

  int get unreadCount {
    // This would need to be implemented based on your API
    // For now, returning 0
    return 0;
  }

  bool get isOnline {
    // This would need to be implemented based on your API
    // For now, returning false
    return false;
  }

  String get displayName {
    return user.name;
  }

  String? get avatarUrl {
    return user.avatar;
  }

  // Геттеры для продавца
  String get sellerName {
    return seller.name;
  }

  String? get sellerAvatar {
    return seller.avatar;
  }

  String? get sellerPhone {
    return seller.phoneNumber;
  }

  bool get sellerIsActive {
    return seller.isActive;
  }

  String get sellerFullName {
    if (seller.surname != null && seller.surname!.isNotEmpty) {
      return '${seller.name} ${seller.surname}';
    }
    return seller.name;
  }
}

class ChatUser {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? phoneNumber;
  final String? surname;
  final int? cityId;
  final bool isActive;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.phoneNumber,
    this.surname,
    this.cityId,
    this.isActive = true,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing ChatUser JSON: $json');
      return ChatUser(
        id: _parseInt(json['id']),
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        avatar: json['avatar'] ??
            json['profile_photo'] ??
            json['photo'] ??
            json['image'],
        phoneNumber: json['phone_number'],
        surname: json['surname'],
        cityId: json['city_id'] != null ? _parseInt(json['city_id']) : null,
        isActive: json['is_active'] ?? true,
      );
    } catch (e, stackTrace) {
      print('Error in ChatUser.fromJson: $e');
      print('JSON: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class ChatProduct {
  final int id;
  final String title;
  final double price;
  final String? imageUrl;
  final String? description;
  final String? video;

  ChatProduct({
    required this.id,
    required this.title,
    required this.price,
    this.imageUrl,
    this.description,
    this.video,
  });

  factory ChatProduct.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing ChatProduct JSON: $json');

      // Функция для получения не-пустой строки или null
      String? getNonEmptyString(dynamic value) {
        if (value == null) return null;
        final str = value.toString().trim();
        return str.isEmpty ? null : str;
      }

      return ChatProduct(
        id: _parseInt(json['id']),
        title: json['name'] ?? '',
        price: _parseDouble(json['price']),
        imageUrl: getNonEmptyString(json['image_url']) ??
            getNonEmptyString(json['image']) ??
            getNonEmptyString(json['photo']) ??
            getNonEmptyString(json['main_photo']),
        description: getNonEmptyString(json['description']),
        video: getNonEmptyString(json['video']) ??
            getNonEmptyString(json['video_url']),
      );
    } catch (e, stackTrace) {
      print('Error in ChatProduct.fromJson: $e');
      print('JSON: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ChatMessage {
  final int id;
  final int chatId;
  final int userId;
  final String content;
  final DateTime createdAt;
  final ChatUser user;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.user,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing ChatMessage JSON: $json');
      return ChatMessage(
        id: _parseInt(json['id']),
        chatId: _parseInt(json['chat_id']),
        userId: _parseInt(json['user_id']),
        content: json['content'] ?? '',
        createdAt: DateTime.parse(json['created_at']),
        user: ChatUser.fromJson(json['user']),
      );
    } catch (e, stackTrace) {
      print('Error in ChatMessage.fromJson: $e');
      print('JSON: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
