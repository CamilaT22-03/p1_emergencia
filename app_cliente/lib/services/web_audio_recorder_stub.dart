import 'dart:typed_data';

class RecordedAudio {
  final Uint8List bytes;
  final String nombreArchivo;
  final String mimeType;

  const RecordedAudio({
    required this.bytes,
    required this.nombreArchivo,
    required this.mimeType,
  });
}

class WebAudioRecorder {
  bool get isRecording => false;

  Future<bool> hasPermission() async => false;

  Future<void> start() async {
    throw UnsupportedError('Grabación de audio no disponible en esta plataforma.');
  }

  Future<RecordedAudio?> stop() async => null;
}