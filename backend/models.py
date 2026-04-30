from sqlalchemy import Column, Integer, String, ForeignKey, Float, DateTime, Boolean
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime
# --- ESTANTE 1: CLIENTES (CU-01) ---
class Cliente(Base):
    __tablename__ = "clientes"
    id = Column(Integer, primary_key=True, index=True)
    nombre_completo = Column(String, index=True)
    telefono = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    contrasena = Column(String)
    vehiculos = relationship("Vehiculo", back_populates="dueño")
# --- ESTANTE 2: VEHÍCULOS (CU-02) ---
class Vehiculo(Base):
    __tablename__ = "vehiculos"
    id = Column(Integer, primary_key=True, index=True)
    placa = Column(String, unique=True, index=True)
    marca = Column(String)
    modelo = Column(String)
    color = Column(String)
    cliente_id = Column(Integer, ForeignKey("clientes.id"))
    dueño = relationship("Cliente", back_populates="vehiculos")
# --- ESTANTE 3: TALLERES (CU-03) ---
class Taller(Base):
    __tablename__ = "talleres"
    id = Column(Integer, primary_key=True, index=True)
    nombre_taller = Column(String, index=True)
    direccion = Column(String)
    telefono = Column(String)
    email = Column(String, unique=True, index=True)
    contrasena = Column(String)
    latitud = Column(Float, nullable=True)    # NUEVO - Func 2
    longitud = Column(Float, nullable=True)   # NUEVO - Func 2
    tecnicos = relationship("Tecnico", back_populates="taller_trabajo")
# --- ESTANTE 4: TÉCNICOS (CU-04) ---
class Tecnico(Base):
    __tablename__ = "tecnicos"
    id = Column(Integer, primary_key=True, index=True)
    nombre_completo = Column(String)
    especialidad = Column(String)
    taller_id = Column(Integer, ForeignKey("talleres.id"))
    taller_trabajo = relationship("Taller", back_populates="tecnicos")
# --- ESTANTE 5: EMERGENCIAS (CU-05) ---
class Emergencia(Base):
    __tablename__ = "emergencias"
    id = Column(Integer, primary_key=True, index=True)
    direccion = Column(String)
    descripcion = Column(String)
    estado = Column(String, default="Pendiente")
    latitud = Column(Float, nullable=True)
    longitud = Column(Float, nullable=True)
    tipo_ia = Column(String(100), nullable=True)
    severidad_ia = Column(String(50), nullable=True)
    prioridad_ia = Column(String(50), nullable=True)    # NUEVO - Func 1
    confianza_ia = Column(String(10), nullable=True)    # NUEVO - Func 1
    cliente_id = Column(Integer, ForeignKey("clientes.id"))
    vehiculo_id = Column(Integer, ForeignKey("vehiculos.id"))
    taller_id = Column(Integer, ForeignKey("talleres.id"), nullable=True)
# --- ESTANTE 6: HISTORIAL DE ESTADOS (NUEVO - Func 3) ---
class HistorialEstados(Base):
    __tablename__ = "historial_estados"
    id = Column(Integer, primary_key=True, index=True)
    emergencia_id = Column(Integer, ForeignKey("emergencias.id"))
    estado_anterior = Column(String)
    estado_nuevo = Column(String)
    descripcion = Column(String)
    fecha_cambio = Column(DateTime, default=datetime.utcnow)
