import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const OrigineS());
}

class OrigineS extends StatelessWidget {
  const OrigineS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Origine S',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF161616),
          primary: Color(0xFF4F7EF7),
          onSurface: Color(0xFFDCDCDC),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0B0B),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}