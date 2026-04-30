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
  Map<String, dynamic>? _datosEmergencia;
  bool estaCargando = true;
  bool huboError = false;

  @override
  void initState() {
    super.initState();
    obtenerDatosDelTaller();
  }

  Future<void> obtenerDatosDelTaller() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/emergencias/${widget.solicitudId}/taller-asignado');
      final respuesta = await http.get(url);

      if (respuesta.statusCode == 200) {
        final datos = json.decode(respuesta.body);
        setState(() {
          _datosEmergencia = datos;
          estaCargando = false;
        });
      } else {
        setState(() {
          huboError = true;
          estaCargando = false;
        });
      }
    } catch (e) {
      print("Error de conexión: $e");
      setState(() {
        huboError = true;
        estaCargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = _datosEmergencia?['estado'] ?? 'Desconocido';
    final esAceptada = estado == 'Aceptada' || estado == 'En Camino';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          esAceptada ? 'Asistencia en Camino' : 'Estado de tu Emergencia',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : huboError
              ? const Center(child: Text("Error al cargar los datos.\nRevisa tu conexión.", textAlign: TextAlign.center))
              : _datosEmergencia == null
                  ? const Center(child: Text("Emergencia no encontrada"))
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
                              child: Icon(
                                esAceptada ? Icons.local_shipping : Icons.report_problem,
                                size: 80,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              esAceptada ? '¡Tu ayuda está en camino!' : 'Emergencia: $estado',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              esAceptada 
                                  ? 'Mantén la calma y espera en un lugar seguro.'
                                  : 'Estado actual: ${_datosEmergencia?['estado'] ?? 'Pendiente'}',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            
                            // Mostrar detalles de la emergencia
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_datosEmergencia?['tipo_incidente'] != null)
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(Icons.car_crash, color: Colors.redAccent),
                                        title: Text('Tipo: ${_datosEmergencia!['tipo_incidente']}'),
                                        subtitle: Text('Severidad: ${_datosEmergencia!['severidad'] ?? 'No especificada'}'),
                                      ),
                                    if (_datosEmergencia?['direccion'] != null) ...[
                                      const Divider(height: 30),
                                      Text('Dirección:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(_datosEmergencia!['direccion'], style: const TextStyle(fontSize: 16)),
                                    ],
                                    
                                    // Mostrar info del taller si ya fue aceptada
                                    if (esAceptada && _datosEmergencia?['nombre_taller'] != null) ...[
                                      const Divider(height: 30),
                                      
                                      // Info del taller
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const CircleAvatar(
                                          backgroundColor: Colors.blueGrey,
                                          child: Icon(Icons.build, color: Colors.white),
                                        ),
                                        title: Text(_datosEmergencia!['nombre_taller'], 
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        subtitle: const Text('Taller Asignado'),
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // 🔴 DISTANCIA Y TIEMPO (PROMINENTE) 🔴
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            // Tiempo estimado
                                            Column(
                                              children: [
                                                const Icon(Icons.timer, color: Colors.redAccent, size: 32),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Tiempo ETA',
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _datosEmergencia!['tiempo_estimado'] ?? '--',
                                                  style: const TextStyle(
                                                    fontSize: 20, 
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              width: 1,
                                              height: 60,
                                              color: Colors.grey[300],
                                            ),
                                            // Distancia
                                            Column(
                                              children: [
                                                const Icon(Icons.map, color: Colors.redAccent, size: 32),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Distancia',
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${_datosEmergencia!['distancia_km'] ?? '--'} km',
                                                  style: const TextStyle(
                                                    fontSize: 20, 
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 25),
                                      
                                      // Información de contacto
                                      if (_datosEmergencia!['direccion_taller'] != null) ...[
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, color: Colors.grey, size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _datosEmergencia!['direccion_taller'],
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            print("Llamando al: ${_datosEmergencia!['telefono_taller']}");
                                          },
                                          icon: const Icon(Icons.phone, color: Colors.white),
                                          label: const Text('Llamar al Taller', 
                                              style: TextStyle(fontSize: 16, color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ] else if (estado == 'Pendiente') ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.orange),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Buscando taller disponible...\nTe notificaremos cuando acepten.',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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