import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_config.dart';

class TallerAsignadoPage extends StatefulWidget {
  final int solicitudId;

  const TallerAsignadoPage({super.key, required this.solicitudId});

  @override
  State<TallerAsignadoPage> createState() => _TallerAsignadoPageState();
}

class _TallerAsignadoPageState extends State<TallerAsignadoPage> {
  // Variables para guardar los datos reales del backend
  String nombreTaller = "Cargando...";
  String tiempoEstimado = "--";
  String distanciaKm = "--";
  String telefonoTecnico = "";
  bool estaCargando = true; // Para mostrar la ruedita de carga
  bool huboError = false;

  @override
  void initState() {
    super.initState();
    // Apenas se abre la pantalla, llamamos a la función
    obtenerDatosDelTaller();
  }

  Future<void> obtenerDatosDelTaller() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/emergencias/${widget.solicitudId}/taller-asignado');
      final respuesta = await http.get(url);

      if (respuesta.statusCode == 200) {
        // Si el backend dice "Todo ok", leemos el JSON
        final datos = json.decode(respuesta.body);
        setState(() {
          nombreTaller = datos['nombre_taller'];
          tiempoEstimado = datos['tiempo_estimado'];
          distanciaKm = datos['distancia_km'].toString();
          telefonoTecnico = datos['telefono_tecnico'];
          estaCargando = false;
        });
      } else {
        // Si hay error (ej. 404)
        setState(() {
          huboError = true;
          estaCargando = false;
        });
      }
    } catch (e) {
      // Si el servidor está apagado
      print("Error de conexión: $e");
      setState(() {
        huboError = true;
        estaCargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia en Camino', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent)) // Ruedita de carga
          : huboError
              ? const Center(child: Text("Error al cargar los datos del taller.\nRevisa tu conexión.", textAlign: TextAlign.center))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_shipping, size: 80, color: Colors.redAccent),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '¡Tu ayuda está en camino!',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Mantén la calma y espera en un lugar seguro.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.blueGrey,
                                    child: Icon(Icons.build, color: Colors.white),
                                  ),
                                  title: Text(nombreTaller, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  subtitle: const Text('Taller Asignado'),
                                ),
                                const Divider(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildInfoColumn(Icons.timer_outlined, 'Llegada (ETA)', tiempoEstimado),
                                    _buildInfoColumn(Icons.map_outlined, 'Distancia', '$distanciaKm km'),
                                  ],
                                ),
                                const SizedBox(height: 25),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      print("Llamando al: $telefonoTecnico");
                                    },
                                    icon: const Icon(Icons.phone, color: Colors.white),
                                    label: const Text('Contactar al Técnico', style: TextStyle(fontSize: 16, color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.redAccent, size: 30),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}