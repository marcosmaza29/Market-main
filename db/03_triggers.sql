-- Triggers de auditoría (equivalentes a los de MySQL)

CREATE OR REPLACE FUNCTION fn_after_compra_proveedor() RETURNS trigger AS $$
DECLARE
  nombre_prov VARCHAR(100);
  nombre_prod VARCHAR(100);
BEGIN
  SELECT nombre INTO nombre_prov FROM proveedores WHERE id = NEW.proveedor_id;
  SELECT nombre INTO nombre_prod FROM productos  WHERE id = NEW.producto_id;

  INSERT INTO historial_admin (usuario_admin, accion, tabla_afectada, id_afectado, detalles)
  VALUES (current_user, 'COMPRA_PROV', 'compras_proveedores', NEW.id,
          'Proveedor: ' || coalesce(nombre_prov, '') || ' | Producto: ' || coalesce(nombre_prod, '') ||
          ' | Cant: ' || NEW.cantidad || ' | Precio: S/' || NEW.precio_unitario);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_compra_proveedor
AFTER INSERT ON compras_proveedores
FOR EACH ROW EXECUTE FUNCTION fn_after_compra_proveedor();


CREATE OR REPLACE FUNCTION fn_after_producto_delete() RETURNS trigger AS $$
BEGIN
  INSERT INTO historial_admin (usuario_admin, accion, tabla_afectada, id_afectado, detalles)
  VALUES (current_user, 'ELIMINAR', 'productos', OLD.id,
          concat('Producto eliminado: ', OLD.nombre,
                 ' | Último precio: S/', OLD.precio,
                 ' | Stock final: ', OLD.stock,
                 ' | Categoría: ', OLD.categoria));
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_producto_delete
AFTER DELETE ON productos
FOR EACH ROW EXECUTE FUNCTION fn_after_producto_delete();


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
    INSERT INTO historial_admin (usuario_admin, accion, tabla_afectada, id_afectado, detalles)
    VALUES (current_user, 'EDITAR', 'productos', OLD.id, cambios);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_producto_update
AFTER UPDATE ON productos
FOR EACH ROW EXECUTE FUNCTION fn_after_producto_update();
