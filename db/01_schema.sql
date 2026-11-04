-- Esquema PostgreSQL (Supabase) migrado desde MySQL/MariaDB `bd_registro`

CREATE TABLE admin (
  id      SERIAL PRIMARY KEY,
  usuario VARCHAR(100) NOT NULL,
  clave   VARCHAR(100) NOT NULL
);

CREATE TABLE usuarios (
  id         SERIAL PRIMARY KEY,
  nombre     VARCHAR(100) NOT NULL,
  apellidos  VARCHAR(100) NOT NULL,
  correo     VARCHAR(100) NOT NULL UNIQUE,
  contrasena VARCHAR(255) NOT NULL
);

CREATE TABLE productos (
  id          SERIAL PRIMARY KEY,
  nombre      VARCHAR(100) NOT NULL,
  descripcion TEXT,
  precio      NUMERIC(10,2) NOT NULL,
  stock       INTEGER NOT NULL,
  unidad      VARCHAR(50),
  imagen_url  VARCHAR(255),
  categoria   VARCHAR(100)
);

CREATE TABLE proveedores (
  id             SERIAL PRIMARY KEY,
  nombre         VARCHAR(100) NOT NULL,
  ruc            VARCHAR(11) NOT NULL UNIQUE,
  contacto       VARCHAR(100),
  telefono       VARCHAR(20),
  direccion      TEXT,
  tipo           VARCHAR(20) NOT NULL
                 CHECK (tipo IN ('Bebidas','Abarrotes','Limpieza','Frutas/Verduras','Licores','Otros')),
  evaluacion     SMALLINT DEFAULT 5,
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activo         BOOLEAN DEFAULT TRUE
);
COMMENT ON COLUMN proveedores.evaluacion IS '1-5 estrellas';

CREATE TABLE compras_proveedores (
  id              SERIAL PRIMARY KEY,
  proveedor_id    INTEGER NOT NULL REFERENCES proveedores(id) ON UPDATE CASCADE,
  producto_id     INTEGER NOT NULL REFERENCES productos(id) ON UPDATE CASCADE,
  cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
  precio_unitario NUMERIC(10,2) NOT NULL,
  fecha_registro  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado          VARCHAR(10) DEFAULT 'pendiente'
                  CHECK (estado IN ('pendiente','recibido','cancelado'))
);
CREATE INDEX idx_compras_proveedor ON compras_proveedores(proveedor_id);
CREATE INDEX idx_compras_producto  ON compras_proveedores(producto_id);

CREATE TABLE historial_admin (
  id             SERIAL PRIMARY KEY,
  usuario_admin  VARCHAR(100) NOT NULL,
  accion         VARCHAR(20) NOT NULL,
  tabla_afectada VARCHAR(50) NOT NULL,
  id_afectado    INTEGER,
  detalles       TEXT,
  fecha          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  admin_id       INTEGER REFERENCES admin(id) ON UPDATE CASCADE
);
CREATE INDEX idx_historial_admin_admin ON historial_admin(admin_id);

CREATE TABLE historial_compras (
  id             SERIAL PRIMARY KEY,
  correo_usuario VARCHAR(100) NOT NULL,
  producto       VARCHAR(200) NOT NULL,
  precio         NUMERIC(10,2) NOT NULL,
  cantidad       INTEGER NOT NULL,
  unidad         VARCHAR(50) NOT NULL,
  subtotal       NUMERIC(10,2) NOT NULL,
  fecha          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  usuario_id     INTEGER REFERENCES usuarios(id) ON UPDATE CASCADE,
  producto_id    INTEGER REFERENCES productos(id) ON UPDATE CASCADE
);
CREATE INDEX idx_historial_compras_correo   ON historial_compras(correo_usuario);
CREATE INDEX idx_historial_compras_usuario  ON historial_compras(usuario_id);
CREATE INDEX idx_historial_compras_producto ON historial_compras(producto_id);

-- Las tablas solo se acceden desde el backend Java (rol postgres).
-- RLS activado sin políticas = bloqueadas para la API pública de Supabase (anon/authenticated).
ALTER TABLE admin               ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios            ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos           ENABLE ROW LEVEL SECURITY;
ALTER TABLE proveedores         ENABLE ROW LEVEL SECURITY;
ALTER TABLE compras_proveedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_admin     ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_compras   ENABLE ROW LEVEL SECURITY;
