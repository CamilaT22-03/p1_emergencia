import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

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
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.report_problem_outlined, color: Colors.redAccent),
                        title: Text(
                          em['tipo_ia']?.toString().isNotEmpty == true
                              ? em['tipo_ia'].toString()
                              : 'Emergencia #${em['id']}',
                        ),
                        subtitle: Text('${em['estado'] ?? 'Pendiente'} · ${em['direccion'] ?? 'Sin dirección'}'),
                        isThreeLine: false,
                      ),
                    );
                  },
                ),
    );
  }
}