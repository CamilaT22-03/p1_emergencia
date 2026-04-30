from pydantic import BaseModel
from typing import Optional
from datetime import datetime
# ==========================================
# FUNC 1: CLASIFICACIÓN DE TEXTO
# ==========================================
class ClasificacionTexto(BaseModel):
    descripcion: str
class ResultadoClasificacion(BaseModel):
    tipo_incidente: str
    nivel_severidad: str
    prioridad: str
    sugiere_grua: bool
    confianza_ia: str
    explicacion: str
# ==========================================
# CLIENTES
# ==========================================
class ClienteNuevo(BaseModel):
    nombre_completo: str
    telefono: str
    email: str
    contrasena: str
class ClienteCreate(BaseModel):
    nombre_completo: str
    email: str
    contrasena: str
    telefono: str
# ==========================================
# VEHÍCULOS
# ==========================================
class VehiculoNuevo(BaseModel):
    placa: str
    marca: str
    modelo: str
    color: str
    cliente_id: int
class VehiculoCreate(BaseModel):
    placa: str
    marca: str
    modelo: str
    color: str
    cliente_id: int
# ==========================================
# TALLERES (Func 2: + latitud/longitud)
# ==========================================
class TallerNuevo(BaseModel):
    nombre_taller: str
    direccion: str
    telefono: str
    email: str
    contrasena: str
    latitud: Optional[float] = None    # NUEVO - Func 2
    longitud: Optional[float] = None   # NUEVO - Func 2
# ==========================================
# TÉCNICOS
# ==========================================
class TecnicoNuevo(BaseModel):
    nombre_completo: str
    especialidad: str
    taller_id: int
# ==========================================
# EMERGENCIAS (Func 1: + prioridad_ia, confianza_ia)
# ==========================================
class EmergenciaNueva(BaseModel):
    cliente_id: int
    vehiculo_id: int
    direccion: str
    descripcion: str
    latitud: Optional[float] = None
    longitud: Optional[float] = None
    tipo_ia: Optional[str] = None
    severidad_ia: Optional[str] = None
    prioridad_ia: Optional[str] = None      # NUEVO - Func 1
    confianza_ia: Optional[str] = None      # NUEVO - Func 1
class EmergenciaResponse(EmergenciaNueva):
    id: int
    estado: str
    class Config:
        from_attributes = True
# ==========================================
# FUNC 3: MÁQUINA DE ESTADOS
# ==========================================
class CambioEstado(BaseModel):
    estado: str
    descripcion: Optional[str] = ""
class HistorialEntry(BaseModel):
    id: int
    emergencia_id: int
    estado_anterior: str
    estado_nuevo: str
    descripcion: str
    fecha_cambio: datetime
    class Config:
        from_attributes = True
# ==========================================
# LOGIN
# ==========================================
class LoginTaller(BaseModel):
    email: str
    contrasena: str
class LoginCliente(BaseModel):
    email: str
    contrasena: str
