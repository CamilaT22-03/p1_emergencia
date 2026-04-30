from sqlalchemy import Column, Integer, String, ForeignKey, Float
from sqlalchemy.orm import relationship
from database import Base

# --- ESTANTE 1: CLIENTES (CU-01) ---
class Cliente(Base):
    __tablename__ = "clientes" # Así se llamará la tabla en PostgreSQL

    id = Column(Integer, primary_key=True, index=True)
    nombre_completo = Column(String, index=True)
    telefono = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    contrasena = Column(String)

    # Relación: Un cliente puede tener varios vehículos
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

    # Relación: Un taller tiene varios técnicos
    tecnicos = relationship("Tecnico", back_populates="taller_trabajo")


# --- ESTANTE 4: TÉCNICOS (CU-04) ---
class Tecnico(Base):
    __tablename__ = "tecnicos"

    id = Column(Integer, primary_key=True, index=True)
    nombre_completo = Column(String)
    especialidad = Column(String) # Ej: Mecánico general, Eléctrico, Llantas
    
    # Esta es la "cuerdita" que une al técnico con su taller
    taller_id = Column(Integer, ForeignKey("talleres.id"))
    taller_trabajo = relationship("Taller", back_populates="tecnicos")
# --- ESTANTE 5: EMERGENCIAS (CU-05) ---
class Emergencia(Base):
    __tablename__ = "emergencias"
    id = Column(Integer, primary_key=True, index=True)
    # Datos de ubicación y problema
    direccion = Column(String) # Dirección manual escrita por el cliente
    descripcion = Column(String)
    estado = Column(String, default="Pendiente") # Pendiente, En Camino, Resuelto
    latitud = Column(Float, nullable=True)
    longitud = Column(Float, nullable=True)
    tipo_ia = Column(String(100), nullable=True)
    severidad_ia = Column(String(50), nullable=True)
    # Relaciones (Foreign Keys)
    cliente_id = Column(Integer, ForeignKey("clientes.id"))
    vehiculo_id = Column(Integer, ForeignKey("vehiculos.id"))
    taller_id = Column(Integer, ForeignKey("talleres.id"), nullable=True) # Se llena cuando el taller acepta

# --- ESTANTE 6: ACEPTACIONES TALLER ---
class AceptacionTaller(Base):
    __tablename__ = "aceptaciones_taller"
    id = Column(Integer, primary_key=True, index=True)
    emergencia_id = Column(Integer, ForeignKey("emergencias.id"))
    taller_id = Column(Integer, ForeignKey("talleres.id"))
    tiempo_estimado_minutos = Column(Integer)
    mensaje = Column(String, nullable=True)
    estado = Column(String, nullable=True)
    fecha = Column(String, nullable=True)