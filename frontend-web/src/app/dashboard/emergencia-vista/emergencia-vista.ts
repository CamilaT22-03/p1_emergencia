import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { EmergenciaService, Emergencia, HistorialEntry, RutaTaller } from '../../services/emergencia';
import { AuthService } from '../../services/auth.service';
interface EstadoConfig {
  label: string;
  color: string;
  bgColor: string;
  icon: string;
}
const ESTADOS_CONFIG: Record<string, EstadoConfig> = {
  'Pendiente':     { label: 'Pendiente',      color: '#b45309', bgColor: '#fef3c7', icon: '⏳' },
  'Aceptada':      { label: 'Aceptada',        color: '#1d4ed8', bgColor: '#dbeafe', icon: '✅' },
  'En Camino':     { label: 'En Camino',       color: '#c2410c', bgColor: '#ffedd5', icon: '🚗' },
  'En Proceso':    { label: 'En Proceso',      color: '#7e22ce', bgColor: '#ede9fe', icon: '🔧' },
  'Finalizada':    { label: 'Finalizada',      color: '#15803d', bgColor: '#dcfce7', icon: '🏁' },
  'Rechazada':     { label: 'Rechazada',       color: '#dc2626', bgColor: '#fee2e2', icon: '❌' },
};
const TRANSICIONES: Record<string, { estado: string; label: string; desc: string }[]> = {
  'Aceptada':   [{ estado: 'En Camino', label: '🚗 En Camino', desc: 'El técnico salió hacia el lugar' }],
  'En Camino':  [{ estado: 'En Proceso', label: '🔧 En Proceso', desc: 'El técnico llegó y empezó a trabajar' }],
  'En Proceso': [{ estado: 'Finalizada', label: '🏁 Finalizada', desc: 'Trabajo completado exitosamente' }],
};
@Component({
  selector: 'app-emergencia-vista',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './emergencia-vista.html',
  styleUrls: ['./emergencia-vista.scss']
})
export class EmergenciaVista implements OnInit, OnDestroy {
  lista: Emergencia[] = [];
  datosTaller: any = null;
  timer: any;
  seccion: string = 'inicio';
  emergenciaSeleccionada: Emergencia | null = null;
  procesando: boolean = false;
  historial: HistorialEntry[] = [];
  talleresCercanos: RutaTaller[] = [];
  cargandoRuta: boolean = false;
  cargandoHistorial: boolean = false;
  estadosConfig = ESTADOS_CONFIG;
  transiciones = TRANSICIONES;
  constructor(
    private service: EmergenciaService,
    private authService: AuthService,
    private router: Router
  ) { }
  ngOnInit(): void {
    this.datosTaller = this.authService.getUsuario();
    if (!this.datosTaller) {
      this.router.navigate(['/login']);
      return;
    }
    this.cargar();
    this.timer = setInterval(() => this.cargar(), 15000);
  }
  cargar(): void {
    this.service.getPendientes().subscribe({
      next: (res: Emergencia[]) => { this.lista = res; },
      error: (e: any) => { console.error("Error al conectar con FastAPI:", e); }
    });
  }
  getEstadoConfig(estado: string): EstadoConfig {
    return ESTADOS_CONFIG[estado] || { label: estado, color: '#6b7280', bgColor: '#f3f4f6', icon: '📋' };
  }
  abrirFicha(em: Emergencia): void {
    this.emergenciaSeleccionada = em;
    this.cargarHistorial(em.id || em.id_emergencia || 0);
    this.cargarRuta(em.id || em.id_emergencia || 0);
  }
  cerrarFicha(): void {
    this.emergenciaSeleccionada = null;
    this.historial = [];
    this.talleresCercanos = [];
  }
  aceptarEmergencia(): void {
    const idEmergencia = this.emergenciaSeleccionada?.id ?? this.emergenciaSeleccionada?.id_emergencia;
    if (!idEmergencia) return;
    this.procesando = true;
    this.service.aceptarEmergencia(idEmergencia).subscribe({
      next: () => {
        alert("¡Servicio Aceptado! Se ha notificado al cliente.");
        this.cerrarFicha();
        this.cargar();
        this.procesando = false;
      },
      error: (e: any) => {
        console.error("Error al aceptar:", e);
        alert("Hubo un error al intentar aceptar el servicio.");
        this.procesando = false;
      }
    });
  }
  ejecutarTransicion(nuevoEstado: string, descripcion: string): void {
    const idEmergencia = this.emergenciaSeleccionada?.id ?? this.emergenciaSeleccionada?.id_emergencia;
    if (!idEmergencia) return;
    this.procesando = true;
    this.service.cambiarEstado(idEmergencia, nuevoEstado, descripcion).subscribe({
      next: () => {
        this.cargarHistorial(idEmergencia);
        this.cerrarFicha();
        this.cargar();
        this.procesando = false;
      },
      error: (e: any) => {
        console.error("Error al cambiar estado:", e);
        alert("Error al actualizar el estado.");
        this.procesando = false;
      }
    });
  }
  cargarHistorial(id: number): void {
    this.cargandoHistorial = true;
    this.service.obtenerHistorial(id).subscribe({
      next: (res) => { this.historial = res; this.cargandoHistorial = false; },
      error: () => { this.cargandoHistorial = false; }
    });
  }
  cargarRuta(id: number): void {
    this.cargandoRuta = true;
    this.service.calcularRuta(id).subscribe({
      next: (res) => { this.talleresCercanos = res.ruta || []; this.cargandoRuta = false; },
      error: () => { this.cargandoRuta = false; }
    });
  }
  abrirGoogleMaps(lat: number, lon: number): void {
    window.open(`https://www.google.com/maps/dir/?api=1&destination=${lat},${lon}`, '_blank');
  }
  salir(): void {
    this.authService.cerrarSesion();
    this.router.navigate(['/login']);
  }
  ngOnDestroy(): void {
    if (this.timer) { clearInterval(this.timer); }
  }
}
