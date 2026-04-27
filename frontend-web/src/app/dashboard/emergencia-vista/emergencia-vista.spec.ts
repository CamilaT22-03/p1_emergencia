import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { of } from 'rxjs';

import { EmergenciaVista } from './emergencia-vista';
import { EmergenciaService } from '../../services/emergencia';
import { AuthService } from '../../services/auth.service';

describe('EmergenciaVista', () => {
  let component: EmergenciaVista;
  let fixture: ComponentFixture<EmergenciaVista>;

  const authServiceMock = {
    getUsuario: () => ({ nombre_taller: 'Taller Demo', usuario: 'admin' }),
    cerrarSesion: () => undefined,
  };

  const emergenciaServiceMock = {
    getPendientes: () => of([]),
    aceptarEmergencia: () => of({}),
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [EmergenciaVista],
      providers: [
        provideRouter([]),
        { provide: AuthService, useValue: authServiceMock },
        { provide: EmergenciaService, useValue: emergenciaServiceMock },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(EmergenciaVista);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
