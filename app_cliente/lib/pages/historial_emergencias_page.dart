import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import 'package:app_cliente/pages/taller_asignado_page.dart';

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

  Color _getColorEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'aceptada':
      case 'en camino':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'resuelto':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconoEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'aceptada':
      case 'en camino':
        return Icons.local_shipping;
      case 'pendiente':
        return Icons.pending_outlined;
      case 'resuelto':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
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
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _emergencias.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final em = _emergencias[index];
                    final estado = em['estado'] ?? 'Pendiente';
                    final colorEstado = _getColorEstado(estado);
                    
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          _getIconoEstado(estado),
                          color: colorEstado,
                        ),
                        title: Text(
                          em['tipo_ia']?.toString().isNotEmpty == true
                              ? em['tipo_ia'].toString().toUpperCase()
                              : 'Emergencia #${em['id']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${em['direccion'] ?? 'Sin dirección'}'),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorEstado.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                estado,
                                style: TextStyle(
                                  color: colorEstado,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Mostrar distancia y tiempo si está aceptada
                            if (em['nombre_taller'] != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (em['tiempo_estimado'] != null) ...[
                                    const Icon(Icons.timer, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      em['tiempo_estimado'],
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  if (em['distancia_km'] != null) ...[
                                    const Icon(Icons.map, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${em['distancia_km']} km',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        isThreeLine: true,
                        onTap: () {
                          // Navegar a la página de detalles
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TallerAsignadoPage(
                                solicitudId: em['id'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}