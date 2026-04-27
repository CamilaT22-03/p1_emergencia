import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../api_config.dart';
import 'ficha_resumen_page.dart';
import '../services/web_audio_recorder.dart';

// (IMPORTANTE: Asegúrate de importar tu tema si AppTheme está en otro archivo)
// import '../theme/app_theme.dart'; // Descomenta o ajusta esta línea según tu proyecto

// --- 1. LA CABEZA DE LA PANTALLA (Faltaba esto) ---
class EmergenciaPage extends StatefulWidget {
  final int clienteId;
  const EmergenciaPage({super.key, required this.clienteId});

  @override
  State<EmergenciaPage> createState() => _EmergenciaPageState();
}

// --- 2. EL CUERPO Y LA LÓGICA ---
class _EmergenciaPageState extends State<EmergenciaPage> {
  final ubicacionCtrl  = TextEditingController();
  final descripcionCtrl = TextEditingController();
  bool _enviando = false;

  final ImagePicker _picker = ImagePicker();
  XFile? _imagenSeleccionada;
  Uint8List? _audioBytes;
  String? _audioNombre;
  bool _grabandoAudio = false;
  final WebAudioRecorder _webAudioRecorder = WebAudioRecorder();

  Future<void> _tomarFoto() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.gallery);
    if (foto != null) {
      setState(() {
        _imagenSeleccionada = foto;
      });
    }
  }

  Future<void> _seleccionarAudio() async {
    if (kIsWeb) {
      if (_grabandoAudio) {
        final grabacion = await _webAudioRecorder.stop();
        if (grabacion != null) {
          setState(() {
            _audioBytes = grabacion.bytes;
            _audioNombre = grabacion.nombreArchivo;
            _grabandoAudio = false;
          });
        } else {
          setState(() => _grabandoAudio = false);
        }
        return;
      }

      final tienePermiso = await _webAudioRecorder.hasPermission();
      if (!tienePermiso) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo acceder al micrófono'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      await _webAudioRecorder.start();
      setState(() => _grabandoAudio = true);
      return;
    }

    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['wav', 'mp3', 'm4a', 'aac', 'ogg', 'flac'],
      withData: true,
    );

    if (resultado != null && resultado.files.isNotEmpty) {
      final audio = resultado.files.first;
      if (audio.bytes != null) {
        setState(() {
          _audioBytes = audio.bytes;
          _audioNombre = audio.name;
        });
      }
    }
  }

  Future<void> procesarYEnviar() async {
    if (descripcionCtrl.text.isEmpty && _imagenSeleccionada == null && _audioBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Agrega texto, una foto o un audio del incidente'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _enviando = true);
    
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Necesitamos permiso de GPS");
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/emergencias/registrar-inteligente'),
      );

      request.fields['cliente_id'] = widget.clienteId.toString();
      request.fields['vehiculo_id'] = '1';
      request.fields['direccion'] = ubicacionCtrl.text.isEmpty ? 'Ubicación por GPS' : ubicacionCtrl.text;
      request.fields['descripcion'] = descripcionCtrl.text;
      request.fields['latitud'] = position.latitude.toString();
      request.fields['longitud'] = position.longitude.toString();

      if (_imagenSeleccionada != null) {
        final bytes = await _imagenSeleccionada!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'imagen',
          bytes,
          filename: _imagenSeleccionada!.name,
        ));
      }

      if (_audioBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'audio',
          _audioBytes!,
          filename: _audioNombre ?? 'nota_de_voz.wav',
        ));
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final datos = jsonDecode(res.body);
        final analisis = (datos['analisis_ia'] as Map<String, dynamic>? ) ?? {};
        final fichaDeEmergencia = {
          'cliente_id': widget.clienteId,
          'vehiculo_id': 1,
          'direccion': ubicacionCtrl.text.isEmpty ? 'Ubicación por GPS' : ubicacionCtrl.text,
          'descripcion': descripcionCtrl.text,
          'latitud': position.latitude,
          'longitud': position.longitude,
          ...analisis,
        };

        Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
                builder: (context) => FichaResumenPage(
                  datosFicha: fichaDeEmergencia,
                  imagen: _imagenSeleccionada,
                )
            )
        );
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Emergencia'),
        backgroundColor: Colors.redAccent, // Usé Colors temporalmente por si falla AppTheme
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Describe tu situación con el mayor detalle posible para recibir ayuda rápida.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13, height: 1.4),
                )),
              ]),
            ),
            const SizedBox(height: 28),

            const Text('Detalles del incidente',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 20),

            TextField(
              controller: ubicacionCtrl,
              decoration: const InputDecoration(
                labelText: 'Referencias de ubicación (Opcional)',
                hintText: 'Tu GPS se enviará automáticamente',
                prefixIcon: Icon(Icons.location_on_outlined, color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descripcionCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '¿Qué ocurrió con el vehículo?',
                hintText: 'Ej: Se pinchó la llanta delantera derecha...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.build_outlined, color: Colors.grey),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            const Text('Evidencia Visual',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _tomarFoto,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _imagenSeleccionada == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Toca para subir foto del daño', style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : const Center(
                      child: Text('✅ Imagen cargada correctamente', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                    ),
              ),
            ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarAudio,
                    icon: Icon(_grabandoAudio ? Icons.stop_circle_outlined : Icons.mic_none_outlined),
                    label: Text(_grabandoAudio
                        ? 'Detener grabación'
                        : _audioBytes == null
                            ? (kIsWeb ? 'Grabar audio con micrófono' : 'Adjuntar audio')
                            : 'Audio cargado: ${_audioNombre ?? 'nota_de_voz'}'),
                  ),
                ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _enviando
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.psychology, color: Colors.white), 
                label: Text(_enviando ? 'Analizando y Enviando...' : 'Analizar por IA y Enviar',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                onPressed: _enviando ? null : procesarYEnviar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}