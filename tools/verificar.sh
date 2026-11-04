#!/bin/sh
# Prueba de humo local: construye la imagen, levanta PostgreSQL con los datos de db/
# y recorre todas las pantallas (visitante, cliente y administrador).
# Falla si alguna responde 5xx, muestra una excepción o tiene caracteres mal codificados.
# Uso: sh tools/verificar.sh
set -u
cd "$(dirname "$0")/.."
RED=verificar-market
PUERTO=18080
B="http://localhost:$PUERTO"
TMP=$(mktemp -d)
FALLOS=0

limpiar() { docker rm -f verificar-app verificar-pg >/dev/null 2>&1; docker network rm $RED >/dev/null 2>&1; rm -rf "$TMP"; }
[ "${CONSERVAR:-0}" = 1 ] || trap limpiar EXIT
docker rm -f verificar-app verificar-pg >/dev/null 2>&1; docker network rm $RED >/dev/null 2>&1
docker network create $RED >/dev/null

echo "== Base de datos"
docker run -d --name verificar-pg --network $RED -e POSTGRES_PASSWORD=local postgres:17 >/dev/null
until docker exec verificar-pg pg_isready -U postgres >/dev/null 2>&1; do sleep 1; done
sleep 2
for f in db/01_schema.sql db/02_data.sql db/03_triggers.sql db/04_multi_tienda.sql db/05_carrusel.sql db/06_imagenes_producto.sql db/07_gestion_administrativa.sql; do
  docker exec -i verificar-pg psql -q -v ON_ERROR_STOP=1 -U postgres < "$f" >/dev/null || { echo "FALLO al cargar $f"; exit 1; }
done
docker exec verificar-pg psql -q -U postgres -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;
  UPDATE admin SET clave = crypt('admin-local-123', gen_salt('bf', 10));
  INSERT INTO usuarios (nombre, apellidos, correo, contrasena) VALUES ('Prueba', 'Local', 'prueba@local.test', crypt('Prueba123', gen_salt('bf', 10)));" >/dev/null

echo "== Imagen"
docker build -q -t verificar-market . >/dev/null || { echo "FALLO el build"; exit 1; }
docker run -d --name verificar-app --network $RED -p $PUERTO:8080 \
  -e DATABASE_URL='postgresql://postgres:local@verificar-pg:5432/postgres?sslmode=disable' verificar-market >/dev/null
until curl -s -o /dev/null "$B/"; do sleep 1; done

revisar() { # $1 = descripción, $2 = cookie jar ("" = sin sesión), $3 = ruta, $4 = código esperado (200 por defecto)
  cuerpo="$TMP/cuerpo"; : > "$cuerpo"
  codigo=$(curl -s -o "$cuerpo" -w '%{http_code}' ${2:+-b "$2"} "$B$3")
  esperado=${4:-200}
  problema=""
  [ "$codigo" = "$esperado" ] || problema="HTTP $codigo (se esperaba $esperado)"
  grep -qE 'Exception|JasperException|Stacktrace' "$cuerpo" && problema="$problema excepción"
  grep -qE 'Ã|Â' "$cuerpo" && problema="$problema codificación"
  if [ -n "$problema" ]; then
    FALLOS=$((FALLOS + 1)); echo "  FALLO  $1 $3 → $problema"
    grep -oE '(JasperException|Exception)[^<]{0,200}' "$cuerpo" | head -2 | sed 's/^/         /'
  else
    echo "  ok     $1 $3 ($codigo)"
  fi
}

CLI="$TMP/cliente"; ADM="$TMP/admin"
curl -s -c "$CLI" -o /dev/null -d 'correo=prueba@local.test&contrasena=Prueba123' "$B/login-usuario"
curl -s -b "$CLI" -c "$CLI" -o /dev/null -H 'Accept: application/json' -d 'id=10&cantidad=2' "$B/agregar-carrito"
curl -s -c "$ADM" -o /dev/null -d 'usuario=administrador&clave=admin-local-123' "$B/jsp-Admin/loginAdmin.jsp"
echo "  login cliente → $(curl -s -b "$CLI" -o /dev/null -w '%{http_code}' "$B/jsp-Interfaz/historial.jsp") (200 = sesión válida)"
echo "  login admin   → $(curl -s -b "$ADM" -o /dev/null -w '%{http_code}' "$B/jsp-Productos/producto.jsp") (200 = sesión válida)"

echo "== Visitante"
for r in /jsp-Interfaz/interfaz.jsp "/jsp-Interfaz/interfaz.jsp?categoria=Bebidas&orden=precio_asc" "/jsp-Interfaz/interfaz.jsp?buscar=zzzz" \
         /jsp-Interfaz/carrito.jsp /jsp-Interfaz/ubicacion.jsp /jsp-Interfaz/ayuda.jsp \
         /jsp-Usuarios/login.jsp /jsp-Usuarios/registro.jsp /jsp-Usuarios/recuperar.jsp /jsp-Admin/loginAdmin.jsp /no-existe.jsp; do
  esperado=200; [ "$r" = /no-existe.jsp ] && esperado=404
  revisar visitante "" "$r" $esperado
done
echo "== Cliente"
for r in /jsp-Interfaz/interfaz.jsp /jsp-Interfaz/carrito.jsp /jsp-Interfaz/historial.jsp /jsp-Usuarios/editarUsuario.jsp; do
  revisar cliente "$CLI" "$r"
done
revisar cliente "$CLI" /jsp-Interfaz/finalizar-compra.jsp 302   # sin compra previa → al carrito
curl -s -b "$CLI" -c "$CLI" -o /dev/null -X POST "$B/jsp-Interfaz/finalizar-compra.jsp"
revisar cliente "$CLI" /jsp-Interfaz/finalizar-compra.jsp
echo "== Administrador"
for r in /jsp-Productos/producto.jsp "/jsp-Productos/producto.jsp?stock=poco&buscar=a" /jsp-Productos/EditarProducto.jsp?id=10 \
         /jsp-Proveedores/Proveedores.jsp "/jsp-Proveedores/Proveedores.jsp?ver=inactivos" /jsp-Proveedores/nuevoProveedor.jsp \
         /jsp-Proveedores/editarProveedor.jsp?id=6 /jsp-Proveedores/comprasProveedor.jsp /jsp-Proveedores/historialProveedor.jsp \
         /jsp-Admin/historialAdmin.jsp "/jsp-Admin/ventasAdmin.jsp?periodo=todos" /jsp-Admin/editarAdmin.jsp /jsp-Admin/ayudaAdmin.jsp /jsp-Admin/catalogoSolicitudes.jsp /jsp-Admin/gestionCambios.jsp /jsp-Admin/pipelineCI.jsp /jsp-Admin/planCapacidad.jsp; do
  revisar admin "$ADM" "$r"
done

docker logs verificar-app 2>&1 | grep -E 'SEVERE|Exception' | grep -v 'Icono no encontrado' | head -5 | sed 's/^/  log: /'
echo
if [ "$FALLOS" -gt 0 ]; then echo "RESULTADO: $FALLOS fallo(s)"; exit 1; fi
echo "RESULTADO: todo correcto"
