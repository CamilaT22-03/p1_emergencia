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
  // --- VARIABLES PARA EL MODO "FICHA" ---
  emergenciaSeleccionada: Emergencia | null = null;
  procesando: boolean = false;
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
  // --- FUNCIONES DE FICHA ---
  abrirFicha(em: Emergencia): void {
    this.emergenciaSeleccionada = em;
  }
  cerrarFicha(): void {
    this.emergenciaSeleccionada = null;
  }
  // Aceptar servicio
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
