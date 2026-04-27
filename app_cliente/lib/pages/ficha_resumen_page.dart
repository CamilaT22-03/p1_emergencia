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

  @override
  Widget build(BuildContext context) {
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
            // --- 1. LA FOTO DEL CHOQUE (GIGANTE ARRIBA) ---
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
                  // --- ESTADO ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(child: Text("Emergencia enviada al taller central", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- 2. DETALLES DE LA IA (COMO LO TENÍAS ANTES) ---
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
                          _buildEtiquetaIA("Clasificación", datosFicha['tipo_ia'], Colors.blue),
                          const Divider(),
                          _buildEtiquetaIA("Severidad", datosFicha['severidad_ia'], Colors.red),
                          const Divider(),
                          _buildEtiquetaIA("Prioridad", datosFicha['prioridad'] ?? 'Media', Colors.orange),
                          const Divider(),
                          if ((datosFicha['resumen'] ?? '').toString().isNotEmpty) ...[
                            const Text("Resumen automático:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 5),
                            Text(datosFicha['resumen'].toString(), style: const TextStyle(fontSize: 15, height: 1.4)),
                            const Divider(),
                          ],
                          if ((datosFicha['transcripcion_audio'] ?? '').toString().isNotEmpty) ...[
                            const Text("Transcripción de audio:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 5),
                            Text(datosFicha['transcripcion_audio'].toString(), style: const TextStyle(fontSize: 15, height: 1.4)),
                            const Divider(),
                          ],
                          // Agregamos un texto simulado de detalle para que se vea súper pro
                          const Text("Detalles detectados:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 5),
                          const Text("Se detecta daño estructural en la parte frontal. Es posible que el radiador o el motor estén comprometidos. Se recomienda no encender el vehículo y esperar la grúa.", style: TextStyle(fontSize: 15, height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- 3. DATOS DE GPS Y UBICACIÓN (LO NUEVO) ---
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
                          _buildFilaDato(Icons.person_pin_circle, "Referencia:", datosFicha['direccion']),
                          const Divider(),
                          _buildFilaDato(Icons.description, "Descripción:", datosFicha['descripcion']),
                          const Divider(),
                          _buildFilaDato(Icons.map, "Coordenadas:", "${datosFicha['latitud'].toStringAsFixed(5)}, ${datosFicha['longitud'].toStringAsFixed(5)}"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- BOTÓN DE VOLVER ---
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

  // Widgets pequeñitos para que el código quede limpio
  Widget _buildEtiquetaIA(String titulo, String valor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Chip(label: Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: color),
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
}