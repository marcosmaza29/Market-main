# Gestor de rendimiento Market

## Qué cambió
- `jsp-Admin/planCapacidad.jsp`: ya no permite inventar resultados ni exige registros manuales. Consume métricas automáticamente cada 5 segundos.
- `/monitor/estado?tienda=market|juguetes|cosmeticos`: JSON protegido por la sesión de administrador de la tienda correspondiente.
- Filtro `MonitorFilter`: instrumenta solicitudes HTTP de la aplicación y registra número de respuestas, errores HTTP 5xx y duración por tienda. No cuenta recursos estáticos ni las solicitudes del monitor. Un acceso sin tienda explícita y sin sesión de tienda se atribuye a `market`.
- RAM = heap Java (no RAM total del sistema); CPU = carga del proceso Java; disco = volumen/sistema de archivos donde vive Tomcat. Son recursos **compartidos**, nunca hardware exclusivo por tienda. El disco de Supabase no está incluido.
- Las estadísticas del panel son en memoria y se reinician al reiniciar Tomcat; Prometheus permite mantener historial y Grafana graficarlo.

## Instalar desde PowerShell de Visual Studio Code
1. Descomprime el proyecto y abre la carpeta raíz en VS Code.
2. Si no existe `.env`, ejecuta `Copy-Item .env.example .env` y edítalo agregando tu `DATABASE_URL` real (no lo publiques).
3. Genera secretos diferentes con PowerShell:

```powershell
function Nuevo-Secreto { -join ((1..48) | ForEach-Object { 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[(Get-Random -Maximum 62)] }) }
Nuevo-Secreto  # pegar el resultado en METRICS_TOKEN de .env
Nuevo-Secreto  # pegar otro resultado en GRAFANA_PASSWORD de .env
```

4. Inicia todo:

```powershell
docker compose --profile monitoring up -d --build
```

5. Entra a `http://localhost:8080/jsp-Admin/planCapacidad.jsp?tienda=market` tras iniciar sesión como administrador de Market. Cambia el parámetro para las otras tiendas (siempre con la sesión correspondiente).
6. Abre Grafana: `http://localhost:3000` y entra con `GRAFANA_USER` y `GRAFANA_PASSWORD`. Abre Dashboards > Market > Market · Rendimiento. El selector de tienda permite inspeccionar series individuales; el monitor de infraestructura no está filtrado por usuario.

## Seguridad y límites
- Grafana sólo publica el puerto 3000 en `127.0.0.1`. **No compartas** esas credenciales con administradores de tiendas: Grafana tiene datos de las tres tiendas. Para exponer Grafana remotamente se necesita proxy con HTTPS y control de usuarios, roles y filtrado adicional de series por tenant.
- Prometheus no expone puerto al host. Consulta `/monitor/metrics` solo con `Authorization: Bearer <METRICS_TOKEN>`; una variable vacía o con menos de 24 caracteres deshabilita el endpoint.
- No uses `docker run` del contenedor web por separado si quieres Prometheus y Grafana; usa Docker Compose para levantar los tres servicios juntos.
- Las series se almacenan en el volumen Docker `prometheus_data`. Evita `docker compose down -v` si deseas preservar el historial.
- Grafana obtiene los datos de Prometheus (no accede a Supabase).
- Para medir CPU/RAM/disco físico del host o volúmenes externos, añade Node Exporter/cAdvisor con una configuración de seguridad apropiada. Para latencia de base de datos y rendimiento de SQL requiere instrumentación específica adicional.
- Las métricas HTTP agrupan tráfico por el parámetro `tienda` o la sesión de tienda; rutas públicas sin contexto usan el valor por defecto `market`.
