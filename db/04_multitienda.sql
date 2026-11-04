-- Migración multi-tienda para PostgreSQL/Supabase.
-- Ejecutar DESPUÉS de 01_schema.sql, 02_data.sql y 03_triggers.sql.
BEGIN;

CREATE TABLE IF NOT EXISTS tiendas (
  id VARCHAR(20) PRIMARY KEY CHECK (id IN ('market','juguetes','cosmeticos')),
  nombre VARCHAR(120) NOT NULL,
  tipo_fuente VARCHAR(80) NOT NULL DEFAULT 'Inter',
  color_primario VARCHAR(7) NOT NULL DEFAULT '#2563EB',
  color_secundario VARCHAR(7) NOT NULL DEFAULT '#1D4ED8',
  color_fondo VARCHAR(7) NOT NULL DEFAULT '#EFF6FF',
  logo_url TEXT,
  banner_url TEXT,
  activa BOOLEAN NOT NULL DEFAULT TRUE
);
INSERT INTO tiendas (id,nombre,color_primario,color_secundario,color_fondo) VALUES
 ('market','Market','#2563EB','#1D4ED8','#EFF6FF'),
 ('juguetes','Juguetería','#7C3AED','#6D28D9','#F5F3FF'),
 ('cosmeticos','Cosméticos','#DB2777','#BE185D','#FDF2F8')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE admin ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(20);
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS rol VARCHAR(30) NOT NULL DEFAULT 'cliente';
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(20);
ALTER TABLE productos ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(20);
ALTER TABLE proveedores ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(20);
ALTER TABLE compras_proveedores ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(20);
ALTER TABLE historial_admin ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(20);
ALTER TABLE historial_compras ADD COLUMN IF NOT EXISTS tienda_id VARCHAR(20);

-- Los registros históricos pertenecen a Market. No se duplican ni se exponen a las otras tiendas.
UPDATE admin SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE usuarios SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE productos SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE proveedores SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE compras_proveedores SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE historial_admin SET tienda_id='market' WHERE tienda_id IS NULL;
UPDATE historial_compras SET tienda_id='market' WHERE tienda_id IS NULL;

ALTER TABLE admin ALTER COLUMN tienda_id SET NOT NULL;
ALTER TABLE productos ALTER COLUMN tienda_id SET NOT NULL;
ALTER TABLE proveedores ALTER COLUMN tienda_id SET NOT NULL;
ALTER TABLE compras_proveedores ALTER COLUMN tienda_id SET NOT NULL;
ALTER TABLE historial_admin ALTER COLUMN tienda_id SET NOT NULL;
ALTER TABLE historial_compras ALTER COLUMN tienda_id SET NOT NULL;

DO $$ BEGIN
  ALTER TABLE admin ADD CONSTRAINT fk_admin_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE usuarios ADD CONSTRAINT fk_usuarios_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE productos ADD CONSTRAINT fk_productos_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE proveedores ADD CONSTRAINT fk_proveedores_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE compras_proveedores ADD CONSTRAINT fk_compras_proveedores_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE historial_admin ADD CONSTRAINT fk_historial_admin_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE historial_compras ADD CONSTRAINT fk_historial_compras_tienda FOREIGN KEY (tienda_id) REFERENCES tiendas(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS idx_productos_tienda ON productos(tienda_id);
CREATE INDEX IF NOT EXISTS idx_proveedores_tienda ON proveedores(tienda_id);
CREATE INDEX IF NOT EXISTS idx_compras_proveedores_tienda ON compras_proveedores(tienda_id);
CREATE INDEX IF NOT EXISTS idx_historial_admin_tienda ON historial_admin(tienda_id);
CREATE INDEX IF NOT EXISTS idx_historial_compras_tienda ON historial_compras(tienda_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_admin_usuario_tienda ON admin(LOWER(usuario),tienda_id);

-- Solicitudes del catálogo usadas por el panel administrativo.
CREATE TABLE IF NOT EXISTS catalogo_solicitudes (
 id BIGSERIAL PRIMARY KEY,
 tienda_id VARCHAR(20) NOT NULL REFERENCES tiendas(id),
 nombre VARCHAR(160) NOT NULL,
 tipo VARCHAR(40) NOT NULL,
 responsable VARCHAR(120),
 descripcion TEXT,
 estado VARCHAR(30) NOT NULL DEFAULT 'pendiente',
 fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_catalogo_solicitudes_tienda ON catalogo_solicitudes(tienda_id,fecha DESC);

-- Cada administrador debe tener una fila propia asociada a su tienda.
-- La cuenta histórica de Market queda asignada a Market; las otras dos se crean
-- desde el panel/DB con contraseñas BCrypt propias antes de habilitar esos accesos.
-- Los triggers propagan la tienda al historial para que la auditoría siga funcionando.
CREATE OR REPLACE FUNCTION fn_after_compra_proveedor() RETURNS trigger AS $$
DECLARE nombre_prov VARCHAR(100); nombre_prod VARCHAR(100);
BEGIN
 SELECT nombre INTO nombre_prov FROM proveedores WHERE id=NEW.proveedor_id AND tienda_id=NEW.tienda_id;
 SELECT nombre INTO nombre_prod FROM productos WHERE id=NEW.producto_id AND tienda_id=NEW.tienda_id;
 INSERT INTO historial_admin (usuario_admin,accion,tabla_afectada,id_afectado,detalles,tienda_id)
 VALUES (current_user,'COMPRA_PROV','compras_proveedores',NEW.id,
 'Proveedor: '||coalesce(nombre_prov,'')||' | Producto: '||coalesce(nombre_prod,'')||' | Cant: '||NEW.cantidad||' | Precio: S/'||NEW.precio_unitario,NEW.tienda_id);
 RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_after_producto_delete() RETURNS trigger AS $$
BEGIN
 INSERT INTO historial_admin (usuario_admin,accion,tabla_afectada,id_afectado,detalles,tienda_id)
 VALUES (current_user,'ELIMINAR','productos',OLD.id,concat('Producto eliminado: ',OLD.nombre,' | Último precio: S/',OLD.precio,' | Stock final: ',OLD.stock,' | Categoría: ',OLD.categoria),OLD.tienda_id);
 RETURN OLD;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_after_producto_update() RETURNS trigger AS $$
DECLARE cambios TEXT;
BEGIN
 cambios := concat(
 CASE WHEN NEW.nombre IS DISTINCT FROM OLD.nombre THEN concat('Nombre: ',OLD.nombre,' → ',NEW.nombre,' | ') ELSE '' END,
 CASE WHEN NEW.descripcion IS DISTINCT FROM OLD.descripcion THEN 'Descripción: modificada | ' ELSE '' END,
 CASE WHEN NEW.precio IS DISTINCT FROM OLD.precio THEN concat('Precio: S/',OLD.precio,' → S/',NEW.precio,' | ') ELSE '' END,
 CASE WHEN NEW.stock IS DISTINCT FROM OLD.stock THEN concat('Stock: ',OLD.stock,' → ',NEW.stock,' | ') ELSE '' END,
 CASE WHEN NEW.unidad IS DISTINCT FROM OLD.unidad THEN concat('Unidad: ',OLD.unidad,' → ',NEW.unidad,' | ') ELSE '' END,
 CASE WHEN NEW.imagen_url IS DISTINCT FROM OLD.imagen_url THEN 'Imagen: Cambiada | ' ELSE '' END,
 CASE WHEN NEW.categoria IS DISTINCT FROM OLD.categoria THEN concat('Categoría: ',OLD.categoria,' → ',NEW.categoria,' | ') ELSE '' END);
 IF cambios <> '' THEN
  INSERT INTO historial_admin (usuario_admin,accion,tabla_afectada,id_afectado,detalles,tienda_id)
  VALUES (current_user,'EDITAR','productos',OLD.id,cambios,OLD.tienda_id);
 END IF;
 RETURN NEW;
END; $$ LANGUAGE plpgsql;

COMMIT;
