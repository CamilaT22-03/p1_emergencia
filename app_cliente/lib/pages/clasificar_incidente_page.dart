import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../api_config.dart';
import 'ficha_resumen_page.dart';

class ClasificarIncidentePage extends StatefulWidget {
  const ClasificarIncidentePage({super.key});

  @override
  State<ClasificarIncidentePage> createState() => _ClasificarIncidentePageState();
}

class _ClasificarIncidentePageState extends State<ClasificarIncidentePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imagenSeleccionada;
  Uint8List? _imagenBytes; 
  bool _estaAnalizando = false;
  Map<String, dynamic>? _resultadoIA;

  Future<void> _seleccionarImagen(ImageSource origen) async {
    final XFile? imagen = await _picker.pickImage(source: origen);
    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      setState(() {
        _imagenSeleccionada = imagen;
        _imagenBytes = bytes;
        _resultadoIA = null; 
      });
    }
  }

  Future<void> _enviarAInteligenciaArtificial() async {
  if (_imagenSeleccionada == null || _imagenBytes == null) return;
  setState(() { _estaAnalizando = true; });

  try {
    var uri = Uri.parse('${ApiConfig.baseUrl}/api/emergencias/clasificar-imagen');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('imagen', _imagenBytes!, filename: _imagenSeleccionada!.name));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    // 🔍 DEBUG EN FLUTTER: Mira la consola de VS Code
    print("Status Code: ${response.statusCode}");
    print("Cuerpo de respuesta: ${response.body}");

    if (response.statusCode == 200) {
      var datos = json.decode(response.body);
      if (datos.containsKey('error')) {
        _mostrarError("Error IA: ${datos['error']}");
      } else {
        setState(() {
          _resultadoIA = datos['analisis_ia'];
        });
      }
    } else {
      _mostrarError("Servidor respondió con error: ${response.statusCode}");
    }
  } catch (e) {
    print("Error de conexión: $e");
    _mostrarError("No se pudo conectar con el servidor backend.");
  } finally {
    setState(() { _estaAnalizando = false; });
  }
}

// Agrega esta función si no la tienes
void _mostrarError(String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(mensaje), backgroundColor: Colors.red)
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis por IA', style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Envolvemos todo en Center para centrar en la Web
      body: Center(
        // ConstrainedBox bloquea el ancho a un máximo de 400 píxeles. Nada puede ser infinito.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Estira los elementos solo hasta los 400px
              children: [
                const Text("Sube foto del choque", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 20),

                // Contenedor de la foto
                if (_imagenBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10), 
                    child: Image.memory(_imagenBytes!, height: 250, fit: BoxFit.cover)
                  )
                else
                  Container(
                    height: 250, 
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)), 
                    child: const Center(child: Icon(Icons.camera_alt, size: 60, color: Colors.grey))
                  ),

                const SizedBox(height: 20),

                // 👇 AQUI ESTABA EL ERROR: Eliminamos el 'Row'. Ahora están apilados de forma segura.
                ElevatedButton.icon(
                  onPressed: () => _seleccionarImagen(ImageSource.camera), 
                  icon: const Icon(Icons.camera), 
                  label: const Text("Tomar con Cámara")
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _seleccionarImagen(ImageSource.gallery), 
                  icon: const Icon(Icons.photo), 
                  label: const Text("Subir de Galería")
                ),

                const SizedBox(height: 30),

                // Botón principal
                if (_imagenBytes != null && _resultadoIA == null)
                  _estaAnalizando
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(vertical: 15)
                          ),
                          onPressed: _enviarAInteligenciaArtificial,
                          child: const Text("Analizar Choque", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),

                // Resultados
                // Botón para generar y ver la Ficha (CU-12)
                if (_resultadoIA != null && _imagenBytes != null) ...[
                  const Divider(height: 40, thickness: 2),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 15)
                      ),
                      icon: const Icon(Icons.assignment, color: Colors.white),
                      label: const Text("Generar Ficha de Incidente", style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: () {
                        // Navegamos a la nueva pantalla pasándole los datos
                        Navigator.pushReplacement(
                         context, 
                         MaterialPageRoute(
                           builder: (context) => FichaResumenPage(
                               datosFicha: _resultadoIA!,
                               imagen: _imagenSeleccionada!  // <-- ¡ESTA ES LA LÍNEA MÁGICA!
                           )
                         )
                        );
                      },
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}