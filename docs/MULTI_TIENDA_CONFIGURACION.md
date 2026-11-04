# Configuración multi-tienda (Market, Juguetes y Cosméticos)

## Qué se implementó

- Las tres tiendas utilizan una sola aplicación Java/JSP y las mismas tablas relacionales; los registros operativos se separan por `tienda_id`.
- `index.jsp` dirige a `acceso_tienda.jsp`. Si la tienda ya fue personalizada, entra directamente al catálogo. Si todavía no, muestra `personalizar_inicio.jsp` antes de entrar.
- La personalización inicial permite nombre, tipografía, colores, logo y banner. Se guarda una sola vez mediante `guardar_personalizacion_inicial.jsp`.
- El administrador puede volver a cambiar el diseño desde `configurar_tienda.jsp` y `guardar_configuracion.jsp`.
- Market conserva categorías de minimarket. Juguetes y Cosméticos tienen sus propias categorías en `util.Catalogo` y se usan tanto en el catálogo público como en alta/edición de productos.

## Migración obligatoria de Supabase

Después de ejecutar los scripts originales `db/01_schema.sql`, `db/02_data.sql` y `db/03_triggers.sql`, ejecutar una sola vez `db/04_multi_tienda.sql` en el SQL Editor de Supabase. Esta migración crea `tiendas`, agrega `tienda_id` a las tablas y crea índices. Los registros existentes se asignan a `market`; Juguetes y Cosméticos comienzan con catálogo vacío y pueden cargar sus productos desde su propio panel.

La migración replica los registros de administrador de Market a las otras tiendas para que se pueda iniciar sesión con las mismas credenciales, pero cada inicio queda limitado a la tienda seleccionada. Cambiar contraseñas de cada tienda después del primer acceso es recomendable.

## Compilación local

Desde la raíz del proyecto:

```bash
npm install
npm run build:css
mvn clean package
```

El CSS compilado debe quedar en `src/main/webapp/assets/app.css`. Luego desplegar `target/Market.war` en Tomcat 9. Configurar `DATABASE_URL` para que el backend se conecte a PostgreSQL/Supabase.

## Rutas

- Selector: `/`
- Entrada y comprobación de personalización: `/jsp-Interfaz/acceso_tienda.jsp?tienda=market|juguetes|cosmeticos`
- Catálogo: `/jsp-Interfaz/interfaz.jsp?tienda=...`
- Personalización inicial: `/jsp-Interfaz/personalizar_inicio.jsp?tienda=...`
- Personalización administrativa: `/jsp-Interfaz/configurar_tienda.jsp?tienda=...` (requiere iniciar sesión como admin de esa tienda)

## Actualización del inicio, administración y publicidad

En una instalación que ya tiene la migración 04, ejecutar `db/05_carrusel.sql` en el SQL Editor de la base configurada y desplegar el nuevo WAR. En una instalación nueva, ejecutar los archivos 01 a 05 en orden. No volver a cargar 01 y 02 en una base que ya tiene datos.

La migración 05 crea el carrusel, amplía los tipos de proveedor y corrige los triggers para registrar actividad en la tienda de origen. Permite registrar el mismo RUC en tiendas distintas. No copia productos ni imágenes de Market a los otros negocios.

Desde Administración → Carrusel de publicidad se pueden subir fotos JPG, PNG o GIF (hasta 5 MB), describirlas, establecer su orden y eliminarlas. Para sustituir una foto, eliminarla y subir la nueva. Las fotos persisten como BYTEA en PostgreSQL, sin depender del disco del servidor. Los carruseles de Juguetería y Cosméticos empiezan vacíos. Market mantiene sus promociones anteriores mientras no tenga fotos propias cargadas.

El nombre de inicio, la cabecera de acceso, el título del navegador y los enlaces administrativos conservan la tienda. Se filtraron el historial de proveedores y la selección de la cuenta administrativa por tienda. Los registros de usuario creados desde el registro público se asocian a la tienda desde la que se registran. Los correos de cliente conservan la unicidad global del sistema existente.

## Validación realizada

- Compilación Maven y generación del WAR con Java 17.
- Generación de CSS con Tailwind.
- Compilación de las 35 JSP con Jasper/Tomcat 9: cero errores.
- Base PostgreSQL temporal independiente: carga de scripts 01–05.
- Para cada tienda: inicio, 11 pantallas administrativas, productos y proveedores exclusivos, carga y lectura de publicidad.
- Rechazo de lectura/eliminación de imágenes de otra tienda, token inválido y archivo falso.
- Comprobación de tienda en los eventos creados por los triggers.

Las pruebas utilizaron datos temporales; no modificaron la base remota configurada en `.env`. El despliegue y la aplicación de la migración en esa base quedan pendientes.

## Corrección v2 del reporte del cliente

El WAR incluye las migraciones 04, 05 y 06, y un listener las aplica al arrancar dentro de una transacción. La tabla `market_migraciones` evita repetirlas en cada arranque. La cuenta de conexión debe tener permiso para modificar el esquema. Si no dispone de ese permiso, ejecutar los scripts 04, 05 y 06 con el propietario de la base; no ejecutar nuevamente 01 ni 02 sobre datos existentes. Los scripts de actualización son repetibles. Revisar el log de Tomcat si una migración falla: no se marca como aplicada y la transacción se revierte.

El historial del cliente ahora asigna el segundo parámetro SQL (`tienda_id`). La migración 04 vuelve a comprobar columnas de configuración que pueden faltar, incluido `actualizado_en`. El guardado de configuración muestra un mensaje recuperable si hay un fallo SQL, en lugar de una pantalla 500.

Los formularios de producto permiten seleccionar una foto del equipo (JPG, PNG o GIF, 5 MB) y subirla antes de guardar. Se conserva el enlace existente si no se sube una foto nueva. Las fotos se guardan en PostgreSQL, separadas por tienda, mediante un endpoint protegido por sesión y token. El archivo subido queda almacenado aunque se cancele posteriormente el formulario del producto. Los productos existentes conservan sus imágenes del bucket.

Juguetería tiene categorías adicionales de Muñecos, Carros, Figuras de acción, Rompecabezas y Juguetes al aire libre. Los ejemplos de nombre se adaptan a cada negocio.

Validación v2: compilación Java y 35 JSP; comprobación de sintaxis de JavaScript; actualización automática de una base temporal con tabla del carrusel y columna de configuración ausentes; POST de personalización, subida al carrusel, subida/alta/edición de producto con foto y consulta del historial del cliente en las tres tiendas. Se verificaron rechazos por token inválido, archivo falso y lectura desde otra tienda. No se modificó la base remota del cliente.

## Actualización v3: gestión administrativa en las tres tiendas

El panel compartido incorpora los siguientes módulos. Cada consulta y modificación usa la tienda autenticada en sesión; cambiar el ID o la tienda en el formulario no concede acceso a datos ajenos.

- Catálogo de solicitudes: nombre, tipo, responsable, tiempo objetivo de atención en horas, flujo de aprobación y evidencia de cierre. Conserva las solicitudes anteriores. La evidencia permite una descripción o enlace, y puede completarse al cerrar la solicitud.
- Gestión de cambios: nombre, tipo de cambio, responsable, riesgo, implementación, plan de reversión y evidencias esperadas.
- Pipeline de CI: nombre, repositorio, eventos que lo disparan, pruebas automáticas y herramientas utilizadas. Es un registro de la definición del pipeline; no ejecuta comandos, despliegues o conexiones al repositorio.
- Plan de capacidad: nombre, número de usuarios, recursos de infraestructura, métricas de monitoreo, riesgo de saturación, estrategia de escalabilidad y herramientas de monitoreo. Documenta el plan; las métricas no son mediciones en tiempo real.

Cada módulo permite crear, editar, buscar y eliminar registros, con confirmación de borrado, validación de servidor, escape HTML y protección por token de sesión. La evidencia de cierre es opcional mientras esté pendiente; los demás campos del registro son obligatorios. No se inventan registros operativos ni se comparten datos entre tiendas.

La migración `db/07_gestion_administrativa.sql` añade la columna de cierre y las tres tablas nuevas. El WAR la incluye en la actualización automática. Si se aplica SQL manualmente, usar `entrega/ACTUALIZAR_BASE_MARKET_V3.sql` (reúne las migraciones 04–07, sin cargar datos iniciales). La cuenta que lo ejecute debe tener permiso de modificación del esquema.

Validación v3: compilación Java y 38 páginas JSP; operaciones de creación/lectura/edición/búsqueda/eliminación de los cuatro módulos para cada tienda; preservación de solicitudes existentes; textos con acentos; límites numéricos; rechazo de token inválido y accesos sin sesión; escape de etiquetas HTML; bloqueo de lectura/actualización/eliminación con IDs de otra tienda; repetición de la migración sin errores. Pruebas efectuadas con PostgreSQL temporal, sin cambios en la base remota.
