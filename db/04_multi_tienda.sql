-- Migración multi-tienda para PostgreSQL / Supabase.
-- Ejecutar DESPUÉS de 01_schema.sql, 02_data.sql y 03_triggers.sql.
-- Las tres tiendas comparten las mismas tablas, pero cada registro queda aislado por tienda_id.

CREATE TABLE IF NOT EXISTS tiendas (
    id VARCHAR(30) PRIMARY KEY CHECK (id IN ('market','juguetes','cosmeticos')),
    nombre VARCHAR(100) NOT NULL,
    tipo_fuente VARCHAR(80) NOT NULL DEFAULT 'Inter',
    color_primario VARCHAR(7) NOT NULL DEFAULT '#2563EB',
    color_secundario VARCHAR(7) NOT NULL DEFAULT '#1D4ED8',
    color_fondo VARCHAR(7) NOT NULL DEFAULT '#FFFFFF',
    logo_url TEXT,
    banner_url TEXT,
    personalizacion_completa BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE tiendas ADD COLUMN IF NOT EXISTS nombre VARCHAR(100) NOT NULL DEFAULT 'Tienda';
ALTER TABLE tiendas ADD COLUMN IF NOT EXISTS tipo_fuente VARCHAR(80) NOT NULL DEFAULT 'Inter';
ALTER TABLE tiendas ADD COLUMN IF NOT EXISTS color_primario VARCHAR(7) NOT NULL DEFAULT '#2563EB';
ALTER TABLE tiendas ADD COLUMN IF NOT EXISTS color_secundario VARCHAR(7) NOT NULL DEFAULT '#1D4ED8';
ALTER TABLE tiendas ADD COLUMN IF NOT EXISTS color_fondo VARCHAR(7) NOT NULL DEFAULT '#FFFFFF';
ALTER TABLE tiendas ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE tiendas ADD COLUMN IF NOT EXISTS banner_url TEXT;
ALTER TABLE tiendas ADD COLUMN IF NOT EXISTS personalizacion_completa BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE tiendas ADD COLUMN IF NOT EXISTS creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE tiendas ADD COLUMN IF NOT EXISTS actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

INSERT INTO tiendas (id,nombre,tipo_fuente,color_primario,color_secundario,color_fondo,personalizacion_completa)
VALUES
 ('market','Minimarket Anais','Inter','#15803D','#166534','#FFFFFF',TRUE),
 ('juguetes','Juguetería','Inter','#EA580C','#C2410C','#FFFFFF',FALSE),
 ('cosmeticos','Belleza y Cosméticos','Inter','#A21CAF','#86198F','#FFFFFF',FALSE)
ON CONFLICT (id) DO NOTHING;

-- Market ya dispone de una tienda operativa: no debe volver a mostrar el asistente inicial.
UPDATE tiendas SET personalizacion_completa=TRUE WHERE id='market';

-- Aislamiento de administradores y datos operativos.
-- Primero se crean las columnas tienda_id y después se normalizan los datos heredados.
ALTER TABLE admin ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(30) NOT NULL DEFAULT 'market';
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS rol VARCHAR(30) NOT NULL DEFAULT 'cliente';
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(30) NOT NULL DEFAULT 'market';
ALTER TABLE productos ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(30) NOT NULL DEFAULT 'market';
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(30) NOT NULL DEFAULT 'market';
ALTER TABLE compras_proveedores ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(30) NOT NULL DEFAULT 'market';
ALTER TABLE historial_admin ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(30) NOT NULL DEFAULT 'market';
ALTER TABLE historial_compras ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(30) NOT NULL DEFAULT 'market';

-- Normalizar datos heredados: todo lo que existía antes pertenece a Market.
UPDATE admin SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE usuarios SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE productos SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE proveedores SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE compras_proveedores SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE historial_admin SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE historial_compras SET tienda_id='market' WHERE tienda_id IS NULL;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_admin_tienda') THEN
    ALTER TABLE admin ADD CONSTRAINT fk_admin_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_usuarios_tienda') THEN
    ALTER TABLE usuarios ADD CONSTRAINT fk_usuarios_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_productos_tienda') THEN
    ALTER TABLE productos ADD CONSTRAINT fk_productos_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_proveedores_tienda') THEN
    ALTER TABLE proveedores ADD CONSTRAINT fk_proveedores_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_compras_tienda') THEN
    ALTER TABLE compras_proveedores ADD CONSTRAINT fk_compras_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_historial_admin_tienda') THEN
    ALTER TABLE historial_admin ADD CONSTRAINT fk_historial_admin_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='fk_historial_compras_tienda') THEN
    ALTER TABLE historial_compras ADD CONSTRAINT fk_historial_compras_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_usuarios_tienda_correo ON usuarios(tienda_id,LOWER(correo));
CREATE INDEX IF NOT EXISTS idx_productos_tienda_categoria ON productos(tienda_id,categoria);
CREATE INDEX IF NOT EXISTS idx_productos_tienda_nombre ON productos(tienda_id,nombre);
CREATE INDEX IF NOT EXISTS idx_admin_tienda_usuario ON admin(tienda_id,usuario);
CREATE INDEX IF NOT EXISTS idx_proveedores_tienda ON proveedores(tienda_id);
CREATE INDEX IF NOT EXISTS idx_compras_tienda ON compras_proveedores(tienda_id);
CREATE INDEX IF NOT EXISTS idx_historial_admin_tienda_fecha ON historial_admin(tienda_id,fecha DESC);
CREATE INDEX IF NOT EXISTS idx_historial_compras_tienda_fecha ON historial_compras(tienda_id,fecha DESC);

-- El administrador que ya existía en Market recibe acceso equivalente en las otras tiendas.
-- Se copian sus credenciales almacenadas, no se crea una contraseña nueva.
INSERT INTO admin (usuario,clave,tienda_id)
SELECT a.usuario,a.clave,t.id
FROM admin a
CROSS JOIN (VALUES ('juguetes'),('cosmeticos')) AS t(id)
WHERE a.tienda_id='market'
  AND NOT EXISTS (SELECT 1 FROM admin x WHERE x.usuario=a.usuario AND x.tienda_id=t.id);

-- Tabla utilizada por el módulo de solicitudes del panel, con aislamiento por tienda.
CREATE TABLE IF NOT EXISTS catalogo_solicitudes (
    id BIGSERIAL PRIMARY KEY,
    tienda_id VARCHAR(30) NOT NULL REFERENCES tiendas(id),
    nombre VARCHAR(150) NOT NULL,
    tipo VARCHAR(80),
    responsable VARCHAR(120),
    tiempo_objetivo_horas INTEGER NOT NULL DEFAULT 24 CHECK (tiempo_objetivo_horas BETWEEN 1 AND 8760),
    flujo_aprobacion TEXT,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_catalogo_solicitudes_tienda ON catalogo_solicitudes(tienda_id,fecha_actualizacion DESC);

-- Política de acceso: el backend usa credenciales de servidor; no exponer tablas a anon/authenticated.
ALTER TABLE tiendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalogo_solicitudes ENABLE ROW LEVEL SECURITY;
