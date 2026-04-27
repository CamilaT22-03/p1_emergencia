import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_config.dart';
import '../theme.dart';
// ¡ESTA ES LA LÍNEA QUE FALTABA PARA QUE RECONOZCA LA PÁGINA! 👇
import 'registro_vehiculo_page.dart'; 

class VehiculosPage extends StatefulWidget {
  final int clienteId;
  const VehiculosPage({super.key, required this.clienteId});

  @override
  State<VehiculosPage> createState() => _VehiculosPageState();
}

class _VehiculosPageState extends State<VehiculosPage> {
  List _vehiculos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerVehiculos(); 
  }

  Future<void> _obtenerVehiculos() async {
    setState(() => _cargando = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vehiculos/cliente/${widget.clienteId}'),
      );

      if (res.statusCode == 200) {
        setState(() {
          _vehiculos = jsonDecode(res.body);
        });
      } else {
        // Si el servidor responde algo que NO es 200
        print('Error del servidor: ${res.statusCode} - ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudieron cargar los vehículos'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      // Si el servidor está apagado o no hay internet
      print("Error de conexión: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error de conexión con el servidor'),
        backgroundColor: Colors.red,
      ));
    } finally {
      // 🚀 ESTO ES CLAVE: Pase lo que pase (éxito o error), detenemos la carga
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Vehículos')),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : _vehiculos.isEmpty 
          ? _sinVehiculos()
          : _listaVehiculos(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegistroVehiculoPage(clienteId: widget.clienteId)),
          ).then((_) => _obtenerVehiculos()); // Refresca al volver
        },
      ),
    );
  }

  Widget _listaVehiculos() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vehiculos.length,
      itemBuilder: (context, i) {
        final v = _vehiculos[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.directions_car, color: AppTheme.primary),
            title: Text('${v['marca']} ${v['modelo']}'),
            subtitle: Text('Placa: ${v['placa']} - Color: ${v['color']}'),
          ),
        );
      },
    );
  }

  Widget _sinVehiculos() {
    return const Center(child: Text('Aún no tienes vehículos registrados.'));
  }
}