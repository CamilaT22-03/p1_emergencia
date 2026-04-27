import { Injectable, PLATFORM_ID, Inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { environment } from '../../environments/environment';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private apiUrl = environment.apiUrl;
  private readonly STORAGE_KEY = 'taller_sesion';
  private datosenMemoria: any = null; // fallback para SSR

  constructor(
    private http: HttpClient,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {}

  private esBrowser(): boolean {
    return isPlatformBrowser(this.platformId);
  }

  login(email: string, contrasena: string): Observable<any> {
  return this.http.post(`${this.apiUrl}/login-taller/`, { email, contrasena }).pipe(
    tap((res: any) => {
      // ⚠️ AQUÍ EL CAMBIO: añadimos .datos porque tu FastAPI lo envía así
      this.datosenMemoria = res.datos; 
      
      if (this.esBrowser()) {
        localStorage.setItem(this.STORAGE_KEY, JSON.stringify(res.datos));
      }
    })
  );
}

  getUsuario(): any {
    if (this.datosenMemoria) return this.datosenMemoria;
    if (this.esBrowser()) {
      const guardado = localStorage.getItem(this.STORAGE_KEY);
      return guardado ? JSON.parse(guardado) : null;
    }
    return null;
  }

  cerrarSesion(): void {
    this.datosenMemoria = null;
    if (this.esBrowser()) {
      localStorage.removeItem(this.STORAGE_KEY);
    }
  }
}