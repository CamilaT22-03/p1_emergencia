import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_config.dart';
import '../theme.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});
  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final nombreCtrl = TextEditingController();
  final emailCtrl  = TextEditingController();
  final passCtrl   = TextEditingController();
  final telfCtrl   = TextEditingController();
  bool _cargando = false;

  Future<void> registrar() async {
    // 1. VALIDACIÓN: Que no mande campos vacíos
    if (nombreCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      _mostrarMensaje('Por favor llena los campos obligatorios', Colors.orange);
      return;
    }

    setState(() => _cargando = true);
    
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/clientes/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_completo': nombreCtrl.text,
          'email': emailCtrl.text,
          'contrasena': passCtrl.text,
          'telefono': telfCtrl.text,
        }),
      );

      // 3. RESPUESTA DEL SERVIDOR: A veces los registros devuelven 201 en vez de 200
      if (res.statusCode == 200 || res.statusCode == 201) {
        _mostrarMensaje('¡Cuenta creada exitosamente!', const Color(0xFF10B981));
        Navigator.pop(context); // Te devuelve al login
      } else {
        // Si FastAPI rechaza (ej. correo duplicado), mostramos el error
        _mostrarMensaje('Error al registrar: Revisar datos', AppTheme.danger);
        print('Error del servidor: ${res.body}'); // Para que lo veas en la consola
      }
    } catch (e) {
      // 4. ERROR DE RED: Si el servidor está apagado o falla la conexión
      _mostrarMensaje('Error de conexión. Revisa que el servidor esté encendido', AppTheme.danger);
      print('Excepción atrapada: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  // Función ayudante para no repetir el código del SnackBar
  void _mostrarMensaje(String texto, Color colorFondo) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: colorFondo,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tus datos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textMain)),
            const SizedBox(height: 4),
            const Text('Completa el formulario para registrarte', style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 28),
            
            _campo(nombreCtrl, 'Nombre completo', Icons.person_outline),
            const SizedBox(height: 14),
            _campo(emailCtrl, 'Correo electrónico', Icons.email_outlined, tipo: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _campo(passCtrl, 'Contraseña', Icons.lock_outline, ocultar: true),
            const SizedBox(height: 14),
            _campo(telfCtrl, 'Teléfono (Opcional)', Icons.phone_outlined, tipo: TextInputType.phone),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _cargando ? null : registrar,
              child: _cargando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icon,
      {TextInputType tipo = TextInputType.text, bool ocultar = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      obscureText: ocultar,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
      ),
    );
  }
}