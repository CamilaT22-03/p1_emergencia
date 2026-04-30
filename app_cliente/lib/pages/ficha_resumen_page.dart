import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
class FichaResumenPage extends StatelessWidget {
  final Map<String, dynamic> datosFicha;
  final XFile? imagen;
  const FichaResumenPage({
    super.key,
    required this.datosFicha,
    this.imagen,
  });
  String _valor(dynamic valor) {
    if (valor == null) return 'No disponible';
    final texto = valor.toString().trim();
    return texto.isEmpty ? 'No disponible' : texto;
  }
  String _coordenadas() {
    final latitud = datosFicha['latitud'];
    final longitud = datosFicha['longitud'];
    if (latitud is num && longitud is num) {
      return '${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}';
    }
    return 'No disponible';
  }
  Widget _buildEtiquetaIA(String titulo, String valor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Chip(
            label: Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: color,
          ),
        ],
      ),
    );
  }
  Widget _buildFilaDato(IconData icono, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                Text(valor, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final tipo = datosFicha['tipo_ia'] ?? datosFicha['tipo_incidente'] ?? 'N/A';
    final severidad = datosFicha['severidad_ia'] ?? datosFicha['nivel_severidad'] ?? 'N/A';
    final prioridad = datosFicha['prioridad'] ?? 'Media';
    final confianza = datosFicha['confianza_ia'] ?? '';
    final sugiereGrua = datosFicha['sugiere_grua'] == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis del Incidente'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 250,
              child: imagen == null
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined, size: 56, color: Colors.grey),
                      ),
                    )
                  : kIsWeb
                      ? Image.network(imagen!.path, fit: BoxFit.cover)
                      : Image.file(File(imagen!.path), fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Emergencia enviada al taller central",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.purple, size: 28),
                      SizedBox(width: 8),
                      Text('Diagnóstico de IA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEtiquetaIA("Clasificación", _valor(tipo), Colors.blue),
                          const Divider(),
                          _buildEtiquetaIA("Severidad", _valor(severidad), Colors.red),
                          const Divider(),
                          _buildEtiquetaIA("Prioridad", _valor(prioridad), Colors.orange),
                          if (confianza.isNotEmpty) ...[
                            const Divider(),
                            _buildEtiquetaIA("Confianza IA", confianza, Colors.purple),
                          ],
                          if (sugiereGrua) ...[
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.airport_shuttle, color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Se recomienda servicio de grúa.",
                                      style: TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if ((datosFicha['resumen'] ?? '').toString().isNotEmpty) ...[
                            const Divider(),
                            const Text("Resumen automático:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 5),
                            Text(datosFicha['resumen'].toString(), style: const TextStyle(fontSize: 14, height: 1.4)),
                          ],
                          if ((datosFicha['transcripcion_audio'] ?? '').toString().isNotEmpty) ...[
                            const Divider(),
                            const Text("Transcripción de audio:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 5),
                            Text(datosFicha['transcripcion_audio'].toString(), style: const TextStyle(fontSize: 14, height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Row(
                    children: [
                      Icon(Icons.gps_fixed, color: Colors.redAccent, size: 28),
                      SizedBox(width: 8),
                      Text('Datos de Ubicación', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildFilaDato(Icons.person_pin_circle, "Referencia:", _valor(datosFicha['direccion'])),
                          const Divider(),
                          _buildFilaDato(Icons.description, "Descripción:", _valor(datosFicha['descripcion'])),
                          const Divider(),
                          _buildFilaDato(Icons.map, "Coordenadas:", _coordenadas()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar Reporte'),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
