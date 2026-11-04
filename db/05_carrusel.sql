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
