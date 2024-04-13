import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Database _database;
  final TextEditingController _messageController = TextEditingController();
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: "AIzaSyBWzww2xQ5m_j-0KjSjAAinqIb7H_pmqmI",
    generationConfig: GenerationConfig(maxOutputTokens: 100),
  );
  final List<ChatMessage> _messages = [];

  @override
  // Initializes the state of the chat screen. Calls _initDatabase to set up the database.
  void initState() {
    super.initState();
    _initDatabase();
  }

  // Initializes the database by opening a database connection and creating a 'messages' table if it doesn't exist. Loads messages from the database after initialization.
  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'chat_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE messages(id INTEGER PRIMARY KEY, text TEXT, isUser INTEGER)',
        );
      },
      version: 1,
    );
    _loadMessages();
  }

  // Asynchronously loads messages from the database and updates the UI state with the new messages.
  Future<void> _loadMessages() async {
    final List<Map<String, dynamic>> messages =
        await _database.query('messages');
    setState(() {
      _messages.clear();
      _messages.addAll(messages.map((message) => ChatMessage.fromMap(message)));
    });
  }

  // Saves a ChatMessage to the database.
  Future<void> _saveMessage(ChatMessage message) async {
    await _database.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Sends a chat message if the message text is not empty, adds the message to the UI, saves it to the database, and sends it to Gemini.
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

  // Asynchronously sends a message to Gemini chat service using the provided message string.
  Future<void> _sendMessageToGemini(String message) async {
    try {
      final chat = await _model.startChat(history: []);
      final response = await chat.sendMessage(Content.text(message));
      final geminiResponse = response.text;
      _addMessage(ChatMessage(text: geminiResponse!, isUser: false));
    } catch (error) {
      _addMessage(ChatMessage(text: "Error: $error", isUser: false));
    }
  }

  // Adds a ChatMessage to the list of messages and triggers a state update to reflect the change.
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

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
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
