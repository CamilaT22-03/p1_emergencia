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
  emergenciaSeleccionada: Emergencia | null = null; // Guarda la emergencia que el mecánico está viendo
  procesando: boolean = false; // Sirve para deshabilitar el botón mientras carga

  constructor(
    private service: EmergenciaService,
    private authService: AuthService,
    private router: Router
  ) { }

  ngOnInit(): void {
    // Le pedimos al mensajero los datos
    this.datosTaller = this.authService.getUsuario();

    // Si no está logueado, lo sacamos
    if (!this.datosTaller) {
      this.router.navigate(['/login']);
      return;
    }

    this.cargar(); // Carga las emergencias por primera vez

    // Hacemos que la tabla se actualice sola cada 15 segundos buscando nuevas emergencias
    this.timer = setInterval(() => this.cargar(), 15000);
  }

  // Descarga la lista desde FastAPI
  cargar(): void {
    this.service.getPendientes().subscribe({
      next: (res: Emergencia[]) => {
        this.lista = res;
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
  }

  // Cierra la ficha y vuelve a mostrar la tabla
  cerrarFicha(): void {
    this.emergenciaSeleccionada = null;
  }

  // Función para aceptar el servicio (CU-08)
  aceptarEmergencia(): void {
    const idEmergencia = this.emergenciaSeleccionada?.id ?? this.emergenciaSeleccionada?.id_emergencia;
    if (!idEmergencia) return;

    this.procesando = true; // Mostramos que está cargando

    this.service.aceptarEmergencia(idEmergencia).subscribe({
      next: () => {
        alert("¡Servicio Aceptado! Se ha notificado al cliente que vas en camino.");
        this.cerrarFicha(); // Volvemos a la tabla
        this.cargar();      // Refrescamos (la emergencia aceptada desaparecerá de esta lista)
        this.procesando = false;
      },
      error: (e: any) => {
        console.error("Error al aceptar:", e);
        alert("Hubo un error al intentar aceptar el servicio.");
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
