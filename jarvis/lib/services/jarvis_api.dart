import 'dart:convert';
import 'package:http/http.dart' as http;

class JarvisApi {
  // 🔥 Your EC2 Public IP
  static const String baseUrl = "http://3.110.75.23:8000";

  Future<String> sendAudioToJarvis(String path) async {
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

        // 🔥 Safe extraction
        return data["jarvis_reply"] ?? data["text"] ?? "No reply from server";
      } else {
        return "Server Error: ${response.statusCode}\n$responseBody";
      }
    } catch (e) {
      return "Connection Failed: $e";
    }
  }
}
