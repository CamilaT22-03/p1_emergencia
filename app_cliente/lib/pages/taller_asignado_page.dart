import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_config.dart';
class TallerAsignadoPage extends StatefulWidget {
  final int emergenciaId;
  const TallerAsignadoPage({super.key, required this.emergenciaId});
  @override
  State<TallerAsignadoPage> createState() => _TallerAsignadoPageState();
}
class _TallerAsignadoPageState extends State<TallerAsignadoPage> {
  String nombreTaller = "Cargando...";
  String tiempoEstimado = "--";
  String distanciaKm = "--";
  String telefonoTaller = "";
  String estadoEmergencia = "--";
  List<Map<String, dynamic>> _historial = [];
  bool estaCargando = true;
  bool huboError = false;
  bool cargandoHistorial = true;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    obtenerDatosDelTaller();
    cargarHistorial();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      obtenerDatosDelTaller();
      cargarHistorial();
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  Future<void> obtenerDatosDelTaller() async {
    try {
      final urlTaller = Uri.parse('${ApiConfig.baseUrl}/api/emergencias/${widget.emergenciaId}/taller-asignado');
      final respTaller = await http.get(urlTaller);
      if (respTaller.statusCode == 200) {
        final datos = json.decode(respTaller.body);
        if (mounted) {
          setState(() {
            nombreTaller = datos['nombre_taller'] ?? 'Sin asignar';
            tiempoEstimado = datos['tiempo_estimado'] ?? '--';
            final dist = datos['distancia_km'];
            distanciaKm = dist != null ? '$dist' : '--';
            telefonoTaller = datos['telefono_taller'] ?? '';
            estaCargando = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            nombreTaller = 'Aún no asignado';
            tiempoEstimado = '--';
            distanciaKm = '--';
            estaCargando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          huboError = true;
          estaCargando = false;
        });
      }
    }
  }
  Future<void> cargarHistorial() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/emergencias/${widget.emergenciaId}/historial');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final lista = json.decode(resp.body) as List;
        final historialParsed = lista.map((e) => Map<String, dynamic>.from(e)).toList();
        if (mounted) {
          setState(() {
            _historial = historialParsed;
            cargandoHistorial = false;
          });
          final ultima = historialParsed.first;
          if (ultima != null) {
            setState(() => estadoEmergencia = ultima['estado_nuevo'] ?? 'Desconocido');
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => cargandoHistorial = false);
    }
  }
  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente': return Colors.orange;
      case 'aceptada': return Colors.blue;
      case 'en camino': return Colors.deepOrange;
      case 'en proceso': return Colors.purple;
      case 'finalizada': return Colors.green;
      case 'rechazada': return Colors.red;
      default: return Colors.grey;
    }
  }
  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null || fechaIso.isEmpty) return '';
    try {
      final dt = DateTime.parse(fechaIso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de mi Solicitud', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: estaCargando
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : huboError
              ? const Center(child: Text("Error al cargar. Revisa tu conexión.", textAlign: TextAlign.center))
              : RefreshIndicator(
                  onRefresh: () async {
                    await obtenerDatosDelTaller();
                    await cargarHistorial();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          // Estado actual
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: _colorEstado(estadoEmergencia).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: _colorEstado(estadoEmergencia).withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 10, color: _colorEstado(estadoEmergencia)),
                                const SizedBox(width: 8),
                                Text(
                                  estadoEmergencia,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _colorEstado(estadoEmergencia),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: estadoEmergencia == 'En Camino' || estadoEmergencia == 'En Proceso'
                                  ? Colors.green.shade50
                                  : estadoEmergencia == 'Finalizada'
                                      ? Colors.green.shade50
                                      : Colors.redAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              estadoEmergencia == 'En Camino' ? Icons.local_shipping :
                              estadoEmergencia == 'En Proceso' ? Icons.build :
                              estadoEmergencia == 'Finalizada' ? Icons.check_circle :
                              estadoEmergencia == 'Rechazada' ? Icons.cancel :
                              Icons.local_shipping,
                              size: 80,
                              color: estadoEmergencia == 'En Camino' || estadoEmergencia == 'En Proceso'
                                  ? Colors.green
                                  : estadoEmergencia == 'Finalizada' ? Colors.green :
                                    estadoEmergencia == 'Rechazada' ? Colors.red :
                                    Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            estadoEmergencia == 'En Camino' ? '¡Tu ayuda está en camino!' :
                            estadoEmergencia == 'En Proceso' ? '¡El técnico está trabajando!' :
                            estadoEmergencia == 'Finalizada' ? 'Servicio finalizado' :
                            estadoEmergencia == 'Rechazada' ? 'Solicitud rechazada' :
                            estadoEmergencia == 'Aceptada' ? 'Taller aceptó tu solicitud' :
                            'Buscando taller cercano...',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Mantén la calma y espera en un lugar seguro.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Card taller + distancia
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: nombreTaller == 'Aún no asignado' ? Colors.grey : Colors.blueGrey,
                                      child: Icon(
                                        nombreTaller == 'Aún no asignado' ? Icons.search : Icons.build,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(nombreTaller, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    subtitle: Text(nombreTaller == 'Aún no asignado' ? 'Esperando aceptación...' : 'Taller Asignado'),
                                  ),
                                  if (nombreTaller != 'Aún no asignado' && distanciaKm != '--') ...[
                                    const Divider(height: 30),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildInfoColumn(Icons.timer_outlined, 'Llegada (ETA)', tiempoEstimado),
                                        _buildInfoColumn(Icons.map_outlined, 'Distancia', distanciaKm == '--' ? '--' : '$distanciaKm km'),
                                      ],
                                    ),
                                    if (telefonoTaller.isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(Icons.phone, color: Colors.white),
                                          label: const Text('Contactar', style: TextStyle(fontSize: 15, color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // TIMELINE DE ESTADOS
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.timeline_outlined, color: Colors.grey, size: 22),
                                      SizedBox(width: 8),
                                      Text('Historial de Estados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (cargandoHistorial)
                                    const Center(child: SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ))
                                  else if (_historial.isEmpty)
                                    const Center(child: Text('Sin historial disponible.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                                  else
                                    ..._historial.map((h) {
                                      final nuevoEstado = h['estado_nuevo'] ?? '';
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              children: [
                                                Container(
                                                  width: 14, height: 14,
                                                  decoration: BoxDecoration(
                                                    color: _colorEstado(nuevoEstado),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white, width: 2),
                                                  ),
                                                ),
                                                Container(
                                                  width: 2, height: 30,
                                                  color: Colors.grey.shade200,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: _colorEstado(nuevoEstado).withOpacity(0.12),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          nuevoEstado,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: _colorEstado(nuevoEstado),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        _formatearFecha(h['fecha_cambio']),
                                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                  if ((h['descripcion'] ?? '').toString().isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      h['descripcion'].toString(),
                                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}
