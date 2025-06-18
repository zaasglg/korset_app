import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:korset_app/pages/singleChat.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, dynamic>> chats = [
    {
      "name": "Korset.kz",
      "message": "Добро пожаловать! Мы здесь, чтобы помочь вам",
      "time": "2:30 PM",
      "avatar": "https://image.winudf.com/v2/image1/Y29tLndpdGhjaGF0dGluZy5hc3Npc3RhbnRtZXNzYWdlc19pY29uXzE2MzcyNDA0NDBfMDQ1/icon.png?w=340&fakeurl=1",
      "isOnline": true,
      "unreadCount": 0,
      "lastSeen": "В сети"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          "Сообщения",
          style: TextStyle(
            fontWeight: FontWeight.w600, 
            color: Colors.black, 
            fontSize: 18
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_horiz,
              color: Colors.black54,
              size: 20,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            onSelected: (String value) {
              if (value == 'clear') {
                _showClearMessagesDialog();
              } else if (value == 'refresh') {
                _refreshChats();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'refresh',
                height: 44,
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_outlined,
                      color: Colors.black87,
                      size: 18,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Обновить',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'clear',
                height: 44,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red[400],
                      size: 18,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Очистить сообщения',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: chats.isEmpty 
        ? _buildEmptyState()
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Color(0xFFF0F0F0),
            ),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatTile(chat, context);
            },
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconlyBroken.chat,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            "Нет сообщений",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Начните общение с поддержкой",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SingleChatPage(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            // Simple avatar
            CircleAvatar(
              backgroundImage: NetworkImage(chat["avatar"]!),
              radius: 24,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat["name"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        chat["time"]!,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat["message"]!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (chat["unreadCount"] > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF183B4E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearMessagesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Simple icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Очистить сообщения?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  'Все сообщения будут удалены без возможности восстановления.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Отмена',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            chats.clear();
                          });
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Сообщения очищены',
                                style: TextStyle(fontSize: 14),
                              ),
                              backgroundColor: Colors.black87,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Очистить',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _refreshChats() {
    // Имитируем обновление данных
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Сообщения обновлены',
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Здесь может быть логика для обновления чатов с сервера
    setState(() {
      // Можно добавить логику обновления
    });
  }
}
