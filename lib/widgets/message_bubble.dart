import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isStreaming;

  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isUser ? 'Vous' : 'Origine S',
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          if (isUser)
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF131C2E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E2D4A)),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Color(0xFFDCDCDC),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: message.content + (isStreaming ? ' ▋' : ''),
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      color: Color(0xFFDCDCDC),
                      fontSize: 14,
                      height: 1.7,
                    ),
                    code: const TextStyle(
                      color: Color(0xFFC9D1D9),
                      fontSize: 13,
                      fontFamily: 'monospace',
                      backgroundColor: Color(0xFF161616),
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: const Color(0xFF1F1F1F)),
                    ),
                    codeblockPadding: const EdgeInsets.all(12),
                    h1: const TextStyle(
                        color: Color(0xFFDCDCDC),
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                    h2: const TextStyle(
                        color: Color(0xFFDCDCDC),
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                    h3: const TextStyle(
                        color: Color(0xFFDCDCDC),
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    listBullet: const TextStyle(
                        color: Color(0xFFDCDCDC), fontSize: 14),
                    blockquote: const TextStyle(
                        color: Color(0xFF555555), fontSize: 14),
                  ),
                ),
                if (!isStreaming && message.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: message.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copie'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Color(0xFF161616),
                          ),
                        );
                      },
                      child: const Text(
                        'Copier',
                        style: TextStyle(
                            color: Color(0xFF555555), fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}