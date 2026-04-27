from fastapi import FastAPI, Depends, HTTPException
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from database import engine, get_db
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, File, UploadFile
from PIL import Image
import io
import json
import random
import models
import schemas
import google.generativeai as genai
import os
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
    allow_origins=["*"], # La dirección de tu Angular
    allow_credentials=True,
    allow_methods=["*"], # Permite POST, GET, etc.
    allow_headers=["*"],
)

# Construimos los estantes
models.Base.metadata.create_all(bind=engine)

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
# ==========================================
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

@app.get("/emergencias-taller/")
def ver_emergencias_para_taller(db: Session = Depends(get_db)):
    # El taller llamará a esta ruta desde su web para ver la lista
    return db.query(models.Emergencia).filter(models.Emergencia.estado == "Pendiente").all()
# Ruta para que el taller Acepte la emergencia
@app.patch("/emergencias/{id_emergencia}/aceptar")
def aceptar_emergencia(id_emergencia: int, db: Session = Depends(get_db)):
    emergencia = db.query(models.Emergencia).filter(models.Emergencia.id_emergencia == id_emergencia).first()
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

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Permite todas las conexiones
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

genai.configure(api_key=os.getenv("GEMINI_API_KEY")) # ¡Bueno!

@app.post("/api/emergencias/clasificar-imagen")
async def clasificar_incidente(imagen: UploadFile = File(...)):
    try:
        print(f"--- Recibiendo imagen: {imagen.filename} ---")
        image_bytes = await imagen.read()
        img = Image.open(io.BytesIO(image_bytes))
        
        # EL NOMBRE CORRECTO EN LA LIBRERÍA ACTUALIZADA
        model = genai.GenerativeModel('gemini-2.5-flash')
        
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
        """
        
        print("Enviando a Google Gemini...")
        response = model.generate_content([prompt, img])
        raw_text = response.text.strip()
        print(f"Respuesta de Gemini: {raw_text}") 
        
        cleaned_text = raw_text.replace("```json", "").replace("```", "").strip()
        datos_ia = json.loads(cleaned_text)
        
        return {"analisis_ia": datos_ia}

    except Exception as e:
        print(f"ERROR CRÍTICO: {str(e)}")
        return {"error": str(e)}