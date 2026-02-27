import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/jarvis_api.dart';
import '../services/audio_service.dart';
import '../widgets/mic_button.dart';

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});

  @override
  State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  final JarvisApi jarvisApi = JarvisApi();
  final AudioService audioService = AudioService();
  final FlutterTts flutterTts = FlutterTts();

  bool isListening = false;
  List<Map<String, String>> messages = [];

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.45);
  }

  /// Called when mic press starts
  Future<void> startListening() async {
    await audioService.startRecording();
    setState(() => isListening = true);
  }

  /// Called when mic press ends
  Future<void> stopListening() async {
    setState(() => isListening = false);

    String? path = await audioService.stopRecording();
    if (path != null) {
      sendToJarvis(path);
    }
  }

  /// Send audio to backend
  Future<void> sendToJarvis(String path) async {
    setState(() {
      messages.add({
        "role": "user",
        "text": "🎤 Voice sent",
      });
    });

    String reply = await jarvisApi.sendAudioToJarvis(path);

    setState(() {
      messages.add({
        "role": "jarvis",
        "text": reply,
      });
    });

    speak(reply);
  }

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }

  Widget buildMessage(Map<String, String> message) {
    bool isUser = message["role"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message["text"] ?? "",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    audioService.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Jarvis AI"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          /// Chat messages
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessage(messages[index]);
              },
            ),
          ),

          const SizedBox(height: 12),

          /// Mic button
          MicButton(
            isListening: isListening,
            onStart: startListening,
            onStop: stopListening,
          ),

          const SizedBox(height: 12),

          const Text(
            "Hold mic to speak",
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}