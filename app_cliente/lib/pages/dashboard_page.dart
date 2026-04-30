import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';
import 'vehiculos_page.dart';
import 'emergencia_page.dart';
import 'login_page.dart';
import 'package:app_cliente/pages/taller_asignado_page.dart';
import 'package:app_cliente/pages/clasificar_incidente_page.dart';
import 'historial_emergencias_page.dart';
import 'talleres_page.dart';
import '../api_config.dart';
class DashboardPage extends StatefulWidget {
  final int clienteId;
  const DashboardPage({super.key, required this.clienteId});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  int _tab = 0;
  int? _emergenciaActivaId;
  String _estadoActivo = '';
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _buscarEmergenciaActiva();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _buscarEmergenciaActiva());
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  Future<void> _buscarEmergenciaActiva() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/emergencias/cliente/${widget.clienteId}');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final lista = json.decode(resp.body) as List;
        final activa = lista.firstWhere(
          (e) {
            final estado = (e['estado'] ?? '').toString().toLowerCase();
            return estado != 'finalizada' && estado != 'rechazada';
          },
          orElse: () => null,
        );
        if (activa != null && mounted) {
          setState(() {
            _emergenciaActivaId = activa['id'];
            _estadoActivo = activa['estado'] ?? 'Pendiente';
          });
        }
      }
    } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['Auxilio Vial', 'Talleres', 'Mi Perfil'][_tab]),
        automaticallyImplyLeading: false,
        actions: [
          if (_tab == 0 && _emergenciaActivaId != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _colorEstado(_estadoActivo).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: _colorEstado(_estadoActivo)),
                  const SizedBox(width: 5),
                  Text(_estadoActivo, style: TextStyle(color: _colorEstado(_estadoActivo), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
      body: [
        _TabSOS(clienteId: widget.clienteId, emergenciaActivaId: _emergenciaActivaId, estadoActivo: _estadoActivo),
        TalleresPage(clienteId: widget.clienteId),
        _TabPerfil(clienteId: widget.clienteId),
      ][_tab],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
          color: Colors.white,
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textMuted,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.emergency_share_outlined), activeIcon: Icon(Icons.emergency_share), label: 'SOS'),
            BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: 'Talleres'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente': return Colors.orange;
      case 'aceptada': return Colors.blue;
      case 'en camino': return Colors.deepOrange;
      case 'en proceso': return Colors.purple;
      case 'finalizada': return Colors.green;
      default: return Colors.grey;
    }
  }
}
// ── TAB SOS ──────────────────────────────────────────────
class _TabSOS extends StatelessWidget {
  final int clienteId;
  final int? emergenciaActivaId;
  final String estadoActivo;
  const _TabSOS({required this.clienteId, this.emergenciaActivaId, this.estadoActivo = ''});
  Widget _buildAlertaAsistenciaEnCamino(BuildContext context) {
    if (emergenciaActivaId == null) return const SizedBox.shrink();
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TallerAsignadoPage(emergenciaId: emergenciaActivaId!)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 30),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: estadoActivo == 'En Camino' ? Colors.green.shade50 :
                 estadoActivo == 'En Proceso' ? Colors.purple.shade50 :
                 Colors.orange.shade100,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: estadoActivo == 'En Camino' ? Colors.green.shade300 :
                   estadoActivo == 'En Proceso' ? Colors.purple.shade300 :
                   Colors.orange.shade400,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                estadoActivo == 'En Camino' ? Icons.local_shipping :
                estadoActivo == 'En Proceso' ? Icons.build :
                Icons.airport_shuttle,
                color: estadoActivo == 'En Camino' ? Colors.green :
                       estadoActivo == 'En Proceso' ? Colors.purple :
                       Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estadoActivo == 'En Camino' ? "¡Ayuda en camino!" :
                    estadoActivo == 'En Proceso' ? "¡Técnico trabajando!" :
                    "¡Solicitud en proceso!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: estadoActivo == 'En Camino' ? Colors.green :
                             estadoActivo == 'En Proceso' ? Colors.purple :
                             Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    estadoActivo == 'En Camino' ? "Toca para ver ETA y distancia." :
                    estadoActivo == 'En Proceso' ? "Toca para ver el estado." :
                    "Toca para ver detalles.",
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAlertaAsistenciaEnCamino(context),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.car_crash_outlined, size: 64, color: Colors.redAccent),
                ),
                const SizedBox(height: 28),
                const Text(
                  '¿Necesitas asistencia?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Presiona el botón SOS para reportar una emergencia.',
                  style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: const CircleBorder(),
                      elevation: 10,
                      shadowColor: Colors.redAccent.withOpacity(0.5),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EmergenciaPage(clienteId: clienteId)),
                      );
                    },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.power_settings_new_rounded, size: 56, color: Colors.white),
                        SizedBox(height: 8),
                        Text('SOS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 3)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: const BorderSide(color: Colors.indigo, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClasificarIncidentePage()),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    "Analizar choque con IA",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
// ── TAB PERFIL ───────────────────────────────────────────
class _TabPerfil extends StatelessWidget {
  final int clienteId;
  const _TabPerfil({required this.clienteId});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF7C3AED)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text('Mi cuenta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textMain)),
            const SizedBox(height: 4),
            Text('ID: $clienteId', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 32),
        Card(
          child: Column(children: [
            _opcion(
              icon: Icons.directions_car_outlined,
              color: AppTheme.primary,
              titulo: 'Mis Vehículos',
              subtitulo: 'Gestiona tus autos registrados',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => VehiculosPage(clienteId: clienteId),
              )),
            ),
            const Divider(height: 1, indent: 60),
            _opcion(
              icon: Icons.history_outlined,
              color: const Color(0xFF10B981),
              titulo: 'Mis Emergencias',
              subtitulo: 'Historial de reportes',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => HistorialEmergenciasPage(clienteId: clienteId),
              )),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Card(
          child: _opcion(
            icon: Icons.logout_rounded,
            color: AppTheme.danger,
            titulo: 'Cerrar sesión',
            subtitulo: 'Salir de tu cuenta',
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            ),
            textoRojo: true,
          ),
        )
      ],
    );
  }
  Widget _opcion({required IconData icon, required Color color, required String titulo, required String subtitulo, required VoidCallback onTap, bool textoRojo = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(titulo, style: TextStyle(fontWeight: FontWeight.w600, color: textoRojo ? AppTheme.danger : AppTheme.textMain, fontSize: 14)),
      subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }
}
