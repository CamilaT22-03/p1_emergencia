import 'package:flutter/material.dart';
import '../theme.dart';
import 'vehiculos_page.dart';
import 'emergencia_page.dart';
import 'login_page.dart';
import 'package:app_cliente/pages/taller_asignado_page.dart';
import 'package:app_cliente/pages/clasificar_incidente_page.dart';
import 'historial_emergencias_page.dart';
import 'talleres_page.dart';

class DashboardPage extends StatefulWidget {
  final int clienteId;
  const DashboardPage({super.key, required this.clienteId});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['Auxilio Vial', 'Talleres', 'Mi Perfil'][_tab]),
        automaticallyImplyLeading: false,
        actions: [
          if (_tab == 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(children: [
                Icon(Icons.circle, size: 8, color: AppTheme.danger),
                SizedBox(width: 5),
                Text('En vivo', style: TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
      ),
      body: [
        _TabSOS(clienteId: widget.clienteId),
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
}

// ── TAB SOS ──────────────────────────────────────────────
class _TabSOS extends StatelessWidget {
  final int clienteId;
  const _TabSOS({required this.clienteId});

  Widget _buildAlertaAsistenciaEnCamino(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TallerAsignadoPage(solicitudId: 1)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 30),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange.shade400, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.airport_shuttle, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "¡Ayuda en camino!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Toca aquí para ver la ubicación y ETA.",
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // La estructura definitiva para evitar el bucle de renderizado en Web
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false, // Permite el scroll solo si el contenido excede la pantalla
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

                // 🔴 TU BOTÓN ROJO ORIGINAL (CU-05 INTACTO) 🔴
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

                // 🤖 NUEVO BOTÓN SECUNDARIO PARA LA IA (CU-11) 🤖
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
// ── TAB TALLERES ─────────────────────────────────────────
class _TabTalleres extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => Card(
        clipBehavior: Clip.antiAlias, 
        child: Padding( // 👇 Le quitamos el InkWell, ahora solo es Padding
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_repair_service_outlined, color: Colors.redAccent),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Taller Mecánico Pro', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                SizedBox(height: 3),
                Text('A 2.5 km · Abierto ahora', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            )),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ]),
        ),
      ),
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
        // Avatar
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

        // Opciones
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
                 '/', // Esta es la ruta de tu LoginPage que configuramos en main.dart
                 (route) => false, // Esto destruye el historial para que no puedan volver atrás
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