class Story {
  final int id;
  final String? content;
  final String? mediaUrl;
  final String? mediaType; // 'image' or 'video'
  final DateTime createdAt;
  final DateTime expiresAt;
  final int userId;
  final String userName;
  final String? userAvatar;

  Story({
    required this.id,
    this.content,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    required this.userId,
    required this.userName,
    this.userAvatar,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    // Извлекаем данные пользователя из вложенного объекта
    final user = json['user'] as Map<String, dynamic>?;

    return Story(
      id: json['id'] ?? 0,
      content: json['content'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().add(const Duration(hours: 24)).toIso8601String()),
      userId: json['user_id'] ?? user?['id'] ?? 0,
      userName: user?['name'] ?? json['user_name'] ?? 'Пользователь',
      userAvatar: user?['avatar'] ?? json['user_avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
  
  bool get isVideo => mediaType == 'video';
  
  bool get isImage => mediaType == 'image';
}