from fastapi import FastAPI, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from database import engine, get_db
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import io
import json
import mimetypes
import random
import models
import schemas
from google import genai as genai_sdk
from google.genai import types as genai_types
import os
import re
from typing import Optional
from dotenv import load_dotenv

load_dotenv(override=True) 

# Imprime solo para confirmar (luego borras esta línea)
llave_actual = os.getenv("GEMINI_API_KEY", "")
print(f"La llave que Python está usando empieza con: {llave_actual[:10]}...")
# El Gerente abre el restaurante
app = FastAPI(title="API de Emergencias Vehiculares")

# --- 2. LE DAMOS PERMISO A ANGULAR PARA ENTRAR AL RESTAURANTE ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:4200",
        "https://taller-emergencias.vercel.app"
    ], # La dirección de tu Angular
    allow_credentials=True,
    allow_methods=["*"], # Permite POST, GET, etc.
    allow_headers=["*"],
)

# Construimos los estantes
models.Base.metadata.create_all(bind=engine)


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


def _clasificar_por_texto(texto: str) -> dict:
    texto_normalizado = (texto or "").lower()
    compactado = re.sub(r"\s+", " ", texto_normalizado)

    if any(palabra in compactado for palabra in ["bater", "arranque", "no enciende", "no prende", "sin corriente"]):
        return {
            "tipo_incidente": "batería",
            "nivel_severidad": "Leve",
            "sugiere_grua": False,
            "confianza_ia": "74%",
            "prioridad": "Media",
        }

    if any(palabra in compactado for palabra in ["llanta", "pinch", "revent", "neumático", "neumatico"]):
        return {
            "tipo_incidente": "llanta",
            "nivel_severidad": "Leve",
            "sugiere_grua": False,
            "confianza_ia": "78%",
            "prioridad": "Media",
        }

    if any(palabra in compactado for palabra in ["choque", "accidente", "golpe", "colision", "colisión"]):
        grave = any(palabra in compactado for palabra in ["no rueda", "torcid", "destruido", "fren", "motor"])
        return {
            "tipo_incidente": "choque",
            "nivel_severidad": "Crítico" if grave else "Moderado",
            "sugiere_grua": grave,
            "confianza_ia": "70%",
            "prioridad": "Alta" if grave else "Media",
        }

    if any(palabra in compactado for palabra in ["motor", "humo", "temperatura", "recalent", "fuego"]):
        return {
            "tipo_incidente": "motor",
            "nivel_severidad": "Grave",
            "sugiere_grua": True,
            "confianza_ia": "76%",
            "prioridad": "Alta",
        }

    return {
        "tipo_incidente": "otros",
        "nivel_severidad": "Moderado",
        "sugiere_grua": False,
        "confianza_ia": "60%",
        "prioridad": "Media",
    }


def _analizar_imagen_con_gemini(image_bytes: bytes) -> dict:
    if not os.getenv("GEMINI_API_KEY"):
        raise RuntimeError("No se configuró GEMINI_API_KEY")

    client = genai_sdk.Client(api_key=os.getenv("GEMINI_API_KEY"))
    image_part = genai_types.Part.from_bytes(
        data=image_bytes,
        mime_type="image/jpeg",
    )

    prompt = """
    Eres un perito experto en incidentes vehiculares de una compañía de seguros.
    Analiza la imagen del incidente y responde ESTRICTAMENTE con un objeto JSON válido (sin ```json ni texto extra).
    Usa exactamente esta estructura:
    {
        "tipo_incidente": "batería" | "llanta" | "choque" | "motor" | "otros",
        "nivel_severidad": "Leve" | "Moderado" | "Grave" | "Crítico",
        "sugiere_grua": true o false,
        "confianza_ia": "porcentaje, ej: 95%"
    }

    REGLAS OBLIGATORIAS PARA TU ANÁLISIS:
    1. Si el incidente es "llanta" (pinchada, reventada) o "batería", el nivel_severidad DEBE ser "Leve" o "Moderado" y sugiere_grua DEBE SER SIEMPRE false (esto se repara en el lugar, no requiere grúa).
    2. Si es un "choque", evalúa el daño de la carrocería. Solo si el daño impide que el auto ruede con seguridad (ej. llantas torcidas, frente destruido), sugiere_grua será true. Si es un raspón o choque leve, será false.
    3. Si es un problema de "motor" visible (humo, fuego), sugiere_grua DEBE ser true.
    4. Si no hay suficiente evidencia, responde como "otros" con severidad "Moderado" y confianza menor al 70%.
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
        analisis["prioridad"] = _clasificar_por_texto(analisis.get("tipo_incidente", "")).get("prioridad", "Media")
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
    return _parsear_json_seguro(
        cleaned_text,
        {
            "transcripcion": cleaned_text,
            "resumen": cleaned_text,
            "palabras_clave": [],
        },
    )

# --- VENTANILLA DE ATENCIÓN (Endpoints) ---

@app.get("/")
def bienvenida():
    return {"mensaje": "¡El servidor está encendido!"}

# CU-01: VENTANILLA PARA REGISTRAR CLIENTES
@app.post("/clientes/")
def registrar_cliente(formulario: schemas.ClienteNuevo, db: Session = Depends(get_db)):
    
    # 1. El mesero agarra los datos del formulario de papel
    nuevo_cliente = models.Cliente(
        nombre_completo=formulario.nombre_completo,
        telefono=formulario.telefono,
        email=formulario.email,
        contrasena=formulario.contrasena
    )
    
    # 2. El mesero va a la bodega y lo pone en el estante
    db.add(nuevo_cliente)
    db.commit() # Confirma que sí lo quiere guardar
    db.refresh(nuevo_cliente) # Refresca para ver el ID (número) que le tocó
    
    # 3. Le avisa al cliente que todo salió bien
    return {"mensaje": "¡Cliente registrado con éxito!", "datos": nuevo_cliente}
# ==========================================
# CU-02: VENTANILLA PARA REGISTRAR VEHÍCULOS
# ==========================================
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

# ==========================================
# CU-03: VENTANILLA PARA REGISTRAR TALLERES
# ==========================================
@app.post("/talleres/")
def registrar_taller(formulario: schemas.TallerNuevo, db: Session = Depends(get_db)):
    nuevo_taller = models.Taller(
        nombre_taller=formulario.nombre_taller,
        direccion=formulario.direccion,
        telefono=formulario.telefono,
        email=formulario.email,
        contrasena=formulario.contrasena
    )
    db.add(nuevo_taller)
    db.commit()
    db.refresh(nuevo_taller)
    return {"mensaje": "¡Taller registrado!", "datos": nuevo_taller}

# ==========================================
# CU-04: VENTANILLA PARA REGISTRAR TÉCNICOS
# ==========================================
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
# CU-05: VENTANILLA PARA REPORTAR EMERGENCIA
# ==========================================
@app.post("/emergencias/")
def reportar_emergencia(formulario: schemas.EmergenciaNueva, db: Session = Depends(get_db)):
    nueva_emergencia = models.Emergencia(
        cliente_id=formulario.cliente_id,
        vehiculo_id=formulario.vehiculo_id,
        direccion=formulario.direccion, # <--- ¡El mesero anota la dirección!
        descripcion=formulario.descripcion,
        estado="Pendiente"
    )
    db.add(nueva_emergencia)
    db.commit()
    db.refresh(nueva_emergencia)
    
    return {"mensaje": "¡Emergencia reportada! Buscando taller cercano...", "datos": nueva_emergencia}

# ==========================================
# LOGIN: VENTANILLA PARA INICIAR SESIÓN
# ==========================================
@app.post("/login-taller/")
def iniciar_sesion(credenciales: schemas.LoginTaller, db: Session = Depends(get_db)):
    
    # 1. El guardia busca en la base de datos si existe ese correo
    taller_encontrado = db.query(models.Taller).filter(models.Taller.email == credenciales.email).first()
    
    # 2. Si no lo encuentra, o si la contraseña no es igualita, lo rebota
    if taller_encontrado == None or taller_encontrado.contrasena != credenciales.contrasena:
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos ❌")
        
    # 3. Si todo está perfecto, lo deja pasar
    return {"mensaje": "¡Bienvenido al sistema!", "datos": taller_encontrado}

@app.post("/clientes/")
def registrar_cliente(cliente: schemas.ClienteCreate, db: Session = Depends(get_db)):
    nuevo_cliente = models.Cliente(**cliente.dict())
    db.add(nuevo_cliente)
    db.commit()
    db.refresh(nuevo_cliente)
    return {"mensaje": "¡Usuario creado con éxito! ✅"}

@app.post("/login-cliente/")
def login_cliente(credenciales: schemas.LoginCliente, db: Session = Depends(get_db)):
    user = db.query(models.Cliente).filter(models.Cliente.email == credenciales.email).first()
    if not user or user.contrasena != credenciales.contrasena:
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")
    
    # Al final de la función login_cliente:
    return {"mensaje": "Bienvenido", "usuario": user.nombre_completo, "usuario_id": user.id}

@app.post("/vehiculos/")
def registrar_vehiculo(vehiculo: schemas.VehiculoCreate, db: Session = Depends(get_db)):
    nuevo_auto = models.Vehiculo(**vehiculo.dict())
    db.add(nuevo_auto)
    db.commit()
    db.refresh(nuevo_auto)
    return {"mensaje": "¡Vehículo registrado con éxito! 🚗"}


# Agrégalo junto a tus otras rutas (@app.post, etc.)

@app.get("/vehiculos/cliente/{cliente_id}")
def obtener_vehiculos_de_cliente(cliente_id: int, db: Session = Depends(get_db)):
    # Buscamos en la base de datos todos los vehículos que tengan ese cliente_id
    vehiculos = db.query(models.Vehiculo).filter(models.Vehiculo.cliente_id == cliente_id).all()
    return vehiculos

@app.post("/emergencias/")
def registrar_emergencia(emergencia: schemas.EmergenciaNueva, db: Session = Depends(get_db)):
    # Esta línea es la que hace la magia de guardar en PostgreSQL
    nueva_e = models.Emergencia(
        cliente_id=emergencia.cliente_id,
        vehiculo_id=emergencia.vehiculo_id,
        direccion=emergencia.direccion,
        descripcion=emergencia.descripcion,
        estado="Pendiente"
    )
    db.add(nueva_e)
    db.commit()
    db.refresh(nueva_e)
    return {"mensaje": "Emergencia guardada en BD", "id": nueva_e.id}

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
        }
        for taller in talleres
    ]

@app.get("/emergencias-taller/")
def ver_emergencias_para_taller(db: Session = Depends(get_db)):
    # El taller llamará a esta ruta desde su web para ver la lista
    return db.query(models.Emergencia).filter(models.Emergencia.estado == "Pendiente").all()

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
            "taller_id": emergencia.taller_id,
        }
        for emergencia in emergencias
    ]
# Ruta para que el taller Acepte la emergencia
@app.patch("/emergencias/{id_emergencia}/aceptar")
def aceptar_emergencia(id_emergencia: int, db: Session = Depends(get_db)):
    emergencia = db.query(models.Emergencia).filter(models.Emergencia.id == id_emergencia).first()
    if emergencia:
        emergencia.estado = "Aceptada"
        db.commit()
        return {"mensaje": "Emergencia aceptada con éxito"}
    return {"error": "Emergencia no encontrada"}
# ---------------------------------------------------------
# CU-07: Visualizar Taller Asignado y ETA
# ---------------------------------------------------------
@app.get("/api/emergencias/{solicitud_id}/taller-asignado")
async def obtener_taller_asignado(solicitud_id: int):
    # NOTA: En el futuro, aquí haremos una consulta a tu base de datos 
    # buscando la 'solicitud_id'. Por ahora, devolveremos datos simulados 
    # pero que viajan de forma real desde el servidor hasta la app.
    
    return {
        "id_solicitud": solicitud_id,
        "nombre_taller": "Taller Mecánico 'El Tuercas' (Desde Backend)",
        "tiempo_estimado": "12 mins",
        "distancia_km": 3.8,
        "telefono_tecnico": "+591 79876543"
    }
# ---------------------------------------------------------
# CU-11: Clasificar Incidente por Imagen (GEMINI IA REAL)
# ---------------------------------------------------------

# (Middleware de CORS duplicado fue eliminado)

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
        return {"transcripcion": datos_audio.get("transcripcion", ""), "resumen": datos_audio.get("resumen", ""), "palabras_clave": datos_audio.get("palabras_clave", [])}
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

        prioridad = _clasificar_por_texto(f"{tipo_ia} {severidad_ia} {texto_apoyo}").get("prioridad", "Media")
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