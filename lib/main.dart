import 'package:flutter/material.dart';

void main() {
  runApp(const RetroAmpApp());
}

class RetroAmpApp extends StatelessWidget {
  const RetroAmpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetroAmp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const RetroAmpPlayer(),
    );
  }
}

class RetroAmpPlayer extends StatefulWidget {
  const RetroAmpPlayer({super.key});

  @override
  State<RetroAmpPlayer> createState() => _RetroAmpPlayerState();
}

class _RetroAmpPlayerState extends State<RetroAmpPlayer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RetroAmp Player'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'RetroAmp',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
