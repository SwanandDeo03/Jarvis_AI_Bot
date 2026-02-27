import 'dart:convert';
import 'package:http/http.dart' as http;

class JarvisApi {
  Future<String> sendAudioToJarvis(String path) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.4:8000/speech-to-text'),
    );

    request.files.add(await http.MultipartFile.fromPath('file', path));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var data = jsonDecode(responseBody);

    return data["jarvis_reply"];
  }
}
