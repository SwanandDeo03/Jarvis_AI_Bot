import 'dart:convert';
import 'package:http/http.dart' as http;

class JarvisApi {
  // 🔥 Your EC2 Public IP
  static const String baseUrl = "http://3.110.75.23:8000";

  /// Sends audio file to backend and returns a map containing
  /// - `transcript`: the transcribed user text (if provided)
  /// - `reply`: Jarvis' textual reply (if provided)
  Future<Map<String, String>> sendAudioToJarvis(String path) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/speech-to-text'),
      );

      // Attach audio file
      request.files.add(await http.MultipartFile.fromPath('file', path));

      var response = await request.send();

      // Convert stream response to string
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);

        final transcript = (data["text"] ?? data["transcript"] ?? '') as String;
        final reply = (data["jarvis_reply"] ?? data["reply"] ?? '') as String;

        return {
          'transcript': transcript,
          'reply': reply,
        };
      } else {
        return {'transcript': '', 'reply': 'Server Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'transcript': '', 'reply': 'Connection Failed: $e'};
    }
  }
}
