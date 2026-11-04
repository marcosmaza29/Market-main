# Activación de la estructura multi-tienda

## Qué cambia en esta revisión

- Se incorpora `db/04_multitienda.sql`, migración idempotente que crea la configuración de `market`, `juguetes` y `cosmeticos` y añade `tienda_id` a administradores, productos, proveedores, compras e historiales.
- Los datos existentes se conservan asignados a `market`; no se copian automáticamente a las otras tiendas.
- Se corrige el alta de productos al carrito para exigir la tienda y comprobar que el producto pertenece a ella.
- El proceso de compra comprueba la tienda al descontar stock y la guarda en el historial.
- Se empieza a aplicar aislamiento por tienda a la gestión de proveedores y compras de proveedor.
- Los triggers de auditoría se actualizan para escribir la tienda correspondiente.

## Orden de ejecución

En la base PostgreSQL/Supabase existente, ejecutar una sola vez y en este orden:

1. `db/01_schema.sql` (solo si se trata de una base nueva).
2. `db/02_data.sql` (solo si se trata de una base nueva).
3. `db/03_triggers.sql` (solo si se trata de una base nueva).
4. `db/04_multitienda.sql` (en base existente o nueva, después de las anteriores).

Si la base ya tiene datos, **no volver a ejecutar** `01_schema.sql` ni `02_data.sql`: ejecutar únicamente `04_multitienda.sql`.

## Administradores de cada tienda

La cuenta administrativa histórica se conserva asignada a `market`. La migración no crea contraseñas predeterminadas para juguetes ni cosméticos. Crear una fila independiente en `admin` por tienda, con la contraseña almacenada en BCrypt (formato generado por `util.PasswordUtil.hashPassword`):

```sql
INSERT INTO admin (usuario, clave, tienda_id)
VALUES ('admin_juguetes', '<HASH_BCRYPT>', 'juguetes');

INSERT INTO admin (usuario, clave, tienda_id)
VALUES ('admin_cosmeticos', '<HASH_BCRYPT>', 'cosmeticos');
```

Generar cada hash con `util.PasswordUtil.hashPassword("una contraseña segura")` desde la aplicación o una utilidad Java que incluya la dependencia jbcrypt del `pom.xml`. No guardar contraseñas en texto plano.

## Importante

Esta entrega es una primera corrección de la base multi-tienda, no una certificación de aislamiento completo. Antes de ponerla en producción hay que completar y probar el filtrado por `tienda_id` en todas las pantallas de ventas, historial, auditoría y catálogo; revisar políticas de acceso y probar cada flujo con tres administradores distintos. El empaquetado debe compilarse y probarse con Maven/Tomcat y una copia de la base de datos, nunca directamente sobre producción.

## Correcciones adicionales de aislamiento (revisión siguiente)

- El filtro administrativo ahora exige una sesión válida y un `adminTiendaId` permitido (`market`, `juguetes` o `cosmeticos`); sesiones antiguas sin tienda se invalidan.
- El reporte de ventas y su exportación CSV filtran por `historial_compras.tienda_id` de la sesión administrativa.
- La actividad de productos filtra por `historial_admin.tienda_id` y solo verifica productos existentes de esa misma tienda.
- El historial de proveedores filtra proveedores, eventos y relaciones de compras por la tienda autenticada.
- Los listados y resúmenes de compras a proveedores refuerzan las uniones con `tienda_id`.

Estas correcciones reducen fugas entre paneles, pero todavía requieren pruebas funcionales en Tomcat y PostgreSQL. En este entorno no está instalado Maven, por lo que no se pudo ejecutar `mvn package`.
