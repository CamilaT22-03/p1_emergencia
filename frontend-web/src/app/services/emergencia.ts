import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
export interface Emergencia {
  id?: number;
  id_emergencia?: number;
  cliente_id: number;
  descripcion: string;
  direccion: string;
  latitud: number;
  longitud: number;
  tipo_ia: string;
  severidad_ia: string;
  prioridad_ia?: string;
  confianza_ia?: string;
  estado: string;
}
export interface RutaTaller {
  taller_id: number;
  nombre_taller: string;
  direccion: string;
  telefono: string;
  distancia_km: number;
  eta_minutos: number;
}
export interface HistorialEntry {
  id: number;
  estado_anterior: string;
  estado_nuevo: string;
  descripcion: string;
  fecha_cambio: string;
}
@Injectable({
  providedIn: 'root'
})
export class EmergenciaService {
  private apiUrl = environment.apiUrl;
  constructor(private http: HttpClient) { }
  getPendientes(): Observable<Emergencia[]> {
    return this.http.get<Emergencia[]>(`${this.apiUrl}/emergencias-taller/`);
  }
  aceptarEmergencia(id: number): Observable<any> {
    return this.http.patch(`${this.apiUrl}/emergencias/${id}/aceptar`, {});
  }
  cambiarEstado(id: number, estado: string, descripcion: string = ''): Observable<any> {
    return this.http.patch(`${this.apiUrl}/emergencias/${id}/estado`, { estado, descripcion });
  }
  obtenerHistorial(id: number): Observable<HistorialEntry[]> {
    return this.http.get<HistorialEntry[]>(`${this.apiUrl}/emergencias/${id}/historial`);
  }
  calcularRuta(emergenciaId: number): Observable<{ ruta: RutaTaller[] }> {
    return this.http.get<{ ruta: RutaTaller[] }>(`${this.apiUrl}/api/emergencias/${emergenciaId}/ruta`);
  }
  clasificarTexto(descripcion: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/api/emergencias/clasificar-texto`, { descripcion });
  }
}
