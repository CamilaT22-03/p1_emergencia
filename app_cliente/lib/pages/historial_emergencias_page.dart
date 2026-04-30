import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import 'taller_asignado_page.dart';
class HistorialEmergenciasPage extends StatefulWidget {
  final int clienteId;
  const HistorialEmergenciasPage({super.key, required this.clienteId});
  @override
  State<HistorialEmergenciasPage> createState() => _HistorialEmergenciasPageState();
}
class _HistorialEmergenciasPageState extends State<HistorialEmergenciasPage> {
  bool _cargando = true;
  List<Map<String, dynamic>> _emergencias = [];
  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }
  Future<void> _cargarHistorial() async {
    setState(() => _cargando = true);
    try {
      final respuesta = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/emergencias/cliente/${widget.clienteId}'),
      );
      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as List<dynamic>;
        setState(() {
          _emergencias = datos.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        });
      }
    } finally {
      setState(() => _cargando = false);
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
  IconData _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente': return Icons.pending_outlined;
      case 'aceptada': return Icons.check_circle_outline;
      case 'en camino': return Icons.local_shipping_outlined;
      case 'en proceso': return Icons.build_outlined;
      case 'finalizada': return Icons.task_alt;
      case 'rechazada': return Icons.cancel_outlined;
      default: return Icons.report_problem_outlined;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Emergencias'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _emergencias.isEmpty
              ? const Center(child: Text('No tienes emergencias registradas todavía.'))
              : RefreshIndicator(
                  onRefresh: _cargarHistorial,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _emergencias.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final em = _emergencias[index];
                      final estado = em['estado'] ?? 'Pendiente';
                      final tipo = em['tipo_ia']?.toString().isNotEmpty == true
                          ? em['tipo_ia'].toString()
                          : 'Emergencia #${em['id']}';
                      final direccion = em['direccion'] ?? 'Sin dirección';
                      final severidad = em['severidad_ia'] ?? '';
                      final prioridad = em['prioridad_ia'] ?? '';
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            if (estado != 'Finalizada' && estado != 'Rechazada') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TallerAsignadoPage(emergenciaId: em['id']),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(_iconoEstado(estado), color: _colorEstado(estado), size: 22),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              tipo,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _colorEstado(estado).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        estado,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _colorEstado(estado),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  direccion,
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                                if (severidad.isNotEmpty || prioridad.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      if (severidad.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Severidad: $severidad',
                                            style: const TextStyle(fontSize: 11, color: Colors.red),
                                          ),
                                        ),
                                      if (prioridad.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Prioridad: $prioridad',
                                            style: const TextStyle(fontSize: 11, color: Colors.orange),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                                if (estado != 'Finalizada' && estado != 'Rechazada') ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Toca para ver taller y ETA',
                                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
