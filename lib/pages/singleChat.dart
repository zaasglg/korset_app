import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class SingleChatPage extends StatefulWidget {
  const SingleChatPage({super.key});

  @override
  State<SingleChatPage> createState() => _SingleChatPageState();
}

class _SingleChatPageState extends State<SingleChatPage> {
  final List<Map<String, dynamic>> messages = [
    {"text": "Добро пожаловать! Чем я могу помочь?", "isMe": false} // Сообщение от "Korset"
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        messages.add({"text": _controller.text.trim(), "isMe": true}); // Сообщение от пользователя
        _controller.clear();
      });
    }
  }

  Future<void> _refreshMessages() async {
    // Имитация обновления данных
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Здесь ничего не добавляем, просто обновляем состояние
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Основной фон чата серый
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white, // Фон AppBar тоже серый
        leading: IconButton(
          icon: const Icon(IconlyBroken.arrowLeft, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop(); // Возврат на предыдущую страницу
          },
        ),
        title: const Text(
          "Чат",
          style: TextStyle(
            fontFamily: "avenir",
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshMessages, // Метод для обновления
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final isMe = messages[index]["isMe"]; // Проверяем, кто отправил сообщение
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Добавлен padding
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue : Colors.grey[400],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12.0),
                          topRight: const Radius.circular(12.0),
                          bottomLeft: isMe ? const Radius.circular(12.0) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        messages[index]["text"],
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 30.0), 
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Белый фон
                borderRadius: BorderRadius.circular(20.0),
                
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Введите сообщение...",
                        border: InputBorder.none, // Убираем стандартную границу
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: const BorderSide(color: CupertinoColors.systemGrey5, width: 1.0), // Граница в неактивном состоянии
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: const BorderSide(color: Colors.blue, width: 2.0), // Граница в активном состоянии
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
