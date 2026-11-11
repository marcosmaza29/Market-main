# Gestor de incidentes - Market

## Cambios
- Menú **Gestor de incidentes** para los administradores de las tres tiendas.
- `src/main/webapp/jsp-Admin/incidentes.jsp`: alta, asignación, cambio de estado, escalamiento, seguimiento y registro histórico por tienda.
- `db/09_incidentes.sql`: tablas `incidentes` e `incidentes_historial` en PostgreSQL/Supabase.
- `pom.xml` y `ActualizarEsquema.java`: incluyen y ejecutan la nueva migración al iniciar, si el rol PostgreSQL dispone de privilegios DDL.
- Monitoreo en la misma pantalla por `/monitor/estado` (Java). El panel de rendimiento existente continúa utilizando Prometheus/Grafana.

## Preparación
1. Mantén tu `.env` **local** con `DATABASE_URL` y `METRICS_TOKEN` (no se incluye en este ZIP).
2. En Supabase, ejecuta `db/09_incidentes.sql` desde SQL Editor si la aplicación no dispone de permiso para migrar automáticamente. **No ejecutar más de una vez por necesidad: es idempotente para creación de tablas/índices.**
3. Construye y levanta la aplicación: `docker compose --profile monitoring up -d --build`.
4. Ingresa como administrador de cualquier tienda y abre **Gestión del servicio → Gestor de incidentes**.
5. Crea un incidente, asígnalo, escala su prioridad operativa mediante el estado `escalado`, registra seguimiento, resuélvelo y ciérralo. El historial se conserva.

## Datos y SLA
- Categorías: Aplicación, Rendimiento, Base de datos, Seguridad, Red y Otros.
- Prioridades de ejemplo: P1 (respuesta 1h, solución 4h), P2 (4h, 12h), P3 (8h, 48h), P4 (24h, 120h).
- Los SLA se calculan en **horas corridas 24/7** desde el alta y se comparan contra los plazos guardados en PostgreSQL. No son acuerdos contractuales configurables ni excluyen horarios no laborables.
- Estados: registrado, asignado, en proceso, escalado, resuelto, cerrado.
- Cada registro, consulta y actualización administrativa se filtra por la tienda de la sesión.

## Alcance real de las herramientas
El módulo está implementado internamente en Java/JSP + PostgreSQL, siguiendo un flujo de gestión de incidentes tipo ITSM. **No** incluye conexión API con ServiceNow, Jira Service Management, ManageEngine ServiceDesk Plus, Freshservice, GLPI, iTop, Zabbix o Azure Monitor. Grafana/Prometheus siguen en el stack existente y el gestor enlaza al panel de rendimiento. CPU, RAM y disco son métricas del servidor compartido, no recursos exclusivos por tienda.

## Seguridad
- Se mantienen las verificaciones de sesión, tienda, parámetros y CSRF.
- El ZIP no contiene `.env`, historial `.git`, módulos `node_modules` ni artefactos `target`.
- No se ha probado el despliegue contra tu Supabase ni una ejecución completa de Docker en este entorno; verifica el comportamiento en tu instalación.
