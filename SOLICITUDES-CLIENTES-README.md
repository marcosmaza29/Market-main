# Solicitudes del cliente — Market / Juguetes / Cosméticos

## Funcionalidad
- Cliente autenticado: desde el menú **Mis solicitudes** o el pie **Solicitudes y mejoras** puede enviar mejoras, sugerencias, problemas u otros, y ver exclusivamente sus solicitudes en la tienda actual.
- Administrador autenticado: apartado **Solicitudes del cliente**. Solo ve la tienda vinculada a su sesión, filtra por estado y responde/cambia estado.
- Estados: pendiente, en revisión, en proceso, resuelta y rechazada.
- Las solicitudes se guardan en PostgreSQL/Supabase, no se envían por correo.
- No se altera el módulo de **Catálogo de solicitudes** que ya existía.

## Instalación
1. Extrae el ZIP y conserva tu archivo `.env` existente, sin compartirlo.
2. Desde la carpeta del proyecto: `docker compose --profile monitoring up -d --build`.
3. En el arranque la aplicación intenta ejecutar la migración `db/08_solicitudes_clientes.sql`. Si la cuenta de conexión no tiene permisos DDL, ejecuta manualmente dicho SQL en el editor SQL de Supabase y reinicia el contenedor.
4. Abre `/jsp-Interfaz/solicitudes.jsp?tienda=market` (o `juguetes`, `cosmeticos`) con sesión de cliente.
5. Abre `/jsp-Admin/solicitudesClientes.jsp?tienda=market` con el administrador correspondiente.

## Seguridad y alcance
- Toda lectura/escritura utiliza `tienda_id` definido por la sesión/contexto y el filtro administrativo existente; los usuarios solo leen solicitudes de su correo de sesión.
- Formularios protegidos mediante token CSRF, valores escapados con `util.Html.esc` y consultas SQL preparadas.
- Los clientes deben iniciar sesión; no se aceptan solicitudes anónimas.
- La actualización usa guardado manual: no incluye avisos push ni correo automático.
