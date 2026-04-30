import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { EmergenciaService, Emergencia } from '../../services/emergencia';
import { AuthService } from '../../services/auth.service';
@Component({
  selector: 'app-emergencia-vista',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './emergencia-vista.html',
  styleUrls: ['./emergencia-vista.scss']
})
export class EmergenciaVista implements OnInit, OnDestroy {
  // 1. Variables de datos
  lista: Emergencia[] = [];
  datosTaller: any = null;
  // 2. Variables de control
  timer: any;
  seccion: string = 'inicio';

  // --- NUEVAS VARIABLES PARA EL MODO "FICHA" ---
  emergenciaSeleccionada: Emergencia | null = null;
  procesando: boolean = false;
  cargandoDetalle: boolean = false; // Para cargar distancia/tiempo
  detalleEmergencia: any = null; // Datos completos con distancia/tiempo

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

    this.seccion = 'emergencias'; // Mostrar emergencias por defecto
    this.cargar(); // Carga las emergencias por primera vez

    // Hacemos que la tabla se actualice sola cada 15 segundos buscando nuevas emergencias
    this.timer = setInterval(() => this.cargar(), 15000);
  }
  // Descarga la lista desde FastAPI (ahora incluye pendientes y aceptadas)
  cargar(): void {
    this.service.getPendientes().subscribe({
      next: (res: Emergencia[]) => {
        this.lista = res.filter(e => e.estado === "Pendiente" || e.estado === "Aceptada");
      },
      error: (e: any) => {
        console.error("Error al conectar con FastAPI:", e);
      }
    });
  }

  // --- NUEVAS FUNCIONES PARA CONTROLAR LA PANTALLA ---
 
  // Oculta la tabla y abre la ficha completa
  abrirFicha(em: Emergencia): void {
    this.emergenciaSeleccionada = em;
    this.cargandoDetalle = true;
    
    // Cargar detalles con distancia y tiempo
    this.service.getDetalleEmergencia(em.id!).subscribe({
      next: (detalle: any) => {
        this.detalleEmergencia = detalle;
        this.cargandoDetalle = false;
      },
      error: (e: any) => {
        console.error("Error cargando detalle:", e);
        this.cargandoDetalle = false;
      }
    });
  }
  cerrarFicha(): void {
    this.emergenciaSeleccionada = null;
  }
  
  // Función para aceptar el servicio (CU-08)
  aceptarEmergencia(): void {
    const idEmergencia = this.emergenciaSeleccionada?.id ?? this.emergenciaSeleccionada?.id_emergencia;
    if (!idEmergencia) return;
    this.procesando = true;
    this.service.aceptarEmergencia(idEmergencia).subscribe({
      next: () => {
        alert("¡Servicio Aceptado! Se ha notificado al cliente que vas en camino.");
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

  // Función para finalizar el servicio (marcar como "Resuelto")
  finalizarEmergencia(): void {
    const idEmergencia = this.emergenciaSeleccionada?.id ?? this.emergenciaSeleccionada?.id_emergencia;
    if (!idEmergencia) return;

    if (!confirm("¿Estás seguro de marcar esta emergencia como resuelta?")) {
      return;
    }

    this.procesando = true;

    this.service.finalizarEmergencia(idEmergencia).subscribe({
      next: () => {
        alert("¡Emergencia finalizada! El cliente ha sido notificado.");
        this.cerrarFicha();
        this.cargar();
        this.procesando = false;
      },
      error: (e: any) => {
        console.error("Error al finalizar:", e);
        alert("Hubo un error al finalizar la emergencia.");
        this.procesando = false;
      }
    });
  }

  // --- FUNCIÓN DE SALIDA ---
  salir(): void {
    this.authService.cerrarSesion();
    this.router.navigate(['/login']);
  }

  ngOnDestroy(): void {
    // Apagamos el timer si el mecánico cierra la pestaña
    if (this.timer) {
      clearInterval(this.timer);
    }
  }
}
