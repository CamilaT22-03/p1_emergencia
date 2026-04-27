import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { of } from 'rxjs';

import { LoginTaller } from './login-taller';
import { AuthService } from '../services/auth.service';

describe('LoginTaller', () => {
  let component: LoginTaller;
  let fixture: ComponentFixture<LoginTaller>;

  const authServiceMock = {
    login: () => of({ datos: { nombre_taller: 'Taller Demo' } })
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [LoginTaller],
      providers: [
        provideRouter([]),
        { provide: AuthService, useValue: authServiceMock },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(LoginTaller);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
