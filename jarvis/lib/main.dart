import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: JarvisHome(),
    );
  }
}

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});

  @override
  State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  final SpeechToText speechToText = SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  final List<Map<String, String>> messages = [];

  bool isListening = false;

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  Future<void> initSpeech() async {
    await speechToText.initialize();
  }

  Future<void> startListening() async {
    await speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          stopListening();
          handleUserSpeech(result.recognizedWords);
        }
      },
    );

    setState(() {
      isListening = true;
    });
  }

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {
      isListening = false;
    });
  }

  Future<void> handleUserSpeech(String text) async {
    setState(() {
      messages.add({"role": "user", "text": text});
      messages.add({"role": "jarvis", "text": "Thinking..."});
    });

    final reply = await _askJarvis(text);

    setState(() {
      messages.removeLast();
      messages.add({"role": "jarvis", "text": reply});
    });

    speak(reply);
  }

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  // Replace this IP with your PC's IPv4 where the backend is running
  static const String _baseUrl = 'http://192.168.1.4:8000';

  Future<String> _askJarvis(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/jarvis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['reply'] ?? 'No reply';
      } else {
        return 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Cannot connect to Jarvis backend. Check your IP and server.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF001219)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'J A R V I S',
                      style: TextStyle(
                        color: Colors.cyanAccent.shade200,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final isUser = messages[index]['role'] == 'user';
                        final bubbleColor = isUser
                            ? Colors.cyanAccent
                            : Colors.grey.shade900;
                        final textColor = isUser ? Colors.black : Colors.white;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isUser)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey.shade800,
                                    child: const Icon(
                                      Icons.smart_toy,
                                      color: Colors.cyanAccent,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(14),
                                      topRight: const Radius.circular(14),
                                      bottomLeft: Radius.circular(
                                        isUser ? 14 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isUser ? 4 : 14,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    messages[index]['text']!,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              if (isUser)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.cyanAccent,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),

              // Centered animated mic button
              Align(
                alignment: Alignment(0, 0.9),
                child: GestureDetector(
                  onTap: isListening ? stopListening : startListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isListening ? 110 : 88,
                    height: isListening ? 110 : 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.18),
                          blurRadius: isListening ? 20 : 8,
                          spreadRadius: isListening ? 6 : 2,
                        ),
                      ],
                      color: isListening ? Colors.redAccent : Colors.cyanAccent,
                    ),
                    child: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      size: isListening ? 44 : 36,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
