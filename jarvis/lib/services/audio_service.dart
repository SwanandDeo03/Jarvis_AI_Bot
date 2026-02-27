import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  /// Start recording audio
  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      _currentPath = '${dir.path}/jarvis_audio.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 16000,
        ),
        path: _currentPath!,
      );
    } else {
      throw Exception("Microphone permission not granted");
    }
  }

  /// Stop recording and return file path
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path;
  }

  /// Check if recorder is active
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  /// Dispose recorder
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
