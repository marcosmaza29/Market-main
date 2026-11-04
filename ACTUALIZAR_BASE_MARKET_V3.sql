-- ACTUALIZACION COMPLETA MARKET V3 - PostgreSQL / Supabase
-- Para una instalación existente. Ejecutar TODO con el propietario del esquema.
-- Conserva los datos operativos y aplica las migraciones 04 a 07.
-- No usar 01_schema.sql ni 02_data.sql sobre datos existentes.
-- Replica accesos administrativos de Market a otras tiendas solo si no existen.
BEGIN;
SELECT pg_advisory_xact_lock(731932852);
DO $$ BEGIN
 IF to_regclass('productos') IS NULL OR to_regclass('admin') IS NULL THEN
  RAISE EXCEPTION 'Selecciona la base del proyecto: no se encontraron las tablas originales.';
 END IF;
END $$;

-- 04_multi_tienda.sql
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


-- 05_carrusel.sql
-- Ejecutar después de 04_multi_tienda.sql. Las fotos persisten en PostgreSQL.
CREATE TABLE IF NOT EXISTS carrusel_publicidad (
 id BIGSERIAL PRIMARY KEY,
 tienda_id VARCHAR(30) NOT NULL REFERENCES tiendas(id),
 texto_alternativo VARCHAR(160) NOT NULL,
 orden INTEGER NOT NULL DEFAULT 0,
 tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('image/jpeg','image/png','image/gif')),
 imagen BYTEA NOT NULL CHECK (octet_length(imagen) <= 5242880),
 creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_carrusel_tienda ON carrusel_publicidad(tienda_id, orden, id);
ALTER TABLE carrusel_publicidad ENABLE ROW LEVEL SECURITY;

-- Permitir proveedores propios de juguetería y cosméticos.
ALTER TABLE proveedores DROP CONSTRAINT IF EXISTS proveedores_tipo_check;
ALTER TABLE proveedores ADD CONSTRAINT proveedores_tipo_check CHECK
 (tipo IN ('Bebidas','Abarrotes','Limpieza','Frutas/Verduras','Licores','Otros',
 'Juguetes','Educativos','Bebés','Maquillaje','Cuidado personal','Perfumes','Accesorios'));

-- Mantener la tienda en los eventos generados por triggers.
-- Triggers de auditoría (equivalentes a los de MySQL)

CREATE OR REPLACE FUNCTION fn_after_compra_proveedor() RETURNS trigger AS $$
DECLARE
  nombre_prov VARCHAR(100);
  nombre_prod VARCHAR(100);
BEGIN
  SELECT nombre INTO nombre_prov FROM proveedores WHERE id = NEW.proveedor_id;
  SELECT nombre INTO nombre_prod FROM productos  WHERE id = NEW.producto_id;

  INSERT INTO historial_admin (usuario_admin, accion, tabla_afectada, id_afectado, detalles, tienda_id)
  VALUES (current_user, 'COMPRA_PROV', 'compras_proveedores', NEW.id,
          'Proveedor: ' || coalesce(nombre_prov, '') || ' | Producto: ' || coalesce(nombre_prod, '') ||
          ' | Cant: ' || NEW.cantidad || ' | Precio: S/' || NEW.precio_unitario, NEW.tienda_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION fn_after_producto_delete() RETURNS trigger AS $$
BEGIN
  INSERT INTO historial_admin (usuario_admin, accion, tabla_afectada, id_afectado, detalles, tienda_id)
  VALUES (current_user, 'ELIMINAR', 'productos', OLD.id,
          concat('Producto eliminado: ', OLD.nombre,
                 ' | Último precio: S/', OLD.precio,
                 ' | Stock final: ', OLD.stock,
                 ' | Categoría: ', OLD.categoria), OLD.tienda_id);
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION fn_after_producto_update() RETURNS trigger AS $$
DECLARE
  cambios TEXT;
BEGIN
  -- Igual que en MySQL: si alguno de los valores es NULL, la comparación no registra cambio.
  cambios := concat(
    CASE WHEN NEW.nombre      <> OLD.nombre      THEN concat('Nombre: ', OLD.nombre, ' → ', NEW.nombre, ' | ') ELSE '' END,
    CASE WHEN NEW.descripcion <> OLD.descripcion THEN concat('Descripción: ', left(OLD.descripcion, 20), '... → ', left(NEW.descripcion, 20), '... | ') ELSE '' END,
    CASE WHEN NEW.precio      <> OLD.precio      THEN concat('Precio: S/', OLD.precio, ' → S/', NEW.precio, ' | ') ELSE '' END,
    CASE WHEN NEW.stock       <> OLD.stock       THEN concat('Stock: ', OLD.stock, ' → ', NEW.stock, ' | ') ELSE '' END,
    CASE WHEN NEW.unidad      <> OLD.unidad      THEN concat('Unidad: ', OLD.unidad, ' → ', NEW.unidad, ' | ') ELSE '' END,
    CASE WHEN NEW.imagen_url  <> OLD.imagen_url  THEN 'Imagen: Cambiada | ' ELSE '' END,
    CASE WHEN NEW.categoria   <> OLD.categoria   THEN concat('Categoría: ', OLD.categoria, ' → ', NEW.categoria, ' | ') ELSE '' END
  );

  IF cambios <> '' THEN
    INSERT INTO historial_admin (usuario_admin, accion, tabla_afectada, id_afectado, detalles, tienda_id)
    VALUES (current_user, 'EDITAR', 'productos', OLD.id, cambios, OLD.tienda_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- Un mismo proveedor puede registrarse independientemente en varias tiendas.
ALTER TABLE proveedores DROP CONSTRAINT IF EXISTS proveedores_ruc_key;
ALTER TABLE proveedores DROP CONSTRAINT IF EXISTS proveedores_tienda_ruc_key;
ALTER TABLE proveedores ADD CONSTRAINT proveedores_tienda_ruc_key UNIQUE (tienda_id, ruc);


-- 06_imagenes_producto.sql
CREATE TABLE IF NOT EXISTS imagenes_producto (
 id UUID PRIMARY KEY,
 tienda_id VARCHAR(30) NOT NULL REFERENCES tiendas(id),
 tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('image/jpeg','image/png','image/gif')),
 imagen BYTEA NOT NULL CHECK (octet_length(imagen) <= 5242880)
);
ALTER TABLE imagenes_producto ENABLE ROW LEVEL SECURITY;


-- 07_gestion_administrativa.sql
-- Extensiones del panel para Market, Juguetería y Cosméticos.
-- Requiere las migraciones 04–06; no elimina registros existentes.
ALTER TABLE catalogo_solicitudes ADD COLUMN IF NOT EXISTS evidencia_cierre TEXT NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS gestion_cambios (
 id BIGSERIAL PRIMARY KEY,
 tienda_id VARCHAR(30) NOT NULL REFERENCES tiendas(id),
 nombre VARCHAR(150) NOT NULL,
 tipo_cambio VARCHAR(100) NOT NULL,
 responsable VARCHAR(120) NOT NULL,
 riesgo TEXT NOT NULL,
 implementacion TEXT NOT NULL,
 plan_reversion TEXT NOT NULL,
 evidencias_esperadas TEXT NOT NULL,
 fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS pipelines_ci (
 id BIGSERIAL PRIMARY KEY,
 tienda_id VARCHAR(30) NOT NULL REFERENCES tiendas(id),
 nombre VARCHAR(150) NOT NULL,
 repositorio VARCHAR(1000) NOT NULL,
 eventos_disparadores TEXT NOT NULL,
 pruebas_automaticas TEXT NOT NULL,
 herramientas_utilizadas TEXT NOT NULL,
 fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS planes_capacidad (
 id BIGSERIAL PRIMARY KEY,
 tienda_id VARCHAR(30) NOT NULL REFERENCES tiendas(id),
 nombre VARCHAR(150) NOT NULL,
 numero_usuarios INTEGER NOT NULL CHECK (numero_usuarios >= 0),
 recursos_infraestructura TEXT NOT NULL,
 metricas_monitoreo TEXT NOT NULL,
 riesgo_saturacion TEXT NOT NULL,
 estrategia_escalabilidad TEXT NOT NULL,
 herramientas_monitoreo TEXT NOT NULL,
 fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_cambios_tienda_fecha ON gestion_cambios(tienda_id,fecha_actualizacion DESC);
CREATE INDEX IF NOT EXISTS idx_pipelines_tienda_fecha ON pipelines_ci(tienda_id,fecha_actualizacion DESC);
CREATE INDEX IF NOT EXISTS idx_capacidad_tienda_fecha ON planes_capacidad(tienda_id,fecha_actualizacion DESC);
ALTER TABLE gestion_cambios ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipelines_ci ENABLE ROW LEVEL SECURITY;
ALTER TABLE planes_capacidad ENABLE ROW LEVEL SECURITY;


CREATE TABLE IF NOT EXISTS market_migraciones (nombre VARCHAR(100) PRIMARY KEY, aplicado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO market_migraciones(nombre) VALUES
 ('04_multi_tienda.sql'),
 ('05_carrusel.sql'),
 ('06_imagenes_producto.sql'),
 ('07_gestion_administrativa.sql')
ON CONFLICT(nombre) DO NOTHING;
COMMIT;
SELECT nombre,aplicado_en FROM market_migraciones ORDER BY nombre;
