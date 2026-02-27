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
  final ScrollController _scrollController = ScrollController();

  bool isListening = false;
  bool isProcessing = false;
  List<Map<String, String>> messages = [];

  @override
  void initState() {
    super.initState();
    _initTTS();

    // Welcome message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          messages.add({
            "role": "jarvis",
            "text":
                "Hello! I'm Jarvis, your personal AI assistant. Tap the mic to speak.",
          });
        });
      }
    });
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.45);
  }

  /// Toggle listening on/off
  Future<void> toggleListening() async {
    if (isListening) {
      // Stop recording
      setState(() {
        isListening = false;
        isProcessing = true;
      });

      String? path = await audioService.stopRecording();
      if (path != null) {
        await sendToJarvis(path);
      }

      if (mounted) setState(() => isProcessing = false);
    } else {
      // Start recording
      await audioService.startRecording();
      setState(() => isListening = true);
    }
  }

  /// Send audio to backend
  Future<void> sendToJarvis(String path) async {
    // Show processing state while sending
    setState(() {
      isProcessing = true;
    });

    _scrollToBottom();

    final Map<String, String> result = await jarvisApi.sendAudioToJarvis(path);

    final transcript = result['transcript'] ?? '';
    final reply = result['reply'] ?? '';

    if (mounted) {
      setState(() {
        // Add the transcribed user message (if available), otherwise a generic marker
        messages.add({"role": "user", "text": transcript.isNotEmpty ? transcript : "(Voice message)"});

        // Add Jarvis' textual reply
        messages.add({"role": "jarvis", "text": reply.isNotEmpty ? reply : "No reply from server."});
        isProcessing = false;
        isListening = false;
      });

      _scrollToBottom();

      if (reply.isNotEmpty) {
        speak(reply);
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }

  Widget _buildMessage(Map<String, String> message) {
    bool isUser = message["role"] == "user";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF00BCD4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                gradient: isUser
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E1E2E), Color(0xFF2A2A3E)],
                      ),
                border: isUser
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? const Color(0xFF00BCD4).withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message["text"] ?? "",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 14.5,
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    String statusText = isProcessing
        ? "Processing..."
        : isListening
        ? "Listening..."
        : "Tap mic to speak";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isListening)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF1744),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          Text(
            statusText,
            style: TextStyle(
              color: isListening
                  ? const Color(0xFFFF1744)
                  : Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: isListening ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    audioService.dispose();
    flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A1A), Color(0xFF0D1117), Color(0xFF0A0A1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF00BCD4)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF00E5FF,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Jarvis",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00E676),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00E676,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Online",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 0.5,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white.withValues(alpha: 0.06),
              ),

              // Chat messages
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: const Color(
                                0xFF00E5FF,
                              ).withValues(alpha: 0.3),
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Tap the mic to start",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessage(messages[index]);
                        },
                      ),
              ),

              // Bottom section with mic
              Container(
                padding: const EdgeInsets.only(bottom: 20, top: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0A1A).withValues(alpha: 0.0),
                      const Color(0xFF0A0A1A),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    _buildStatusBar(),
                    const SizedBox(height: 8),
                    MicButton(
                      isListening: isListening,
                      isProcessing: isProcessing,
                      onToggle: toggleListening,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
