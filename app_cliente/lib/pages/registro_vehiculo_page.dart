import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_config.dart';
import '../theme.dart';

class RegistroVehiculoPage extends StatefulWidget {
  final int clienteId;
  const RegistroVehiculoPage({super.key, required this.clienteId});
  @override
  State<RegistroVehiculoPage> createState() => _RegistroVehiculoPageState();
}

class _RegistroVehiculoPageState extends State<RegistroVehiculoPage> {
  final placaCtrl  = TextEditingController();
  final marcaCtrl  = TextEditingController();
  final modeloCtrl = TextEditingController();
  final colorCtrl  = TextEditingController();
  bool _cargando = false;

  Future<void> guardar() async {
    if ([placaCtrl, marcaCtrl, modeloCtrl, colorCtrl].any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor, completa todos los campos'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _cargando = true);
    
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/vehiculos/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'placa': placaCtrl.text, 
          'marca': marcaCtrl.text,
          'modelo': modeloCtrl.text, 
          'color': colorCtrl.text,
          'cliente_id': widget.clienteId,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Vehículo guardado exitosamente!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: Revisa los datos'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error de conexión. ¿Está encendido el servidor?'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Vehículo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car_rounded, size: 48, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 28),
            _campo(placaCtrl, 'Placa', Icons.pin_outlined),
            const SizedBox(height: 14),
            _campo(marcaCtrl, 'Marca', Icons.branding_watermark_outlined),
            const SizedBox(height: 14),
            _campo(modeloCtrl, 'Modelo', Icons.directions_car_outlined),
            const SizedBox(height: 14),
            _campo(colorCtrl, 'Color', Icons.palette_outlined),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _cargando ? null : guardar,
              child: _cargando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Guardar vehículo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
      ),
    );
  }
}