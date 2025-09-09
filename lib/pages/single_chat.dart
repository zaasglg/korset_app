import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'detail.dart';

class SingleChatPage extends StatefulWidget {
  final Chat? chat;
  final int? chatId;

  const SingleChatPage({
    super.key,
    this.chat,
    this.chatId,
  }) : assert(chat != null || chatId != null,
            'Either chat or chatId must be provided');

  @override
  State<SingleChatPage> createState() => _SingleChatPageState();
}

class _SingleChatPageState extends State<SingleChatPage> {
  List<ChatMessage> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  int? _currentUserId;

  // Chat info
  int get _chatId => widget.chatId ?? widget.chat?.id ?? 0;
  String get _chatTitle =>
      widget.chat?.sellerName ?? widget.chat?.displayName ?? 'Чат';
  String? get _chatAvatar =>
      widget.chat?.sellerAvatar ?? widget.chat?.avatarUrl;

  @override
  void initState() {
    super.initState();

    // Отладочная информация о продукте
    if (widget.chat?.product != null) {
      print('=== PRODUCT DEBUG INFO ===');
      print('Product ID: ${widget.chat!.product.id}');
      print('Product Title: ${widget.chat!.product.title}');
      print('Product Price: ${widget.chat!.product.price}');
      print('Product ImageUrl: ${widget.chat!.product.imageUrl}');
      print('Product Video: ${widget.chat!.product.video}');
      print('Product Description: ${widget.chat!.product.description}');
      print('========================');
    } else {
      print('No product found in chat');
    }

    _loadCurrentUser();
    _loadMessages();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getUser();
      if (user != null) {
        setState(() {
          _currentUserId = user['id'];
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_chatId == 0) {
      setState(() {
        _error = 'ID чата не найден';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final loadedMessages = await ChatService.getChatMessages(_chatId);

      if (mounted) {
        setState(() {
          messages = loadedMessages;
          _isLoading = false;
        });

        // Прокручиваем к последнему сообщению после загрузки
        if (messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _controller.text.trim();
    if (messageText.isEmpty || _isSending || _chatId == 0) return;

    if (messageText.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сообщение слишком длинное (максимум 1000 символов)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final sentMessageData = await ChatService.sendMessage(
        chatId: _chatId,
        text: messageText,
      );

      if (mounted) {
        _controller.clear();

        // Создаем объект сообщения из ответа API
        try {
          final newMessage = ChatMessage.fromJson(sentMessageData);
          setState(() {
            messages.add(newMessage);
          });

          // Прокручиваем к последнему сообщению
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } catch (e) {
          print('Error parsing sent message: $e');
          // Если не удалось распарсить, перезагружаем все сообщения
          await _loadMessages();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _refreshMessages() async {
    await _loadMessages();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = _currentUserId != null && message.userId == _currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF183B4E) : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft:
                isMe ? const Radius.circular(16.0) : const Radius.circular(4.0),
            bottomRight:
                isMe ? const Radius.circular(4.0) : const Radius.circular(16.0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                message.user.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'Сейчас';
    }
  }

  Widget _buildChatAvatar() {
    final avatarUrl = _chatAvatar;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      String fullUrl = avatarUrl;

      // Construct full URL if needed
      if (avatarUrl.startsWith('/')) {
        fullUrl = 'https://videopokaz.kz/storage$avatarUrl';
      } else if (!avatarUrl.startsWith('http')) {
        fullUrl = 'https://videopokaz.kz/storage/$avatarUrl';
      }

      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        child: ClipOval(
          child: Image.network(
            fullUrl,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to initials if image fails to load
              return _buildInitialsAvatar();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: const Color(0xFF183B4E),
                ),
              );
            },
          ),
        ),
      );
    }

    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF183B4E),
      child: Text(
        _getInitials(_chatTitle),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildProductMedia(ChatProduct product) {
    print('Product video: ${product.video}'); // Для отладки
    print('Product imageUrl: ${product.imageUrl}'); // Для отладки

    // Сначала проверяем видео
    if (product.video != null && product.video!.trim().isNotEmpty) {
      final videoUrl = product.video!.trim();
      final isVideo = _isVideoUrl(videoUrl);

      print('Is video: $isVideo, Video URL: $videoUrl'); // Для отладки

      if (isVideo) {
        return _buildVideoThumbnail(videoUrl);
      }
    }

    // Если видео нет или это не видео файл, используем изображение
    if (product.imageUrl != null && product.imageUrl!.trim().isNotEmpty) {
      return _buildImage(product.imageUrl!);
    }

    // Fallback если нет ни видео ни изображения
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey[400],
        size: 24,
      ),
    );
  }

  bool _isVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.contains(ext));
  }

  Widget _buildVideoThumbnail(String videoUrl) {
    print("videoUrl ${videoUrl}");

    // Формируем полный URL если нужно
    String fullVideoUrl = videoUrl;
    if (videoUrl.startsWith('/')) {
      fullVideoUrl = 'https://videopokaz.kz/storage$videoUrl';
    } else if (!videoUrl.startsWith('http')) {
      fullVideoUrl = 'https://videopokaz.kz/storage/$videoUrl';
    }

    print("Full video URL: $fullVideoUrl");

    return FutureBuilder<String?>(
      future: _generateThumbnail(fullVideoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF183B4E),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Stack(
            children: [
              Image.file(
                File(snapshot.data!),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildVideoIcon();
                },
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          );
        }

        return _buildVideoIcon();
      },
    );
  }

  Widget _buildVideoIcon() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.videocam,
          color: Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    // Формируем полный URL если нужно
    String fullUrl = imageUrl;
    if (imageUrl.startsWith('/')) {
      fullUrl = 'https://videopokaz.kz/storage$imageUrl';
    } else if (!imageUrl.startsWith('http')) {
      fullUrl = 'https://videopokaz.kz/storage/$imageUrl';
    }

    print('Loading image: $fullUrl'); // Для отладки

    return Image.network(
      fullUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error'); // Для отладки
        return Container(
          width: 60,
          height: 60,
          color: Colors.grey[200],
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey[400],
            size: 24,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 60,
          height: 60,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF183B4E),
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Future<String?> _generateThumbnail(String videoUrl) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: null, // Автоматически создаст временный файл
        imageFormat: ImageFormat.JPEG,
        maxHeight: 60,
        maxWidth: 60,
        quality: 75,
      );
      return thumbnailPath;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildProductCard() {
    if (widget.chat?.product == null) return const SizedBox.shrink();

    final product = widget.chat!.product;

    return GestureDetector(
      onTap: () {
        // Navigate to product detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(
              productId: product.id,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.lightBlueAccent.withOpacity(0.1), // Легкий синий фон
        ),
        child: Row(
          children: [
            // Product image/video
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildProductMedia(product),
              ),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.price.toStringAsFixed(0)} ₸',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF183B4E),
                    ),
                  ),
                ],
              ),
            ),
            // View product button
            Container(
              decoration: BoxDecoration(),
              child: const Icon(
                IconlyBroken.arrowRightCircle,
                size: 22,
                color: Color(0xFF183B4E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            _buildChatAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _chatTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Product card at the top
          _buildProductCard(),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF183B4E),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Ошибка загрузки',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF183B4E),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  IconlyBroken.chat,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Нет сообщений',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Начните общение',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshMessages,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16.0),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                return _buildMessageBubble(messages[index]);
                              },
                            ),
                          ),
          ),
          Container(
            padding: const EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 16.0,
              bottom: 32.0,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 1000,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Введите сообщение...",
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF183B4E),
                          width: 2.0,
                        ),
                      ),
                      counterText: '', // Скрываем счетчик
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF183B4E),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
