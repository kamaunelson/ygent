import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MessageWidget extends StatelessWidget {

  final String text;
  final bool isFrontUser;
  
  const MessageWidget({
    super.key,
    required this.text,
    required this.isFrontUser,});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints( maxWidth: 520.0),
            decoration: const BoxDecoration(),
            child: Column(
              children: [
                MarkdownBody(data: text),
              ]
            ),
          )
          )
      ],
    );
  }
}