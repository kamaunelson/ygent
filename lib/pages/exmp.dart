import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-pro', // Using Gemini Pro model
    apiKey: "AIzaSyBWzww2xQ5m_j-0KjSjAAinqIb7H_pmqmI",
    generationConfig: GenerationConfig(maxOutputTokens: 100),
  );
  final List<ChatMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Gemini AI Chat Bot'),
        ),
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

  void _sendMessage() {
    String messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      _addMessage(messageText, isUser: true);
      _messageController.clear();
      _sendMessageToGemini(messageText);
    }
  }

  Future<void> _sendMessageToGemini(String message) async {
  try {
    // Clear previous messages
    _clearMessages();

    // Initiate chat with an empty history
    final chat = await _model.startChat(history: []);

    // Send the text message
    final response = await chat.sendMessage(Content.text(message));

    // Extract the text response from Gemini
    final geminiResponse = response.text;
    _addMessage(geminiResponse!, isUser: false);
    } catch (error) {
    _addMessage("Error: $error", isUser: false);
  }
}


  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
    });
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({Key? key, required this.text, required this.isUser}) : super(key: key);

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