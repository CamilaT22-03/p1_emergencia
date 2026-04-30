from database import SessionLocal, engine
from models import Base, Taller

# Crear las tablas si no existen
Base.metadata.create_all(bind=engine)

db = SessionLocal()

# Verificar si ya existe un taller
taller_existente = db.query(Taller).first()

if not taller_existente:
    # Crear taller de prueba
    nuevo_taller = Taller(
        nombre_taller="Taller Prueba",
        direccion="Av. Siempre Viva 123",
        telefono="123456789",
        email="taller@test.com",
        contrasena="12345"
    )
    
    db.add(nuevo_taller)
    db.commit()
    print("✅ Taller de prueba creado:")
    print("   Email: taller@test.com")
    print("   Contraseña: 12345")
else:
    print("ℹ️ Ya existe un taller en la base de datos:")
    print(f"   Email: {taller_existente.email}")

db.close()
