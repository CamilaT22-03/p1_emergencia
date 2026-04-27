-- Esquema limpio para ejecutar en el SQL Editor de Supabase
-- Tablas sin los comandos COPY de pg_dump

CREATE TABLE public.clientes (
    id SERIAL PRIMARY KEY,
    nombre_completo VARCHAR,
    telefono VARCHAR UNIQUE,
    email VARCHAR UNIQUE,
    contrasena VARCHAR
);

CREATE TABLE public.talleres (
    id SERIAL PRIMARY KEY,
    nombre_taller VARCHAR,
    direccion VARCHAR,
    telefono VARCHAR,
    email VARCHAR UNIQUE,
    contrasena VARCHAR,
    latitud DOUBLE PRECISION,
    longitud DOUBLE PRECISION
);

CREATE TABLE public.vehiculos (
    id SERIAL PRIMARY KEY,
    placa VARCHAR UNIQUE,
    marca VARCHAR,
    modelo VARCHAR,
    color VARCHAR,
    cliente_id INTEGER REFERENCES public.clientes(id)
);

CREATE TABLE public.tecnicos (
    id SERIAL PRIMARY KEY,
    nombre_completo VARCHAR,
    especialidad VARCHAR,
    usuario VARCHAR UNIQUE,
    contrasena VARCHAR,
    disponible BOOLEAN,
    motivo_no_disponible VARCHAR,
    taller_id INTEGER REFERENCES public.talleres(id)
);

CREATE TABLE public.emergencias (
    id SERIAL PRIMARY KEY,
    direccion VARCHAR,
    descripcion VARCHAR,
    latitud DOUBLE PRECISION,
    longitud DOUBLE PRECISION,
    tipo_ia VARCHAR(100),
    severidad_ia VARCHAR(50),
    estado VARCHAR,
    audio_url VARCHAR,
    transcripcion TEXT,
    foto_url VARCHAR,
    tecnico_id INTEGER REFERENCES public.tecnicos(id),
    observaciones TEXT,
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE,
    fecha_actualizacion TIMESTAMP WITHOUT TIME ZONE,
    cliente_id INTEGER REFERENCES public.clientes(id),
    vehiculo_id INTEGER REFERENCES public.vehiculos(id),
    taller_id INTEGER REFERENCES public.talleres(id),
    precio_total DOUBLE PRECISION,
    latitud_tecnico DOUBLE PRECISION,
    longitud_tecnico DOUBLE PRECISION
);

CREATE TABLE public.aceptaciones_taller (
    id SERIAL PRIMARY KEY,
    emergencia_id INTEGER REFERENCES public.emergencias(id),
    taller_id INTEGER REFERENCES public.talleres(id),
    tiempo_estimado_minutos INTEGER,
    mensaje VARCHAR,
    estado VARCHAR,
    fecha TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE public.historial_estados (
    id SERIAL PRIMARY KEY,
    emergencia_id INTEGER REFERENCES public.emergencias(id),
    estado_anterior VARCHAR,
    estado_nuevo VARCHAR,
    descripcion VARCHAR,
    fecha_cambio TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE public.pagos (
    id SERIAL PRIMARY KEY,
    emergencia_id INTEGER REFERENCES public.emergencias(id),
    cliente_id INTEGER REFERENCES public.clientes(id),
    taller_id INTEGER REFERENCES public.talleres(id),
    monto DOUBLE PRECISION,
    metodo_pago VARCHAR,
    estado_pago VARCHAR,
    referencia VARCHAR,
    fecha_pago TIMESTAMP WITHOUT TIME ZONE,
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE public.tokens_notificacion (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES public.clientes(id),
    taller_id INTEGER REFERENCES public.talleres(id),
    token_fcm VARCHAR,
    plataforma VARCHAR,
    activo BOOLEAN,
    fecha TIMESTAMP WITHOUT TIME ZONE
);
