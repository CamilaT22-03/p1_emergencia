import 'dart:async';
import 'dart:html' as html;
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
  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = [];

  bool get isRecording => _recorder?.state == 'recording';

  Future<bool> hasPermission() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        return false;
      }

      final stream = await mediaDevices.getUserMedia({'audio': true});
      for (final track in stream.getTracks()) {
        track.stop();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> start() async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw StateError('El navegador no soporta captura de audio.');
    }

    _chunks.clear();
    _stream = await mediaDevices.getUserMedia({'audio': true});
    _recorder = html.MediaRecorder(_stream!, {'mimeType': 'audio/webm'});
    _recorder!.addEventListener('dataavailable', (event) {
      final data = (event as html.BlobEvent).data;
      if (data != null && data.size > 0) {
        _chunks.add(data);
      }
    });
    _recorder!.start();
  }

  Future<RecordedAudio?> stop() async {
    final recorder = _recorder;
    if (recorder == null) {
      return null;
    }

    final completer = Completer<void>();
    recorder.addEventListener('stop', (_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    recorder.stop();
    await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {});

    for (final track in _stream?.getTracks() ?? const <html.MediaStreamTrack>[]) {
      track.stop();
    }
    _stream = null;
    _recorder = null;

    final blob = html.Blob(_chunks, 'audio/webm');
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoadEnd.first;

    final bytes = Uint8List.view(reader.result as ByteBuffer);
    return RecordedAudio(
      bytes: bytes,
      nombreArchivo: 'nota_de_voz.webm',
      mimeType: 'audio/webm',
    );
  }
}