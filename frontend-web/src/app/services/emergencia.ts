import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
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

  // Obtener la lista
  getPendientes(): Observable<Emergencia[]> {
    return this.http.get<Emergencia[]>(`${this.apiUrl}/emergencias-taller/`);
  }

  // Aceptar el caso
  aceptarEmergencia(id: number): Observable<any> {
    return this.http.patch(`${this.apiUrl}/emergencias/${id}/aceptar`, {});
  }
}