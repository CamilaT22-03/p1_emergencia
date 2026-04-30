import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv

# Cargar variables de entorno desde el archivo .env
load_dotenv(override=True)

# 1. Obtenemos la URL de la base de datos
URL_BASE_DATOS = os.getenv("DATABASE_URL", "sqlite:///./emergencia_local.db")

# 2. Creamos el motor que hará viajar los datos
# Configuración especial para Supabase PostgreSQL
if URL_BASE_DATOS.startswith("postgresql"):
    engine = create_engine(
        URL_BASE_DATOS,
        connect_args={"sslmode": "require"}
    )
else:
    engine = create_engine(URL_BASE_DATOS)

# 3. Creamos la sesión (es como abrir la puerta para meter o sacar datos)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 4. Esta es la base mágica con la que crearemos nuestras tablas
Base = declarative_base()

# 5. Función para que el mesero pida la llave de la bodega y la devuelva al terminar
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()