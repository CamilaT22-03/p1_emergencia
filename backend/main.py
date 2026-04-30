from fastapi import FastAPI, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from database import engine, get_db
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import io
import json
import mimetypes
import random
import math
import models
import schemas
from google import genai as genai_sdk
from google.genai import types as genai_types
import os
import re
from typing import Optional
from dotenv import load_dotenv
from datetime import datetime
load_dotenv(override=True)
llave_actual = os.getenv("GEMINI_API_KEY", "")
print(f"La llave que Python está usando empieza con: {llave_actual[:10]}...")
app = FastAPI(title="API de Emergencias Vehiculares")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
models.Base.metadata.create_all(bind=engine)
# ==========================================
# FUNCIONES AUXILIARES
# ==========================================
def _obtener_mime_type(nombre_archivo: str | None, contenido_por_defecto: str = "audio/wav") -> str:
    if not nombre_archivo:
        return contenido_por_defecto
    mime_type, _ = mimetypes.guess_type(nombre_archivo)
    return mime_type or contenido_por_defecto
def _parsear_json_seguro(texto: str, valor_por_defecto: dict) -> dict:
    try:
        return json.loads(texto)
    except Exception:
        return valor_por_defecto
# ==========================================
# FUNC 1: CLASIFICACIÓN MEJORADA CON SCORING
# ==========================================
CATEGORIAS = {
    "bateria": {
        "keywords": ["bater", "bateria", "arranque", "no enciende", "no prende",
                     "sin corriente", "no da marcha", "motor gira pero no arranca",
                     "luces tenues", "bornes", "alternador"],
        "severidad_base": "Leve",
        "sugiere_grua": False,
        "prioridad_base": "Baja",
    },
    "llanta": {
        "keywords": ["llanta", "pinch", "revent", "neumático", "neumatico",
                     "ponchada", "ponchó", "desinflada", "aire de la llanta",
                     "goma baja", "rim"],
        "severidad_base": "Leve",
        "sugiere_grua": False,
        "prioridad_base": "Baja",
    },
    "choque": {
        "keywords": ["choque", "accidente", "golpe", "colision", "colisión",
                     "impacto", "chocó", "choco", "atropell", "abolladura",
                     "abolló", "raspón", "raspe", "roce"],
        "severidad_base": "Moderado",
        "sugiere_grua": False,
        "prioridad_base": "Alta",
    },
    "motor": {
        "keywords": ["motor", "humo", "temperatura", "recalent", "fuego",
                     "sobrecalent", "aceite", "fuga de aceite", "ruido del motor",
                     "motor falla", "motor se apag", "tirones", "falla de encendido",
                     "correa", "embrague"],
        "severidad_base": "Grave",
        "sugiere_grua": True,
        "prioridad_base": "Alta",
    },
    "frenos": {
        "keywords": ["freno", "no frena", "pedal de freno", "frenos", "frenado",
                     "ruido al frenar", "pastilla de freno", "disco de freno",
                     "líquido de frenos", "ABS"],
        "severidad_base": "Grave",
        "sugiere_grua": False,
        "prioridad_base": "Alta",
    },
    "electrico": {
        "keywords": ["eléctric", "electric", "cable", "fusible", "cortocircuito",
                     "no enciende las luces", "ventanas eléctricas", "panel",
                     "tablero", "luces no funcionan"],
        "severidad_base": "Moderado",
        "sugiere_grua": False,
        "prioridad_base": "Media",
    },
    "combustible": {
        "keywords": ["combustible", "gasolina", "diésel", "diesel", "tanque",
                     "sin gasolina", "quedé sin combustible", "bomba de combustible",
                     "filtro de gasolina", "se acabó la gasolina"],
        "severidad_base": "Leve",
        "sugiere_grua": False,
        "prioridad_base": "Baja",
    },
}
SEVERIDAD_GRAVE_KEYWORDS = [
    "no rueda", "torcid", "destruido", "no avanza", "no se mueve",
    "varado", "no puede circular", "imposible conducir", "grúa necesaria",
    "arrastre", "humo negro", "humo blanco", "chispas", "fuego",
    "grito de metal", "se partió", "se rompió"
]
def _clasificar_por_texto(texto: str) -> dict:
    texto_normalizado = (texto or "").lower()
    compactado = re.sub(r"\s+", " ", texto_normalizado)
    scoring = {}
    categorias_detectadas = []
    for categoria, config in CATEGORIAS.items():
        score = 0
        keywords_found = []
        for keyword in config["keywords"]:
            if keyword in compactado:
                score += 1
                keywords_found.append(keyword)
        if score > 0:
            scoring[categoria] = score
            categorias_detectadas.append((categoria, score, keywords_found))
    if not categorias_detectadas:
        return {
            "tipo_incidente": "otros",
            "nivel_severidad": "Moderado",
            "sugiere_grua": False,
            "confianza_ia": "55%",
            "prioridad": "Media",
            "explicacion": "No se identificó un tipo específico de incidente con claridad. Se recomienda revisión manual.",
        }
    categorias_detectadas.sort(key=lambda x: x[1], reverse=True)
    categoria_ganadora = categorias_detectadas[0][0]
    score_maximo = categorias_detectadas[0][1]
    keywords_ganadoras = categorias_detectadas[0][2]
    config = CATEGORIAS[categoria_ganadora]
    es_grave = any(kw in compactado for kw in SEVERIDAD_GRAVE_KEYWORDS)
    if categoria_ganadora == "choque":
        severidad = "Crítico" if es_grave else "Moderado"
        sugiere_grua = es_grave
    elif categoria_ganadora == "motor":
        severidad = "Crítico" if es_grave else "Grave"
        sugiere_grua = True
    elif categoria_ganadora == "frenos":
        severidad = "Grave" if es_grave else "Moderado"
        sugiere_grua = es_grave
    else:
        severidad = config["severidad_base"]
        if es_grave:
            severidad = "Grave"
            sugiere_grua = True
        else:
            sugiere_grua = config["sugiere_grua"]
    prioridad = _calcular_prioridad(categoria_ganadora, severidad, compactado)
    confianza_base = min(55 + score_maximo * 8, 95)
    if len(keywords_ganadoras) >= 3:
        confianza_base = min(confianza_base + 5, 95)
    explicacion = _generar_explicacion(categoria_ganadora, keywords_ganadoras, severidad)
    return {
        "tipo_incidente": categoria_ganadora,
        "nivel_severidad": severidad,
        "sugiere_grua": sugiere_grua,
        "confianza_ia": f"{confianza_base}%",
        "prioridad": prioridad,
        "explicacion": explicacion,
    }
def _calcular_prioridad(tipo: str, severidad: str, texto: str = "") -> str:
    texto_lower = texto.lower()
    urgencia_keywords = ["urgente", "ayuda", "emergencia", "peligro",
                         "familia", "niño", "niños", "herido", "herida",
                         "sangre", "hospital", "ambulancia", "rapido", "rápido"]
    hay_urgencia = any(kw in texto_lower for kw in urgencia_keywords)
    tabla_prioridad = {
        "choque":  {"Crítico": "Crítica", "Grave": "Crítica", "Moderado": "Alta", "Leve": "Media"},
        "motor":   {"Crítico": "Crítica", "Grave": "Alta", "Moderado": "Alta", "Leve": "Media"},
        "frenos":  {"Crítico": "Crítica", "Grave": "Alta", "Moderado": "Alta", "Leve": "Media"},
        "llanta":  {"Crítico": "Alta", "Grave": "Alta", "Moderado": "Media", "Leve": "Baja"},
        "bateria": {"Crítico": "Alta", "Grave": "Alta", "Moderado": "Media", "Leve": "Baja"},
        "electrico": {"Crítico": "Alta", "Grave": "Alta", "Moderado": "Media", "Leve": "Baja"},
        "combustible": {"Crítico": "Alta", "Grave": "Alta", "Moderado": "Media", "Leve": "Baja"},
    }
    prioridad = tabla_prioridad.get(tipo, {}).get(severidad, "Media")
    if hay_urgencia and prioridad not in ["Crítica"]:
        prioridad = "Alta" if prioridad == "Media" else prioridad
    return prioridad
def _generar_explicacion(categoria: str, keywords: list, severidad: str) -> str:
    explicaciones = {
        "bateria": {
            "Leve": f"Se detectó un problema de batería/arranque ({', '.join(keywords)}). Generalmente se resuelve con un puente de arranque o cambio de batería en el lugar.",
            "Moderado": f"Problema eléctrico relacionado con la batería ({', '.join(keywords)}). Podría requerir diagnóstico de alternador o sistema de carga.",
            "Grave": f"Fallo severo del sistema eléctrico/batería ({', '.join(keywords)}). Puede requerir traslado a taller para reparación completa.",
        },
        "llanta": {
            "Leve": f"Se identificó un problema con las llantas/neumáticos ({', '.join(keywords)}). Se puede reparar en el lugar con cambio de rueda.",
            "Moderado": f"Problema de neumáticos ({', '.join(keywords)}). Verificar si hay daño en el rín o sistema de suspensión.",
            "Grave": f"Daño severo en neumáticos ({', '.join(keywords)}). Posible daño adicional en suspensión o dirección.",
        },
        "choque": {
            "Moderado": f"Se reportó un incidente/choque vehicular ({', '.join(keywords)}). Daño aparentemente menor, se recomienda evaluación presencial.",
            "Grave": f"Choque con daño significativo ({', '.join(keywords)}). Posible afectación estructural. Se recomienda grúa.",
            "Crítico": f"Accidente vehicular grave ({', '.join(keywords)}). Daño estructural severo. Requiere grúa y posible asistencia de emergencia.",
        },
        "motor": {
            "Moderado": f"Problema de motor detectado ({', '.join(keywords)}). Se recomienda revisión técnica en el lugar.",
            "Grave": f"Fallo grave de motor ({', '.join(keywords)}). Alto riesgo de daño mayor. No operar el vehículo. Se recomienda grúa.",
            "Crítico": f"Fallo crítico de motor ({', '.join(keywords)}). Vehículo no operable. Requiere grúa urgente y revisión en taller.",
        },
        "frenos": {
            "Moderado": f"Problema en el sistema de frenos ({', '.join(keywords)}). No conducir el vehículo hasta inspección.",
            "Grave": f"Fallo severo de frenos ({', '.join(keywords)}). Peligro inminente. No mover el vehículo. Se requiere asistencia inmediata.",
        },
        "electrico": {
            "Leve": f"Problema eléctrico menor ({', '.join(keywords)}). Se puede diagnosticar en el lugar.",
            "Moderado": f"Fallo eléctrico significativo ({', '.join(keywords)}). Requiere diagnóstico especializado.",
        },
        "combustible": {
            "Leve": f"Problema de combustible ({', '.join(keywords)}). Se resuelve con reabastecimiento o cambio de filtro.",
        },
    }
    return explicaciones.get(categoria, {}).get(severidad,
        f"Se identificó un incidente de tipo '{categoria}' con severidad '{severidad}'. Palabras clave detectadas: {', '.join(keywords)}. Se recomienda evaluación profesional.")
# ==========================================
# FUNC 2: HAVERSINE Y ETA
# ==========================================
def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    lat1_r, lon1_r, lat2_r, lon2_r = map(math.radians, [lat1, lon1, lat2, lon2])
    dlat = lat2_r - lat1_r
    dlon = lon2_r - lon1_r
    a = math.sin(dlat / 2) ** 2 + math.cos(lat1_r) * math.cos(lat2_r) * math.sin(dlon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)
def _calcular_eta(distancia_km: float) -> int:
    velocidad_promedio = 30.0
    if distancia_km <= 2:
        velocidad_promedio = 20.0
    elif distancia_km <= 5:
        velocidad_promedio = 25.0
    elif distancia_km <= 10:
        velocidad_promedio = 35.0
    else:
        velocidad_promedio = 40.0
    tiempo_min = (distancia_km / velocidad_promedio) * 60
    tiempo_min += 5
    return max(round(tiempo_min), 5)
# ==========================================
# FUNC 3: MÁQUINA DE ESTADOS
# ==========================================
TRANSICIONES_VALIDAS = {
    "Pendiente": ["Aceptada", "Rechazada"],
    "Aceptada": ["En Camino", "Rechazada"],
    "En Camino": ["En Proceso"],
    "En Proceso": ["Finalizada"],
    "Rechazada": [],
    "Finalizada": [],
}
def _registrar_cambio_estado(db: Session, id_emergencia: int, nuevo_estado: str, descripcion: str = ""):
    emergencia = db.query(models.Emergencia).filter(models.Emergencia.id == id_emergencia).first()
    if not emergencia:
        return None
    estado_anterior = emergencia.estado
    if nuevo_estado not in TRANSICIONES_VALIDAS.get(estado_anterior, []):
        raise HTTPException(
            status_code=400,
            detail=f"Transición inválida: '{estado_anterior}' → '{nuevo_estado}'. Transiciones permitidas: {TRANSICIONES_VALIDAS.get(estado_anterior, [])}"
        )
    emergencia.estado = nuevo_estado
    historial = models.HistorialEstados(
        emergencia_id=id_emergencia,
        estado_anterior=estado_anterior,
        estado_nuevo=nuevo_estado,
        descripcion=descripcion or f"Estado cambiado a {nuevo_estado}",
        fecha_cambio=datetime.utcnow(),
    )
    db.add(historial)
    db.commit()
    db.refresh(emergencia)
    return emergencia
# ==========================================
# FUNCIONES IA (GEMINI)
# ==========================================
def _analizar_imagen_con_gemini(image_bytes: bytes) -> dict:
    if not os.getenv("GEMINI_API_KEY"):
        raise RuntimeError("No se configuró GEMINI_API_KEY")
    client = genai_sdk.Client(api_key=os.getenv("GEMINI_API_KEY"))
    image_part = genai_types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg")
    prompt = """
    Eres un perito experto en incidentes vehiculares de una compañía de seguros.
    Analiza la imagen del incidente y responde ESTRICTAMENTE con un objeto JSON válido (sin ```json ni texto extra).
    Usa exactamente esta estructura:
    {
        "tipo_incidente": "batería" | "llanta" | "choque" | "motor" | "frenos" | "eléctrico" | "combustible" | "otros",
        "nivel_severidad": "Leve" | "Moderado" | "Grave" | "Crítico",
        "sugiere_grua": true o false,
        "confianza_ia": "porcentaje, ej: 95%"
    }
    REGLAS OBLIGATORIAS:
    1. Si es "llanta" o "batería", severidad DEBE ser "Leve" o "Moderado" y sugiere_grua = false.
    2. Si es "choque", evalúa daño. Solo sugiere_grua=true si el daño impide circular.
    3. Si es "motor" visible (humo, fuego), sugiere_grua DEBE ser true.
    4. Si es "frenos", severidad mínimo "Moderado". Si es grave, sugiere_grua=true.
    5. Si no hay evidencia suficiente, responde "otros" con severidad "Moderado".
    """
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[prompt, image_part],
        config=genai_types.GenerateContentConfig(response_mime_type="application/json"),
    )
    raw_text = (response.text or "").strip()
    cleaned_text = raw_text.replace("```json", "").replace("```", "").strip()
    analisis = _parsear_json_seguro(cleaned_text, _clasificar_por_texto(cleaned_text))
    if "prioridad" not in analisis:
        analisis["prioridad"] = _calcular_prioridad(
            analisis.get("tipo_incidente", "otros"),
            analisis.get("nivel_severidad", "Moderado")
        )
    if "resumen" not in analisis:
        analisis["resumen"] = f"Clasificación automática: {analisis.get('tipo_incidente', 'otros')}"
    return analisis
def _transcribir_audio_con_gemini(audio_bytes: bytes, nombre_archivo: str | None, mime_type: str | None) -> dict:
    if not os.getenv("GEMINI_API_KEY"):
        raise RuntimeError("No se configuró GEMINI_API_KEY")
    client = genai_sdk.Client(api_key=os.getenv("GEMINI_API_KEY"))
    audio_part = genai_types.Part.from_bytes(
        data=audio_bytes,
        mime_type=mime_type or _obtener_mime_type(nombre_archivo, "audio/wav"),
    )
    prompt = """
    Eres un asistente para emergencias vehiculares.
    Transcribe el audio en español y responde solo JSON válido con esta estructura:
    {
        "transcripcion": "texto literal o aproximado",
        "resumen": "resumen corto del problema",
        "palabras_clave": ["lista", "de", "palabras"]
    }
    """
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[prompt, audio_part],
        config=genai_types.GenerateContentConfig(response_mime_type="application/json"),
    )
    raw_text = (response.text or "").strip()
    cleaned_text = raw_text.replace("```json", "").replace("```", "").strip()
    return _parsear_json_seguro(cleaned_text, {
        "transcripcion": cleaned_text,
        "resumen": cleaned_text,
        "palabras_clave": [],
    })
# ==========================================
# ENDPOINTS BÁSICOS
# ==========================================
@app.get("/")
def bienvenida():
    return {"mensaje": "¡El servidor está encendido!"}
@app.post("/clientes/")
def registrar_cliente(formulario: schemas.ClienteNuevo, db: Session = Depends(get_db)):
    nuevo_cliente = models.Cliente(
        nombre_completo=formulario.nombre_completo,
        telefono=formulario.telefono,
        email=formulario.email,
        contrasena=formulario.contrasena
    )
    db.add(nuevo_cliente)
    db.commit()
    db.refresh(nuevo_cliente)
    return {"mensaje": "¡Cliente registrado con éxito!", "datos": nuevo_cliente}
@app.post("/vehiculos/")
def registrar_vehiculo(formulario: schemas.VehiculoNuevo, db: Session = Depends(get_db)):
    nuevo_vehiculo = models.Vehiculo(
        placa=formulario.placa,
        marca=formulario.marca,
        modelo=formulario.modelo,
        color=formulario.color,
        cliente_id=formulario.cliente_id
    )
    db.add(nuevo_vehiculo)
    db.commit()
    db.refresh(nuevo_vehiculo)
    return {"mensaje": "¡Vehículo registrado!", "datos": nuevo_vehiculo}
@app.post("/talleres/")
def registrar_taller(formulario: schemas.TallerNuevo, db: Session = Depends(get_db)):
    nuevo_taller = models.Taller(
        nombre_taller=formulario.nombre_taller,
        direccion=formulario.direccion,
        telefono=formulario.telefono,
        email=formulario.email,
        contrasena=formulario.contrasena,
        latitud=formulario.latitud,
        longitud=formulario.longitud,
    )
    db.add(nuevo_taller)
    db.commit()
    db.refresh(nuevo_taller)
    return {"mensaje": "¡Taller registrado!", "datos": nuevo_taller}
@app.post("/tecnicos/")
def registrar_tecnico(formulario: schemas.TecnicoNuevo, db: Session = Depends(get_db)):
    nuevo_tecnico = models.Tecnico(
        nombre_completo=formulario.nombre_completo,
        especialidad=formulario.especialidad,
        taller_id=formulario.taller_id
    )
    db.add(nuevo_tecnico)
    db.commit()
    db.refresh(nuevo_tecnico)
    return {"mensaje": "¡Técnico registrado!", "datos": nuevo_tecnico}
@app.post("/login-taller/")
def iniciar_sesion(credenciales: schemas.LoginTaller, db: Session = Depends(get_db)):
    taller_encontrado = db.query(models.Taller).filter(models.Taller.email == credenciales.email).first()
    if taller_encontrado is None or taller_encontrado.contrasena != credenciales.contrasena:
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")
    return {"mensaje": "¡Bienvenido al sistema!", "datos": taller_encontrado}
@app.post("/login-cliente/")
def login_cliente(credenciales: schemas.LoginCliente, db: Session = Depends(get_db)):
    user = db.query(models.Cliente).filter(models.Cliente.email == credenciales.email).first()
    if not user or user.contrasena != credenciales.contrasena:
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")
    return {"mensaje": "Bienvenido", "usuario": user.nombre_completo, "usuario_id": user.id}
@app.get("/vehiculos/cliente/{cliente_id}")
def obtener_vehiculos_de_cliente(cliente_id: int, db: Session = Depends(get_db)):
    vehiculos = db.query(models.Vehiculo).filter(models.Vehiculo.cliente_id == cliente_id).all()
    return vehiculos
@app.get("/emergencias/cliente/{cliente_id}")
def ver_emergencias_de_cliente(cliente_id: int, db: Session = Depends(get_db)):
    emergencias = (
        db.query(models.Emergencia)
        .filter(models.Emergencia.cliente_id == cliente_id)
        .order_by(models.Emergencia.id.desc())
        .all()
    )
    return [
        {
            "id": emergencia.id,
            "cliente_id": emergencia.cliente_id,
            "vehiculo_id": emergencia.vehiculo_id,
            "direccion": emergencia.direccion,
            "descripcion": emergencia.descripcion,
            "estado": emergencia.estado,
            "latitud": emergencia.latitud,
            "longitud": emergencia.longitud,
            "tipo_ia": emergencia.tipo_ia,
            "severidad_ia": emergencia.severidad_ia,
            "prioridad_ia": emergencia.prioridad_ia,
            "confianza_ia": emergencia.confianza_ia,
            "taller_id": emergencia.taller_id,
        }
        for emergencia in emergencias
    ]
@app.get("/talleres/")
def listar_talleres(db: Session = Depends(get_db)):
    talleres = db.query(models.Taller).order_by(models.Taller.nombre_taller.asc()).all()
    return [
        {
            "id": taller.id,
            "nombre_taller": taller.nombre_taller,
            "direccion": taller.direccion,
            "telefono": taller.telefono,
            "email": taller.email,
            "latitud": taller.latitud,
            "longitud": taller.longitud,
        }
        for taller in talleres
    ]
@app.get("/emergencias-taller/")
def ver_emergencias_para_taller(db: Session = Depends(get_db)):
    return db.query(models.Emergencia).filter(models.Emergencia.estado == "Pendiente").all()
# ==========================================
# FUNC 1: ENDPOINT CLASIFICAR TEXTO
# ==========================================
@app.post("/api/emergencias/clasificar-texto")
def clasificar_emergencia_por_texto(datos: schemas.ClasificacionTexto):
    resultado = _clasificar_por_texto(datos.descripcion)
    return resultado
# ==========================================
# FUNC 2: ENDPOINT CALCULAR RUTA
# ==========================================
@app.get("/api/emergencias/{id}/ruta")
def calcular_ruta_emergencia(id: int, db: Session = Depends(get_db)):
    emergencia = db.query(models.Emergencia).filter(models.Emergencia.id == id).first()
    if not emergencia or emergencia.latitud is None or emergencia.longitud is None:
        raise HTTPException(status_code=404, detail="Emergencia no encontrada o sin coordenadas")
    talleres = db.query(models.Taller).filter(
        models.Taller.latitud.isnot(None),
        models.Taller.longitud.isnot(None)
    ).all()
    if not talleres:
        return {"mensaje": "No hay talleres con coordenadas registradas", "ruta": []}
    rutas = []
    for taller in talleres:
        distancia = _haversine(
            emergencia.latitud, emergencia.longitud,
            taller.latitud, taller.longitud
        )
        eta = _calcular_eta(distancia)
        rutas.append({
            "taller_id": taller.id,
            "nombre_taller": taller.nombre_taller,
            "direccion": taller.direccion,
            "telefono": taller.telefono,
            "distancia_km": distancia,
            "eta_minutos": eta,
        })
    rutas.sort(key=lambda x: x["distancia_km"])
    return {
        "emergencia_id": id,
        "ubicacion": {"latitud": emergencia.latitud, "longitud": emergencia.longitud},
        "ruta": rutas,
    }
# ==========================================
# ENDPOINT TALLER ASIGNADO (actualizado con cálculo real)
# ==========================================
@app.get("/api/emergencias/{solicitud_id}/taller-asignado")
async def obtener_taller_asignado(solicitud_id: int, db: Session = Depends(get_db)):
    emergencia = db.query(models.Emergencia).filter(models.Emergencia.id == solicitud_id).first()
    if not emergencia:
        raise HTTPException(status_code=404, detail="Emergencia no encontrada")
    if emergencia.taller_id:
        taller = db.query(models.Taller).filter(models.Taller.id == emergencia.taller_id).first()
        if taller and taller.latitud and taller.longitud and emergencia.latitud and emergencia.longitud:
            distancia = _haversine(
                taller.latitud, taller.longitud,
                emergencia.latitud, emergencia.longitud
            )
            eta = _calcular_eta(distancia)
            return {
                "id_solicitud": solicitud_id,
                "nombre_taller": taller.nombre_taller,
                "tiempo_estimado": f"{eta} mins",
                "distancia_km": distancia,
                "telefono_taller": taller.telefono,
            }
    return {
        "id_solicitud": solicitud_id,
        "nombre_taller": emergencia.taller_id or "No asignado",
        "tiempo_estimado": "N/A",
        "distancia_km": None,
    }
# ==========================================
# FUNC 3: ENDPOINTS DE ESTADOS
# ==========================================
@app.patch("/emergencias/{id_emergencia}/aceptar")
def aceptar_emergencia(id_emergencia: int, db: Session = Depends(get_db)):
    try:
        emergencia = _registrar_cambio_estado(db, id_emergencia, "Aceptada", "El taller aceptó la solicitud")
        if emergencia:
            return {"mensaje": "Emergencia aceptada con éxito", "estado": emergencia.estado}
        raise HTTPException(status_code=404, detail="Emergencia no encontrada")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
@app.patch("/emergencias/{id_emergencia}/estado")
def cambiar_estado_emergencia(id_emergencia: int, cambio: schemas.CambioEstado, db: Session = Depends(get_db)):
    try:
        emergencia = _registrar_cambio_estado(db, id_emergencia, cambio.estado, cambio.descripcion)
        if emergencia:
            return {
                "mensaje": f"Estado cambiado a {cambio.estado}",
                "estado_anterior": emergencia.estado,
                "estado_nuevo": cambio.estado,
            }
        raise HTTPException(status_code=404, detail="Emergencia no encontrada")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
@app.get("/emergencias/{id_emergencia}/historial")
def obtener_historial_estados(id_emergencia: int, db: Session = Depends(get_db)):
    historial = (
        db.query(models.HistorialEstados)
        .filter(models.HistorialEstados.emergencia_id == id_emergencia)
        .order_by(models.HistorialEstados.fecha_cambio.desc())
        .all()
    )
    return [
        {
            "id": h.id,
            "estado_anterior": h.estado_anterior,
            "estado_nuevo": h.estado_nuevo,
            "descripcion": h.descripcion,
            "fecha_cambio": h.fecha_cambio.isoformat() if h.fecha_cambio else None,
        }
        for h in historial
    ]
# ==========================================
# ENDPOINTS DE IA (IMAGEN, AUDIO, REGISTRO INTELIGENTE)
# ==========================================
@app.post("/api/emergencias/clasificar-imagen")
async def clasificar_incidente(imagen: UploadFile = File(...)):
    try:
        print(f"--- Recibiendo imagen: {imagen.filename} ---")
        image_bytes = await imagen.read()
        datos_ia = _analizar_imagen_con_gemini(image_bytes)
        return {"analisis_ia": datos_ia}
    except Exception as e:
        print(f"ERROR CRÍTICO: {str(e)}")
        return {"error": str(e)}
@app.post("/api/emergencias/transcribir-audio")
async def transcribir_audio(audio: UploadFile = File(...)):
    try:
        audio_bytes = await audio.read()
        datos_audio = _transcribir_audio_con_gemini(audio_bytes, audio.filename, audio.content_type)
        return {
            "transcripcion": datos_audio.get("transcripcion", ""),
            "resumen": datos_audio.get("resumen", ""),
            "palabras_clave": datos_audio.get("palabras_clave", []),
        }
    except Exception as e:
        print(f"ERROR CRÍTICO AUDIO: {str(e)}")
        return {"error": str(e)}
@app.post("/api/emergencias/registrar-inteligente")
async def registrar_emergencia_inteligente(
    cliente_id: int = Form(...),
    vehiculo_id: int = Form(...),
    direccion: str = Form(...),
    descripcion: str = Form(""),
    latitud: Optional[float] = Form(None),
    longitud: Optional[float] = Form(None),
    imagen: Optional[UploadFile] = File(None),
    audio: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
):
    try:
        descripcion_base = descripcion.strip()
        analisis_imagen = None
        analisis_audio = None
        transcripcion_audio = ""
        if audio is not None:
            audio_bytes = await audio.read()
            analisis_audio = _transcribir_audio_con_gemini(audio_bytes, audio.filename, audio.content_type)
            transcripcion_audio = analisis_audio.get("transcripcion", "")
        if imagen is not None:
            imagen_bytes = await imagen.read()
            analisis_imagen = _analizar_imagen_con_gemini(imagen_bytes)
        texto_apoyo = " ".join(
            parte for parte in [descripcion_base, transcripcion_audio, (analisis_audio or {}).get("resumen", "")] if parte
        )
        if analisis_imagen:
            tipo_ia = analisis_imagen.get("tipo_incidente", "otros")
            severidad_ia = analisis_imagen.get("nivel_severidad", "Moderado")
            sugiere_grua = bool(analisis_imagen.get("sugiere_grua", False))
            confianza_ia = analisis_imagen.get("confianza_ia", "70%")
        else:
            clasificacion_texto = _clasificar_por_texto(texto_apoyo)
            tipo_ia = clasificacion_texto["tipo_incidente"]
            severidad_ia = clasificacion_texto["nivel_severidad"]
            sugiere_grua = bool(clasificacion_texto["sugiere_grua"])
            confianza_ia = clasificacion_texto["confianza_ia"]
        prioridad = _calcular_prioridad(tipo_ia, severidad_ia, texto_apoyo)
        resumen = (analisis_audio or {}).get("resumen") or descripcion_base or "Incidente vehicular reportado"
        descripcion_guardada = descripcion_base
        if transcripcion_audio:
            descripcion_guardada = f"{descripcion_base}\nTranscripción audio: {transcripcion_audio}".strip()
        nueva_emergencia = models.Emergencia(
            cliente_id=cliente_id,
            vehiculo_id=vehiculo_id,
            direccion=direccion,
            descripcion=descripcion_guardada,
            estado="Pendiente",
            latitud=latitud,
            longitud=longitud,
            tipo_ia=tipo_ia,
            severidad_ia=severidad_ia,
            prioridad_ia=prioridad,
            confianza_ia=confianza_ia,
        )
        db.add(nueva_emergencia)
        db.commit()
        db.refresh(nueva_emergencia)
        return {
            "mensaje": "Emergencia analizada y registrada con éxito",
            "datos": nueva_emergencia,
            "analisis_ia": {
                "tipo_ia": tipo_ia,
                "severidad_ia": severidad_ia,
                "prioridad": prioridad,
                "sugiere_grua": sugiere_grua,
                "confianza_ia": confianza_ia,
                "resumen": resumen,
                "transcripcion_audio": transcripcion_audio,
            },
        }
    except Exception as e:
        print(f"ERROR CRÍTICO REGISTRO INTELIGENTE: {str(e)}")
        return {"error": str(e)}
