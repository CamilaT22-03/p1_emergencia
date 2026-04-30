import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../environments/environment';
// Definimos la estructura exacta que nos manda FastAPI
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
  estado: string;
}
@Injectable({
  providedIn: 'root'
})
export class EmergenciaService {
  // Tu IP de FastAPI
  private apiUrl = environment.apiUrl;
  constructor(private http: HttpClient) { }

  // Obtener la lista (excluyendo "Resuelto")
  getPendientes(): Observable<Emergencia[]> {
    return this.http.get<any>(`${this.apiUrl}/emergencias-taller/`).pipe(
      map(res => {
        // Si la respuesta tiene 'value', extraer el array
        if (res && res.value && Array.isArray(res.value)) {
          return res.value;
        }
        // Si ya es un array, devolverlo directo
        if (Array.isArray(res)) {
          return res;
        }
        return [];
      })
    );
  }
  // Aceptar el caso
  aceptarEmergencia(id: number): Observable<any> {
    return this.http.patch(`${this.apiUrl}/emergencias/${id}/aceptar`, {});
  }

  // Finalizar el caso (marcar como "Resuelto")
  finalizarEmergencia(id: number): Observable<any> {
    return this.http.patch(`${this.apiUrl}/emergencias/${id}/finalizar`, {});
  }

  // Obtener detalles completos (con distancia y tiempo)
  getDetalleEmergencia(id: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/api/emergencias/${id}/taller-asignado`);
  }
}
