# Auditoría UI/UX — Minimarket Anais

Auditoría heurística de toda la aplicación (tienda, cuentas y panel de administración) con los
**10 principios de usabilidad de Jakob Nielsen**, aplicados uno por uno a cada componente.
Cada hallazgo se corrigió en el código; la columna «Dónde» indica el archivo.

| Código | Heurística |
|---|---|
| H1 | Visibilidad del estado del sistema |
| H2 | Coincidencia entre el sistema y el mundo real |
| H3 | Control y libertad del usuario |
| H4 | Consistencia y estándares |
| H5 | Prevención de errores |
| H6 | Reconocer antes que recordar |
| H7 | Flexibilidad y eficiencia de uso |
| H8 | Diseño estético y minimalista |
| H9 | Ayudar a reconocer, diagnosticar y recuperarse de errores |
| H10 | Ayuda y documentación |

## Decisiones transversales

- **Un solo sistema visual.** Se retiró Bootstrap y los ~30 bloques de `<style>` sueltos (cada
  pantalla tenía su propio «btn-warm», con colores y efectos distintos). Ahora hay un único
  sistema en Tailwind CSS 4, compilado en el build (`src/main/frontend/app.css`), con tokens de
  color, botones, campos, tablas, tarjetas, avisos y estados.
- **Iconos.** Se usan solo SVG oficiales de **Material Symbols** (`google/material-design-icons`,
  el 2.º repositorio de iconos con más estrellas en GitHub, licencia Apache-2.0). Se descargan con
  `tools/descargar-iconos.sh`, fijados a un commit, y se insertan en línea con `<ui:icono>`. Se usa
  una sola familia para mantener la coherencia (H4). No hay SVG dibujados a mano.
- **Sin emojis ni degradados.** Se eliminaron los emojis usados como iconos (🛒 📜 ⚙️ 🧾 📍 ✅ ❌)
  y los efectos de «resplandor» y escalado al pasar el cursor.
- **Movimiento con propósito.** Las transiciones comunican estado: carga de imágenes con
  esqueleto, transición entre páginas (View Transitions), barra de progreso al navegar, entrada
  escalonada de listas, botones con estados (normal → cargando → éxito), menús, diálogos y cajones
  con entrada y salida, acordeones con altura animada y notificaciones con tiempo restante.
  Todo se desactiva con `prefers-reduced-motion`.
- **Mejora progresiva.** Todo funciona sin JavaScript (formularios clásicos con
  Post/Redirect/Get); `app.js` añade validación en línea, confirmaciones y estados.
- **Mensajes en la sesión.** Los avisos viajan en la sesión (`util.Flash`) en vez de
  `?error=` en la URL. Antes se pintaban sin escapar, lo que además era una vulnerabilidad XSS.
- **Accesibilidad de base.** Un `<h1>` por página, enlace «Saltar al contenido», foco visible,
  etiquetas `<label>` reales, `aria-invalid` y `aria-describedby` en los errores, contraste AA del
  color de marca (naranja oscurecido a `#c2410c`) y botones principales de 40 px de alto o más.

---

## Tienda

### 1. Cabecera y búsqueda — `WEB-INF/jspf/tienda-header.jspf`

| | Hallazgo (antes) | Cambio aplicado |
|---|---|---|
| H1 | El contador del carrito solo cambiaba al recargar con otra petición; sin indicación de búsqueda activa. | El contador se actualiza al instante con animación de pulso y `aria-label` («Carrito, 3 productos»). El buscador conserva el texto buscado. |
| H2 | «Admin» aparecía junto a las opciones del cliente; reloj con segundos sin utilidad. | El acceso de administrador pasa al pie («Acceso para administradores»). Se quitó el reloj. Textos como «Ingresar», «Crear cuenta», «Mis compras». |
| H3 | Sin forma clara de volver al inicio desde cualquier página. | El logotipo enlaza al inicio en todas las páginas, y el enlace «Ingresar» devuelve a la página donde estabas (`?volver=`). |
| H4 | La cabecera solo existía en el inicio, con estilos propios; las demás páginas no tenían ninguna. | Una sola cabecera compartida por todas las pantallas de la tienda. |
| H5 | El buscador enviaba vacíos y comillas sin escapar a una consulta concatenada (SQL injection). | Consulta parametrizada y texto escapado; la búsqueda vacía muestra todo. |
| H6 | El menú de cuenta mostraba solo una inicial. | Iniciales, nombre y correo visibles en el menú; las opciones llevan icono y texto. |
| H7 | Sin atajos. | Atajo `/` para enfocar el buscador, con la tecla indicada dentro del campo; el menú se maneja con flechas y Esc. |
| H8 | Fondo azul saturado, botones con brillo y escalado. | Cabecera blanca, fija y translúcida, con jerarquía clara: marca, búsqueda y acciones. |
| H9 | — | Si la búsqueda no encuentra nada, se lleva a un estado vacío con sugerencias (ver listado). |
| H10 | No había ayuda. | El menú de cuenta y el pie enlazan a «Ayuda». |

### 2. Navegación por categorías — `jsp-Interfaz/interfaz.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | No se sabía cuántos productos había en cada categoría; al buscar se resaltaba una categoría elegida «a ojo» con el primer resultado. | Contador por categoría y categoría activa marcada con `aria-current`. La búsqueda ya no cambia la categoría por su cuenta. |
| H2 | Nombres correctos, pero sin apoyo visual. | Cada categoría lleva un icono reconocible (frutas, bebidas, limpieza, mascotas…). |
| H3 | Para quitar una categoría había que buscar «Todos». | Chips de filtros activos con «×» y «Limpiar filtros». |
| H4 | Lista de enlaces con estilos propios. | El mismo componente `.nav-lateral` que el panel. En móvil, chips con el mismo estado activo. |
| H5 | El parámetro `categoria` se concatenaba en SQL. | Se valida contra el catálogo (`util.Catalogo`) y se usa como parámetro. |
| H6 | El mapa de Google ocupaba la barra lateral en cada visita. | La barra lateral muestra solo categorías y una guía breve; el mapa pasa a «Ubicación». |
| H7 | Cambiar de categoría reiniciaba la búsqueda y el orden. | Los enlaces conservan búsqueda, orden y «Solo disponibles». |
| H8 | Iframe de mapa y lista sin jerarquía. | Barra lateral fija y limpia; en móvil, fila desplazable de chips. |
| H9 | Categorías desconocidas no mostraban nada. | Un valor inválido muestra todo el catálogo. |
| H10 | — | Tarjeta «¿Primera compra?» con enlace a «Cómo comprar». |

### 3. Carrusel de promociones — `jsp-Interfaz/interfaz.jsp`, `assets/app.js`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Sin indicador de la promoción actual. | Indicadores con la posición activa (`aria-current`) y transición de ancho. |
| H2 | Dos carruseles idénticos con flechas sin texto. | Un solo carrusel con «Promoción anterior / siguiente» etiquetados. |
| H3 | Pase automático sin forma de detenerlo. | Botón de pausa/reanudar; se pausa al pasar el cursor o con el foco (WCAG 2.2.2). |
| H4 | Componente de Bootstrap distinto del resto. | Mismos botones del sistema; deslizamiento nativo con scroll-snap. |
| H5 | Las imágenes se recortaban a 250 px de alto (`object-cover`), cortando textos de las promos. | Cada promoción conserva su proporción real (de 1:1 a 1.9:1); nada se recorta. |
| H6 | — | Varias promociones visibles a la vez en escritorio. |
| H7 | Solo flechas. | Deslizar con el dedo, indicadores clicables y flechas. |
| H8 | Sombras y bordes redondeados distintos en cada carrusel. | Altura contenida (h-44 a h-64), tarjetas con borde suave. |
| H9 | Si una imagen fallaba quedaba un hueco. | Esqueleto mientras carga; alternativa «Imagen no disponible» si falla. |
| H10 | — | `aria-roledescription` y etiquetas «1 de 6» para lectores de pantalla. |

### 4. Listado de productos (orden, filtros y estados) — `jsp-Interfaz/interfaz.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | No se mostraba cuántos productos había ni qué filtros se aplicaban. | Título con contexto («Resultados para «arroz»»), total de productos y chips de filtros activos. Barra de progreso y resultados atenuados mientras carga. |
| H2 | Los agotados aparecían mezclados al principio. | Orden «Destacados» con los agotados al final; «Más relevantes» al buscar. |
| H3 | Sin forma de deshacer un filtro. | Cada filtro se quita por separado o todos con «Limpiar filtros». |
| H4 | — | Los mismos controles de orden y filtro que el panel. |
| H5 | La búsqueda solo miraba el nombre (no encontraba «cerveza» por descripción). | Busca en nombre, descripción y categoría; escapa `%` y `_`. |
| H6 | — | El orden y los filtros quedan visibles y seleccionados. |
| H7 | Sin ordenar ni ocultar agotados. | Orden por precio y nombre, y «Solo disponibles», aplicados al instante. |
| H8 | Tres columnas grandes con mucho espacio vacío. | Cuadrícula de 2 (móvil) a 4 columnas (escritorio). |
| H9 | Con un error se pintaba la excepción técnica en la página. | Estado de error con explicación y «Reintentar»; estado vacío con sugerencias y «Buscar en todas las categorías». |
| H10 | — | Sugerencias de búsqueda en el estado vacío. |

### 5. Tarjeta de producto — `jsp-Interfaz/interfaz.jsp`, `assets/tienda.js`, `controlador/AgregarCarritoServlet`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Al agregar solo cambiaba un texto pequeño. | El botón pasa de «Agregar» a «Agregando…» (spinner) y a «Agregado» (verde, con check), y luego vuelve; el mensaje indica cuántos tienes; el contador del carrito late. |
| H2 | «Quedan N» y precio sin unidad clara. | Precio con unidad («S/ 2.00 / 625 Mililitros»), «Agotado» y «Quedan N» solo cuando aplica. |
| H3 | — | Sin JS, el formulario vuelve a la misma página con un aviso. |
| H4 | La categoría se mostraba como otra «píldora» más. | Categoría como texto con icono; las etiquetas de estado se reservan para el stock (sin abusar de badges). |
| H5 | Se podía pedir más del stock disponible. | El selector limita al stock, deshabilita −/+ en los extremos y el servidor revalida. Agotado = controles deshabilitados. |
| H6 | — | Imagen, nombre (2 líneas), descripción y precio siempre en el mismo orden. |
| H7 | — | Cantidad con −/+ o escribiéndola; sin recargar la página. |
| H8 | El marco de la foto era un cuadrado enorme y la foto se agrandaba al pasar el cursor. | Marco 4:3 contenido, sin zoom al pasar el cursor; solo cambian la sombra y el borde. |
| H9 | Los errores de red no se comunicaban. | Mensaje junto al producto y notificación si falla la conexión. |
| H10 | — | `aria-live` anuncia el resultado a lectores de pantalla. |

### 6. Carrito — `jsp-Interfaz/carrito.jsp`, `controlador/CarritoServlet`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Saludo, fecha y hora sin relación con la compra; no se veía el progreso. | Indicador de pasos (Carrito → Confirmar → Boleta) y resumen con unidades y total. |
| H2 | Tabla con columnas técnicas. | Filas con imagen, nombre, precio por unidad y subtotal. |
| H3 | **No se podía cambiar la cantidad ni quitar un producto.** | Cambiar cantidad, quitar y vaciar, todo con **«Deshacer»**. |
| H4 | Botón verde con brillo, distinto al resto. | Botones del sistema; el principal es el mismo naranja que en toda la app. |
| H5 | Se podía intentar comprar más del stock y fallar al final. | Aviso por producto cuando la cantidad supera el stock; «Confirmar compra» se deshabilita hasta corregirlo. |
| H6 | Sin imágenes. | Miniatura de cada producto para reconocerlo. |
| H7 | — | Cantidad editable directamente o con −/+. |
| H8 | — | Dos columnas: productos y resumen fijo. |
| H9 | Sin sesión, el botón llevaba a una redirección inesperada. | Aviso «Para comprar necesitas una cuenta; tu carrito se mantiene» y botón «Iniciar sesión para comprar» que vuelve al carrito. |
| H10 | — | Enlace «¿Cómo funciona?» a la ayuda. |

### 7. Confirmación y boleta — `jsp-Interfaz/finalizar-compra.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Al pulsar «Descargar» saltaba un `alert()`. | Página de éxito con icono animado, fecha y hora legibles y paso 3 de 3. |
| H2 | «Total a pagar» cuando la compra ya estaba hecha. | «¡Compra realizada!» y «Total». |
| H3 | — | «Seguir comprando» y «Ver mis compras». |
| H4 | Paleta propia (fondo naranja, tablas cálidas). | Mismo sistema de tarjetas y tablas. |
| H5 | La compra se ejecutaba al cargar la página: recargar podía repetir el proceso; el stock se comprobaba y descontaba por separado. | Confirmación previa con el total; **Post/Redirect/Get** (recargar no compra dos veces); descuento de stock atómico en una sola transacción. |
| H6 | — | Detalle de productos, cliente y correo en la boleta. |
| H7 | — | Descarga del PDF en un clic (se abre en otra pestaña, indicado). |
| H8 | Cuatro bloques de color y botones de tamaños distintos. | Una tarjeta con jerarquía clara y acciones en una fila. |
| H9 | Mensajes como «❌ Error al finalizar la compra: <excepción>». | «Ya no hay suficiente stock de «X». Ajusta la cantidad…», volviendo al carrito con todo intacto. |
| H10 | — | Enlace «Más sobre tu boleta». |

### 8. Mis compras — `jsp-Interfaz/historial.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Una fila por producto: no se distinguían las compras. | Compras agrupadas por fecha, con número de unidades y total, más el total gastado. |
| H2 | Fechas «2025-07-21 21:30». | «lunes, 21 de julio de 2025 · 21:30». |
| H3 | — | Cada compra se pliega y despliega. |
| H4 | Cabecera azul propia. | Cabecera y pie de la tienda. |
| H5 | — | Si no hay sesión, se pide iniciarla y se vuelve aquí. |
| H6 | — | La compra más reciente aparece abierta. |
| H7 | — | Acordeones con animación de altura y teclado. |
| H8 | Tabla con rayas de colores. | Lista de tarjetas limpias. |
| H9 | Los errores se ignoraban (lista vacía). | Aviso de error con «Reintentar», distinto del estado vacío. |
| H10 | — | El estado vacío explica qué aparecerá aquí. |

### 9. Ubicación — `jsp-Interfaz/ubicacion.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | El mapa aparecía en blanco mientras cargaba. | Esqueleto con icono de mapa detrás del iframe. |
| H2 | Solo el mapa. | «Cómo llegar» con «Obtener indicaciones» y «Abrir en Google Maps». |
| H3 | Solo «Volver al inicio». | Ruta de navegación (Inicio › Ubicación) y cabecera completa. |
| H4 | Página sin cabecera ni pie. | Layout de la tienda. |
| H5 | — | Enlaces externos marcados como «se abre en otra pestaña». |
| H6 | — | Nombre de la tienda visible junto al mapa. |
| H7 | — | Indicaciones directas en un clic. |
| H8 | — | Mapa grande en una tarjeta, sin elementos extra. |
| H9 | Si el iframe fallaba no había alternativa. | Nota: «Si no carga, usa Abrir en Google Maps». |
| H10 | — | `title` descriptivo en el iframe para lectores de pantalla. |

### 10. Ayuda — `jsp-Interfaz/ayuda.jsp` (nueva)

| | Hallazgo | Cambio |
|---|---|---|
| H1 | No existía. | Índice de temas con anclas. |
| H2 | — | Lenguaje del cliente: «Tu boleta», «Olvidé mi contraseña». |
| H3 | — | Se accede desde el menú, el pie, el carrito y la boleta. |
| H4 | — | Mismos acordeones que en «Mis compras». |
| H5 | — | Explica los requisitos de contraseña y qué significa «Quedan N». |
| H6 | — | Pasos con iconos iguales a los de la interfaz. |
| H7 | — | Enlaces directos (p. ej. a «¿Olvidaste tu contraseña?»). |
| H8 | — | Respuestas breves y plegables. |
| H9 | — | Qué hacer si el stock cambió durante la compra. |
| H10 | **Faltaba documentación para el cliente.** | Guía de compra en 4 pasos y preguntas frecuentes. |

### 11. Pie de página — `WEB-INF/jspf/tienda-footer.jspf` (nuevo)

| | Hallazgo | Cambio |
|---|---|---|
| H1 | No había pie. | Muestra el estado de la sesión (ofrece «Mis compras» o «Iniciar sesión»). |
| H2 | — | Agrupado en «Comprar», «Ayuda» y «Tu cuenta». |
| H3 | — | Accesos a cualquier sección desde el final de la página. |
| H4 | — | Igual en todas las pantallas de la tienda. |
| H5 | — | El acceso de administración queda separado del flujo del cliente. |
| H6 | — | Categorías principales enlazadas. |
| H7 | — | Atajos a carrito, compras y ubicación. |
| H8 | — | Texto pequeño y gris; no compite con el contenido. |
| H9 | — | — (sin estados de error propios). |
| H10 | — | Enlaces a «Cómo comprar», «Tu boleta» y «Cuenta y contraseña». |

## Cuentas

### 12. Inicio de sesión — `jsp-Usuarios/login.jsp`, `controlador/LoginServlet`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Sin indicación al enviar. | Botón «Ingresando…» con spinner; aviso «Hola, X. Iniciaste sesión». |
| H2 | «Correo Electrónico:» con dos puntos y mayúsculas. | Etiquetas en lenguaje natural y ejemplo de correo. |
| H3 | Botón «Volver al inicio» mezclado con el enlace de registro. | «Volver a la tienda» en la parte superior; tras ingresar vuelves a donde estabas y el carrito se conserva. |
| H4 | Cabecera azul y botón verde. | Layout de acceso común a login, registro, recuperación y admin. |
| H5 | — | Validación en línea del correo; mostrar/ocultar contraseña. |
| H6 | El enlace «¿Olvidaste tu contraseña?» estaba al final. | Junto al campo de contraseña. |
| H7 | — | Autocompletado del navegador (`autocomplete="email" / "current-password"`). |
| H8 | — | Tarjeta centrada con un solo botón principal. |
| H9 | «Credenciales incorrectas» en la URL. | Mensaje junto a la contraseña, con la sugerencia de revisar las mayúsculas y el correo conservado. |
| H10 | — | Enlace para crear cuenta. |

### 13. Registro — `jsp-Usuarios/registro.jsp`, `controlador/RegistroServlet`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Los requisitos de la contraseña solo se conocían al fallar. | Lista de requisitos que se marca mientras escribes. |
| H2 | — | «Repite la contraseña», «Lo usarás para iniciar sesión». |
| H3 | — | Enlace a «Inicia sesión» y «Volver a la tienda». |
| H4 | — | Campos generados por el mismo componente `<ui:campo>` que el resto. |
| H5 | Errores solo en el servidor, de uno en uno; se perdía todo lo escrito. | Validación en línea (formato, longitud, coincidencia) y, si el servidor rechaza, se conservan los datos (nunca la contraseña). |
| H6 | — | Ayuda bajo cada campo. |
| H7 | — | Autocompletado de nombre, apellidos y correo. |
| H8 | — | Nombres y apellidos en una fila. |
| H9 | «El correo ya está registrado» sin salida. | «Ya existe una cuenta con este correo. Inicia sesión o recupera tu contraseña», junto al campo. |
| H10 | — | Requisitos visibles. |

### 14. Recuperar contraseña — `jsp-Usuarios/recuperar.jsp`, `controlador/RecuperarPasswordServlet`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | — | Requisitos en vivo y estado «Guardando…». |
| H2 | — | Título «Crea una nueva contraseña». |
| H3 | — | «Volver a iniciar sesión». |
| H4 | — | Mismo layout y campos que el registro. |
| H5 | — | Confirmación de contraseña validada antes de enviar. |
| H6 | — | El correo se conserva al volver con error. |
| H7 | — | Al terminar se rellena el correo en el inicio de sesión. |
| H8 | — | Tres campos y un botón. |
| H9 | «El correo no está registrado» genérico. | «No encontramos una cuenta con ese correo. Revisa cómo lo escribiste o crea una cuenta», junto al campo. |
| H10 | — | Enlazado desde la ayuda. |

> Nota de seguridad: este flujo permite cambiar la contraseña de cualquier cuenta conociendo
> solo el correo. Requiere verificación por correo; queda señalado como pendiente porque no
> es un cambio de interfaz.

### 15. Mi cuenta (cliente) — `jsp-Usuarios/editarUsuario.jsp`, `controlador/EditarUsuarioServlet`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | — | Indicador «Tienes cambios sin guardar» y aviso al guardar. |
| H2 | — | «Datos personales» y «Cambiar contraseña» separados. |
| H3 | «Volver» sin aviso de pérdida. | Aviso del navegador si sales con cambios sin guardar; «Cancelar» explícito. |
| H4 | Cabecera amarilla propia. | Layout de la tienda. |
| H5 | **Dejar la contraseña en blanco la reemplazaba por un hash vacío** (el cliente ya no podía entrar). | La contraseña solo cambia si se escribe; se valida confirmación y unicidad del correo. |
| H6 | El nombre se partía por el primer espacio (rompía nombres compuestos). | Nombre y apellidos se leen tal cual de la base. |
| H7 | — | La sección de contraseña está plegada por defecto. |
| H8 | — | Dos bloques claros. |
| H9 | `?error=Error: <excepción>`. | Mensajes concretos junto al campo («Ese correo ya pertenece a otra cuenta»). |
| H10 | — | Ayuda bajo el correo sobre su efecto en el inicio de sesión. |

## Panel de administración

### 16. Estructura y navegación — `WEB-INF/jspf/admin-inicio.jspf`, `admin-nav.jspf`, `admin-fin.jspf`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | No había forma de saber en qué sección se estaba. | Barra lateral con la sección activa resaltada (`aria-current`) y el usuario conectado. |
| H2 | «Ver mi historial» e «Historial de Compras de Clientes». | «Actividad» y «Ventas», agrupadas en Catálogo, Compras y Reportes. |
| H3 | Para moverse había que volver siempre a Productos. | Navegación directa a cualquier sección; «Ver tienda» en otra pestaña. |
| H4 | Cada página tenía su propio color de cabecera (azul, naranja, amarillo, celeste). | Una sola estructura para todo el panel. |
| H5 | — | «Cerrar sesión» separado del resto de acciones. |
| H6 | Botones de colores sin agrupar en la parte superior. | Menú con iconos y texto, siempre visible. |
| H7 | — | Cajón lateral en móvil (se cierra con Esc o tocando fuera); atajo `/` para buscar. |
| H8 | — | Fondo neutro, contenido centrado con ancho máximo. |
| H9 | Sin sesión, redirección con `?error=Acceso no autorizado`. | Aviso amable y vuelta a la página pedida después de iniciar sesión. |
| H10 | No había ayuda. | Sección «Ayuda» fija en el menú. |

### 17. Acceso de administrador — `jsp-Admin/loginAdmin.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Bienvenida con `alert()`. | Estado «Ingresando…» y aviso de bienvenida en el panel. |
| H2 | Etiqueta «Nombre» para el usuario. | «Usuario» y «Contraseña». |
| H3 | — | «Volver a la tienda» y enlace al login de clientes. |
| H4 | Reloj y botones propios. | Mismo layout de acceso que la tienda. |
| H5 | Contraseña comparada en texto plano. | Verificación con BCrypt y nueva sesión al autenticarse. |
| H6 | — | El usuario se conserva tras un error. |
| H7 | — | `autocomplete="username" / "current-password"`. |
| H8 | — | Sin reloj ni adornos. |
| H9 | `alert("Usuario o contraseña incorrectos")` y recarga en blanco. | Mensaje junto al campo; error de conexión distinguido del de credenciales. |
| H10 | — | Enlace a la tienda para quien llegó por error. |

### 18. Productos (listado) — `jsp-Productos/producto.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | No se veía cuántos productos había ni cuáles tenían poco stock. | Tarjetas de resumen (total, poco stock, agotados) y «Mostrando X de Y». |
| H2 | Columnas «#», «Unidad», «Imagen» sin contexto. | Producto con miniatura y presentación; stock bajo y agotado señalados. |
| H3 | — | «Limpiar» filtros; los filtros se conservan tras eliminar o agregar. |
| H4 | Formulario de alta y tabla en la misma página, con estilos distintos. | Alta en diálogo con los mismos campos que la edición. |
| H5 | **Eliminar se hacía por GET** con `confirm()`; fallaba sin explicación si el producto tenía compras. | POST con diálogo de confirmación que nombra el producto; si tiene compras, se explica y se sugiere poner el stock en 0. |
| H6 | — | Miniaturas para reconocer productos. |
| H7 | Solo búsqueda por nombre. | Filtro por categoría, stock y orden (menos stock primero); cada cifra del resumen filtra. |
| H8 | Tabla con 9 columnas centradas. | 5 columnas, números alineados a la derecha; en móvil, filas como tarjetas. |
| H9 | Excepciones mostradas en la tabla. | Estado de error con «Reintentar» y estado vacío con «Limpiar filtros». |
| H10 | — | Texto de ayuda bajo el título y sección de ayuda del panel. |

### 19. Formulario de producto (alta y edición) — `WEB-INF/jspf/producto-campos.jspf`, `jsp-Productos/EditarProducto.jsp`, `util/ProductoForm`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Tras guardar volvía a la lista sin confirmación. | Aviso «Guardaste los cambios de «X»» y botón «Guardando…». |
| H2 | «Cantidad» + «Unidad» confusos; «URL de Imagen» cuando en realidad es una ruta. | «Contenido» + «Unidad de medida»; «Imagen: ruta en el bucket images». |
| H3 | — | «Cancelar» y aviso de cambios sin guardar; ruta de navegación Productos › nombre. |
| H4 | En la edición la categoría era un texto libre y en el alta una lista. | Mismas listas en ambos (`util.Catalogo`). |
| H5 | Se podían guardar precios negativos y textos en campos numéricos (excepción). | Validación en línea y en el servidor (precio ≥ 0.10, stock ≥ 0, contenido > 0). |
| H6 | Había que recordar el nombre exacto del archivo de imagen. | Vista previa de la imagen en vivo mientras se escribe la ruta. |
| H7 | — | Teclado numérico en móvil (`inputmode`). |
| H8 | Campos sin agrupar. | Cuadrícula de dos columnas con ancho según el contenido. |
| H9 | «Error al actualizar: <excepción>». | Errores junto al campo y aviso «No encontramos esa imagen». |
| H10 | — | Ayuda bajo descripción, stock, contenido e imagen. |

### 20. Proveedores — `jsp-Proveedores/Proveedores.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | No se sabía cuándo fue la última compra a cada proveedor. | «Última compra: fecha» en cada tarjeta y contadores de activos y desactivados. |
| H2 | «Desactivar» con icono de papelera, como si borrara. | «Desactivar» con explicación de que el historial se conserva. |
| H3 | **Desactivar no se podía revertir.** | «Deshacer» en el aviso y pestaña «Desactivados» con «Reactivar». |
| H4 | Fondo celeste propio. | Tarjetas del sistema. |
| H5 | Se desactivaba sin confirmar. | Diálogo de confirmación con consecuencias. |
| H6 | — | Contacto, teléfono y RUC con iconos. |
| H7 | — | «Compra» directa desde la tarjeta (preselecciona el proveedor) y teléfono clicable. |
| H8 | — | Cuadrícula de tarjetas con acciones al pie. |
| H9 | Errores como texto de excepción. | Estados de error y vacío con acción. |
| H10 | — | Texto explicativo bajo el título. |

### 21. Formulario de proveedor — `WEB-INF/jspf/proveedor-campos.jspf`, `nuevoProveedor.jsp`, `editarProveedor.jsp`, `util/ProveedorForm`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | — | Aviso al guardar y estado «Guardando…». |
| H2 | «Nombre*» con asteriscos sin explicación. | «Razón social o nombre comercial» y «(opcional)» solo donde aplica. |
| H3 | Tras editar redirigía a `proveedores.jsp` (en minúsculas, **404** en Linux). | Redirección correcta, «Cancelar» y ruta de navegación. |
| H4 | La edición estaba en otra codificación (`Tel�fono`). | Mismo fragmento de campos en alta y edición, en UTF-8. |
| H5 | El tipo «Otros» no existía en el formulario, aunque la base lo admite; el RUC duplicado generaba una excepción. | Tipos desde `util.Catalogo` y RUC duplicado detectado con un mensaje claro. |
| H6 | — | Ayuda y ejemplos (RUC de 11 dígitos, formato de teléfono). |
| H7 | — | `inputmode` numérico para el RUC. |
| H8 | — | Agrupación lógica; dirección opcional al final. |
| H9 | `?error=<excepción>`. | «Ya existe un proveedor con ese RUC. Búscalo en la lista (también entre los desactivados)». |
| H10 | — | Queda registrado en el historial del proveedor. |

### 22. Registrar compra — `jsp-Proveedores/comprasProveedor.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | No se sabía el total ni cómo quedaría el stock. | Resumen en vivo: total de la compra y «Stock: 12 → 32». |
| H2 | — | «Cantidad recibida» y «Precio unitario». |
| H3 | — | «Cancelar» y aviso de cambios sin guardar. |
| H4 | Paleta propia. | Formulario del sistema. |
| H5 | **La compra y el aumento de stock no eran una transacción** (podía guardarse una sin la otra). | Transacción única; validación de cantidades y precios. |
| H6 | La lista de 179 productos no estaba ordenada ni agrupada. | Agrupada por categoría y con el stock actual de cada producto. |
| H7 | — | Proveedor preseleccionado al venir desde su tarjeta. |
| H8 | — | Dos columnas: datos y resumen. |
| H9 | `?error=<excepción>`. | «No pudimos registrar la compra; no se modificó el stock». |
| H10 | — | Explica que la cantidad se suma al stock al guardar. |

### 23. Historial de proveedores — `jsp-Proveedores/historialProveedor.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | **Las compras se asociaban al proveedor equivocado** (se cruzaba el ID de la compra con el del proveedor). | Consulta corregida; título con el proveedor filtrado. |
| H2 | Códigos internos «COMPRA_PROV», «postgres». | «Compra registrada», «Registro automático». |
| H3 | — | «Limpiar» filtros y ruta de navegación. |
| H4 | Línea de tiempo con colores propios. | Lista agrupada por día con el mismo estilo que «Actividad». |
| H5 | Filtros concatenados en SQL. | Parámetros validados (fechas `aaaa-mm-dd`, acciones conocidas). |
| H6 | El filtro de acción no recordaba la selección. | Los filtros quedan seleccionados. |
| H7 | Solo «desde». | Rango «desde / hasta» y aplicación automática al cambiar. |
| H8 | Insignias de colores para cada acción. | Icono y texto; sin insignias. |
| H9 | Excepciones como texto. | Estados de error y vacío con acción. |
| H10 | — | Indica el límite de 200 movimientos y cómo acotarlo. |

### 24. Actividad — `jsp-Admin/historialAdmin.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Se mostraban solo los últimos 100 sin aviso. | Paginación con «Página X de Y · N registros». |
| H2 | «Producto ID #34». | «Producto editado», cambios por campo y enlace «Abrir producto». |
| H3 | — | Filtro «Todas» y «Ver toda la actividad». |
| H4 | Insignias de colores. | Lista igual a la del historial de proveedores. |
| H5 | — | Distingue los productos que ya no existen. |
| H6 | — | Icono por tipo de cambio (precio, stock, imagen…). |
| H7 | Sin filtros. | Segmentos por tipo y búsqueda en el detalle. |
| H8 | — | Una línea por cambio, sin tablas. |
| H9 | Excepción en la tabla. | Estado de error con «Reintentar». |
| H10 | — | Explica que se registra automáticamente. |

### 25. Ventas — `jsp-Admin/ventasAdmin.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Los totales aparecían al final, después de la tabla. | KPIs arriba: total vendido, compras, unidades y ticket promedio del periodo. |
| H2 | «Registros encontrados». | «Compras», «Unidades vendidas». |
| H3 | — | Quitar la búsqueda de cliente con «×». |
| H4 | Cada filtro con un color distinto (verde, amarillo, azul, negro). | Control segmentado único con el periodo activo. |
| H5 | — | Fechas validadas; tope de 300 filas en pantalla con aviso. |
| H6 | No se sabía qué periodo se estaba viendo. | Periodo visible en el título del detalle. |
| H7 | Solo hoy, semana y mes. | Rango de fechas, búsqueda por cliente (clic en un correo para filtrarlo) y **Exportar CSV**. |
| H8 | Tabla centrada con iconos de persona en cada fila. | Tabla alineada y legible; en móvil, filas como tarjetas. |
| H9 | Excepción en la tabla. | Error con «Reintentar» y estado vacío «Ver todas las ventas». |
| H10 | — | Subtítulo que explica el origen de los datos. |

### 26. Mi cuenta (admin) — `jsp-Admin/editarAdmin.jsp`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Confirmación con `alert()`. | Aviso en el panel y «Tienes cambios sin guardar». |
| H2 | — | «Datos de acceso» y «Cambiar contraseña». |
| H3 | — | «Cancelar» y aviso al salir sin guardar. |
| H4 | Estilos propios. | Mismo patrón que «Mi cuenta» del cliente. |
| H5 | **La contraseña actual se precargaba en el campo** y se podía cambiar todo sin confirmar. | Ya no se muestra la contraseña; para guardar se pide la contraseña actual (verificada con BCrypt). |
| H6 | — | El usuario actual se precarga. |
| H7 | — | Contraseña plegada; requisitos en vivo. |
| H8 | — | Tres bloques breves. |
| H9 | `alert()` con mínimos de 4 caracteres. | Errores junto al campo y mínimo de 8 caracteres con letra y número. |
| H10 | — | Explica por qué se pide la contraseña actual. |

### 27. Ayuda del panel — `jsp-Admin/ayudaAdmin.jsp` (nueva)

| | Hallazgo | Cambio |
|---|---|---|
| H1 | No existía. | Temas plegables con el primero abierto. |
| H2 | — | Redactada como tareas: «Dejar de vender un producto». |
| H3 | — | Accesible desde la barra lateral en todo momento. |
| H4 | — | Mismos acordeones que la ayuda de la tienda. |
| H5 | — | Explica qué acciones no se pueden deshacer. |
| H6 | — | Icono de la sección de cada tarea. |
| H7 | — | Lista de atajos de teclado. |
| H8 | — | Columna de temas y otra de atajos. |
| H9 | — | Qué hacer cuando un producto no se puede eliminar. |
| H10 | **Faltaba documentación para el administrador.** | Guía de las 7 tareas más comunes. |

## Componentes transversales

### 28. Notificaciones — `WEB-INF/jspf/fin.jspf`, `assets/app.js`, `util/Flash`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Mensajes como `alert()` o en la URL. | Notificaciones con icono y barra de tiempo restante. |
| H2 | «✅ Producto eliminado correctamente.» | Frases concretas: «Eliminaste «X»». |
| H3 | — | Botón «Deshacer» en las acciones reversibles (carrito, proveedores). |
| H4 | Cada pantalla pintaba sus avisos de otra forma. | Un solo componente para toda la app. |
| H5 | Mensajes en la URL sin escapar (XSS). | En la sesión y escapados. |
| H6 | — | Icono distinto para éxito, error e información. |
| H7 | — | Se pausan al pasar el cursor o con el foco. |
| H8 | — | Abajo a la derecha; no tapan el contenido. |
| H9 | — | Los errores no desaparecen solos: se cierran a mano. |
| H10 | — | `aria-live` y `role="alert"` para lectores de pantalla. |

### 29. Diálogo de confirmación — `WEB-INF/jspf/fin.jspf`, `assets/app.js`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | `confirm()` nativo con «¿Eliminar producto?». | Diálogo con título, consecuencia y animación de entrada y salida. |
| H2 | — | Botones con verbo («Eliminar», «Desactivar», «Sí, comprar»). |
| H3 | — | Cancelar con Esc, clic fuera o botón; el foco empieza en «Cancelar». |
| H4 | — | El mismo diálogo para todas las acciones críticas. |
| H5 | Algunas acciones destructivas no pedían confirmación (desactivar proveedor). | Confirmación obligatoria en eliminar, desactivar y comprar. |
| H6 | — | El texto nombra el elemento afectado. |
| H7 | — | Teclado completo (`<dialog>` nativo, foco atrapado). |
| H8 | — | Una sola idea por diálogo. |
| H9 | — | Explica que la acción no se puede deshacer cuando corresponde. |
| H10 | — | En navegadores sin `<dialog>` se usa `confirm()` con el mismo texto. |

### 30. Páginas de error — `WEB-INF/errores/404.jsp`, `500.jsp`, `web.xml`

| | Hallazgo | Cambio |
|---|---|---|
| H1 | Tomcat mostraba la traza completa (`HTTP Status 500 – JasperException…`). | Página propia que indica qué pasó. |
| H2 | Jerga técnica. | «No encontramos esta página», «Algo salió mal de nuestro lado». |
| H3 | Sin salida. | «Volver atrás», «Ir a la tienda», «Reintentar». |
| H4 | — | Mismo sistema visual. |
| H5 | — | El error se registra en el log del servidor, no en pantalla. |
| H6 | — | Icono y código del error visibles. |
| H7 | — | Acción principal en un clic. |
| H8 | — | Mensaje breve y centrado. |
| H9 | **Se exponían detalles internos.** | Explicación humana y tranquilizadora («no se perdió nada de tu carrito»). |
| H10 | — | Enlace a la tienda como punto de partida. |

---

## Verificación

`sh tools/verificar.sh` construye la imagen Docker, levanta PostgreSQL con `db/`, inicia sesión
como cliente y como administrador, y recorre todas las pantallas. Falla ante cualquier
respuesta 5xx, excepción visible o carácter mal codificado. Se ejecuta antes de cada push.

## Pendientes fuera del alcance de la interfaz

- **Productos duplicados en los datos.** 49 productos aparecen tres veces (IDs 1–50, 51–100 y
  101–150), por la carga original. Corregirlo implica fusionar y borrar filas de la base.
- **Recuperación de contraseña sin verificación** (ver la nota de la sección 14).
