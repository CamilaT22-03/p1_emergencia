import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class TalleresPage extends StatefulWidget {
  final int clienteId;

  const TalleresPage({super.key, required this.clienteId});

  @override
  State<TalleresPage> createState() => _TalleresPageState();
}

class _TalleresPageState extends State<TalleresPage> {
  bool _cargando = true;
  List<Map<String, dynamic>> _talleres = [];

  @override
  void initState() {
    super.initState();
    _cargarTalleres();
  }

  Future<void> _cargarTalleres() async {
    setState(() => _cargando = true);
    try {
      final respuesta = await http.get(Uri.parse('${ApiConfig.baseUrl}/talleres/'));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as List<dynamic>;
        setState(() {
          _talleres = datos.map((item) => Map<String, dynamic>.from(item as Map)).toList();
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
        title: const Text('Talleres Cercanos'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _talleres.isEmpty
              ? const Center(child: Text('No hay talleres registrados.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _talleres.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final taller = _talleres[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.home_repair_service_outlined, color: Colors.redAccent),
                        title: Text(taller['nombre_taller']?.toString() ?? 'Taller'),
                        subtitle: Text('${taller['direccion'] ?? ''}\n${taller['telefono'] ?? ''}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}