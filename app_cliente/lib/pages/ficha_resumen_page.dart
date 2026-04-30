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
  String _getDetalleDinamico() {
    final tipo = (datosFicha['tipo_ia'] ?? datosFicha['tipo_incidente'] ?? 'otros').toString().toLowerCase();
    final severidad = (datosFicha['severidad_ia'] ?? datosFicha['nivel_severidad'] ?? '').toString().toLowerCase();
    final sugiereGrua = datosFicha['sugiere_grua'] == true;
    final detalles = {
      'bateria': {
        'leve': 'Se detectó un problema con el sistema de arranque o batería. Generalmente se resuelve con un puente de arranque en el lugar. No requiere grúa.',
        'moderado': 'Problema eléctrico relacionado con la batería o alternador. Podría requerir diagnóstico adicional del sistema de carga.',
        'grave': 'Fallo severo del sistema eléctrico. Puede requerir traslado a taller para reparación completa del sistema de carga.',
      },
      'llanta': {
        'leve': 'Se identificó un neumático dañado o desinflado. Se puede reparar en el lugar con cambio de rueda o parche.',
        'moderado': 'Problema de neumáticos con posible daño en el rín. Se recomienda inspección del sistema de suspensión.',
        'grave': 'Daño severo en neumáticos con posible afectación de suspensión o dirección. Evaluación profesional requerida.',
      },
      'choque': {
        'moderado': 'Se reportó un incidente vehicular con daño aparentemente menor. Se recomienda evaluación presencial para determinar reparaciones necesarias.',
        'grave': 'Choque con daño significativo en la carrocería. Posible afectación estructural. Se recomienda evaluación en taller.',
        'crítico': 'Accidente vehicular grave con daño estructural severo. ${sugiereGrua ? 'Se requiere traslado con grúa al taller más cercano.' : 'Verificar si el vehículo puede circular.'}',
      },
      'motor': {
        'moderado': 'Problema de motor detectado que requiere revisión técnica. No se recomienda continuar conduciendo sin diagnóstico.',
        'grave': 'Fallo grave de motor. Alto riesgo de daño mayor si se continúa operando el vehículo. Se recomienda grúa.',
        'crítico': 'Fallo crítico de motor. Vehículo no operable. Requiere traslado urgente con grúa a taller especializado.',
      },
      'frenos': {
        'moderado': 'Problema en el sistema de frenos detectado. No conducir el vehículo hasta inspección profesional.',
        'grave': 'Fallo severo de frenos. Peligro inminente. No mover el vehículo. Se requiere asistencia inmediata.',
      },
      'electrico': {
        'leve': 'Problema eléctrico menor detectado. Se puede diagnosticar en el lugar con herramientas básicas.',
        'moderado': 'Fallo eléctrico significativo que requiere diagnóstico especializado. Posible revisión de cableado o fusibles.',
      },
      'combustible': {
        'leve': 'Problema de suministro de combustible. Se resuelve con reabastecimiento o cambio de filtro de combustible.',
      },
    };
    return (detalles[tipo] ?? {})[severidad] ??
        'Se identificó un incidente de tipo "$tipo" con severidad "$severidad". Se recomienda evaluación profesional en el lugar.';
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
                  // Diagnóstico IA
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
                          if (sugiereGrua) ...[
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
                                      "Se recomienda servicio de grúa basado en el análisis del incidente.",
                                      style: TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          const Text("Detalles detectados:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 5),
                          Text(
                            _getDetalleDinamico(),
                            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Datos de GPS
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
