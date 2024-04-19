import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class WindowScreen extends StatefulWidget {
  const WindowScreen({Key? key}) : super(key: key);

  @override
  _WindowScreenState createState() => _WindowScreenState();
}

class _WindowScreenState extends State<WindowScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: "AIzaSyBWzww2xQ5m_j-0KjSjAAinqIb7H_pmqmI",
    //edited out the maxOutputTokens cause its limiting the response
    //generationConfig: GenerationConfig(maxOutputTokens: 100),
  );
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    await Hive.openBox('messages');
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final box = await Hive.openBox('messages');
    setState(() {
      _messages.clear();
      _messages.addAll(box.values.map((message) => ChatMessage.fromMap(message)));
    });
  }

  Future<void> _saveMessage(ChatMessage message) async {
  final box = await Hive.openBox('messages');
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  // Ensure the key is within the valid range
  final key = timestamp % 0xFFFFFFFF; // Modulus operation to keep the key within the valid range
  await box.put(key, message.toMap());
}

  void _sendMessage() {
    String messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      ChatMessage message = ChatMessage(text: messageText, isUser: true);
      _addMessage(message);
      _saveMessage(message);
      _messageController.clear();
      _sendMessageToGemini(messageText);
    }
  }

  Future<void> _sendMessageToGemini(String message) async {
    try {
      final chat = await _model.startChat(history: []);
      final response = await chat.sendMessage(Content.text(message));
      if (response != null && response.text != null) {
        final geminiResponse = response.text!;
        _addMessage(ChatMessage(text: geminiResponse, isUser: false));
        await _saveMessage(ChatMessage(text: geminiResponse, isUser: false));
      } else {
        _addMessage(const ChatMessage(
            text: "Error: Unable to get response from Gemini", isUser: false));
      }
    } catch (error) {
      _addMessage(ChatMessage(text: "Error: $error", isUser: false));
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini AI Chat Bot'),
      ),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return _messages[index];
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({Key? key, required this.text, required this.isUser})
      : super(key: key);

  factory ChatMessage.fromMap(dynamic map) {
    return ChatMessage(
      text: map['text'],
      isUser: map['isUser'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser ? 1 : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
