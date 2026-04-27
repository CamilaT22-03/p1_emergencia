import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http'; // <--- Importamos al cartero aquí también
import { environment } from '../../environments/environment';

@Component({
  selector: 'app-registro-taller',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './registro-taller.html',
  styleUrl: './registro-taller.scss'
})
export class RegistroTallerComponent {
  
  taller = {
    nombre_taller: '',
    direccion: '',
    telefono: '',
    email: '',
    contrasena: ''
  };

  // Le decimos al componente que usaremos al cartero
  constructor(private http: HttpClient) {} 

  guardarTaller() {
    // Aquí ocurre la magia: El cartero viaja a la ventanilla de FastAPI (puerto 8000)
    this.http.post(`${environment.apiUrl}/talleres/`, this.taller).subscribe({
      
      // Si el Backend responde que todo salió bien:
      next: (respuesta: any) => {
        alert('🎉 ' + respuesta.mensaje); // Mostrará "¡Taller registrado!"
        // Limpiamos las cajitas después de guardar
        this.taller = { nombre_taller: '', direccion: '', telefono: '', email: '', contrasena: '' };
      },

      // Si hay un error (ej. el backend está apagado):
      error: (error) => {
        alert('Ups, hubo un problema. ¿Está encendido el Backend?');
        console.error(error);
      }
    });
  }
}