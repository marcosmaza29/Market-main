<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Html, util.Flash, util.Catalogo, util.ProductoForm" %>
<%
    // ---------- Seguridad y tienda del administrador ----------
    String admin = (String) session.getAttribute("adminUsuario");
    String tiendaId = (String) session.getAttribute("adminTiendaId");

    boolean tiendaValida = "market".equals(tiendaId)
            || "juguetes".equals(tiendaId)
            || "cosmeticos".equals(tiendaId);

    if (!Boolean.TRUE.equals(session.getAttribute("adminLogueado"))
            || admin == null || !tiendaValida) {

        String tiendaSolicitada = request.getParameter("tienda");

        if (!"market".equals(tiendaSolicitada)
                && !"juguetes".equals(tiendaSolicitada)
                && !"cosmeticos".equals(tiendaSolicitada)) {
            tiendaSolicitada = "market";
        }

        response.sendRedirect(
            ctx + "/jsp-Admin/loginAdmin.jsp?tienda=" + tiendaSolicitada
        );
        return;
    }

    // Si la URL solicita otra tienda, no permitir acceso cruzado.
    String tiendaSolicitada = request.getParameter("tienda");

    if (tiendaSolicitada != null && !tiendaId.equals(tiendaSolicitada)) {
        response.sendError(
            HttpServletResponse.SC_FORBIDDEN,
            "No tienes permiso para acceder a esta tienda."
        );
        return;
    }

    // ---------- Acciones (POST -> redirección con aviso) ----------
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String accion = request.getParameter("accion");
        String filtrosPost = request.getParameter("filtros");

        String volverA = ctx + "/jsp-Productos/producto.jsp?tienda=" + tiendaId;

        if (filtrosPost != null && !filtrosPost.trim().isEmpty()) {
            volverA += "&" + filtrosPost;
        }

        if ("agregar".equals(accion)) {
            ProductoForm f = ProductoForm.leer(request, tiendaId);

            if (f.campoError != null) {
                Flash.formulario(
                    session, request.getParameterMap(),
                    f.campoError, f.mensajeError
                );
                session.setAttribute("producto.reabrir", true);
                response.sendRedirect(volverA);
                return;
            }

            try (Connection conn = util.Conexion.getConnection()) {
                int nuevoId;

                try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO productos "
                    + "(nombre, descripcion, precio, stock, unidad, imagen_url, categoria, tienda_id) "
                    + "VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING id")) {

                    ps.setString(1, f.nombre);
                    ps.setString(2, f.descripcion.isEmpty() ? null : f.descripcion);
                    ps.setDouble(3, f.precio);
                    ps.setInt(4, f.stock);
                    ps.setString(5, f.unidadCompleta());
                    ps.setString(6, f.imagen.isEmpty() ? null : f.imagen);
                    ps.setString(7, f.categoria);

                    // La tienda proviene de la sesión, nunca del formulario.
                    ps.setString(8, tiendaId);

                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        nuevoId = rs.getInt(1);
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO historial_admin "
                    + "(usuario_admin, accion, tabla_afectada, id_afectado, detalles, tienda_id) "
                    + "VALUES (?, 'AGREGAR', 'productos', ?, ?, ?)")) {

                    ps.setString(1, admin);
                    ps.setInt(2, nuevoId);
                    ps.setString(
                        3,
                        "Tienda: " + tiendaId
                        + " | Producto agregado: " + f.nombre
                        + " | Precio: S/"
                        + String.format(Locale.US, "%.2f", f.precio)
                        + " | Stock: " + f.stock
                    );
                    ps.setString(4, tiendaId);
                    ps.executeUpdate();
                }

                Flash.exito(
                    session,
                    "Agregaste «" + f.nombre + "» a tu tienda."
                );

            } catch (Exception e) {
                log("Error al agregar producto", e);
                Flash.error(
                    session,
                    "No pudimos guardar el producto. Revisa la conexión e inténtalo de nuevo."
                );
                Flash.formulario(session, request.getParameterMap(), null);
                session.setAttribute("producto.reabrir", true);
            }

            response.sendRedirect(volverA);
            return;
        }

        if ("eliminar".equals(accion)) {
            String nombre = request.getParameter("nombre");

            try (Connection conn = util.Conexion.getConnection();
                 PreparedStatement ps = conn.prepareStatement(
                     "DELETE FROM productos WHERE id = ? AND tienda_id = ?")) {

                ps.setInt(1, Integer.parseInt(request.getParameter("id")));
                ps.setString(2, tiendaId);

                // Solo elimina productos pertenecientes a esta tienda.
                if (ps.executeUpdate() > 0) {
                    Flash.exito(session, "Eliminaste «" + nombre + "».");
                } else {
                    Flash.error(
                        session,
                        "El producto no existe o no pertenece a tu tienda."
                    );
                }

            } catch (SQLException e) {
                if ("23503".equals(e.getSQLState())) {
                    Flash.error(
                        session,
                        "No se puede eliminar «" + nombre
                        + "» porque tiene compras registradas. Para dejar de venderlo, edítalo y pon su stock en 0."
                    );
                } else {
                    log("Error al eliminar producto", e);
                    Flash.error(
                        session,
                        "No pudimos eliminar el producto. Inténtalo de nuevo."
                    );
                }
            } catch (NumberFormatException e) {
                Flash.error(session, "Producto no válido.");
            }

            response.sendRedirect(volverA);
            return;
        }
    }

    // ---------- Listado ----------
    String titulo = "Productos";
    String seccion = "productos";

    Map<String, String> pf = Flash.formulario(session);
    String pfError = pf.get("__error");
    String pfMsg = pf.get("__mensaje");

    boolean reabrir = session.getAttribute("producto.reabrir") != null;
    session.removeAttribute("producto.reabrir");

    String buscar = Html.param(request, "buscar");
    String categoria = Html.param(request, "categoria");

    if (!Catalogo.esCategoria(categoria, tiendaId)) {
        categoria = null;
    }

    String estadoStock = request.getParameter("stock");

    if (!"poco".equals(estadoStock) && !"agotado".equals(estadoStock)) {
        estadoStock = "todos";
    }

    String orden = request.getParameter("orden");

    if (!Arrays.asList("nombre", "stock", "precio").contains(orden)) {
        orden = "nombre";
    }

    int total = 0, pocos = 0, agotados = 0;
    List<Map<String, Object>> filas = new ArrayList<>();
    boolean errorDatos = false;

    try (Connection conn = util.Conexion.getConnection()) {

        // Los contadores solo consideran la tienda de la sesión.
        try (PreparedStatement ps = conn.prepareStatement(
            "SELECT COUNT(*), "
            + "COUNT(*) FILTER (WHERE stock BETWEEN 1 AND 5), "
            + "COUNT(*) FILTER (WHERE stock <= 0) "
            + "FROM productos WHERE tienda_id = ?")) {

            ps.setString(1, tiendaId);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                total = rs.getInt(1);
                pocos = rs.getInt(2);
                agotados = rs.getInt(3);
            }
        }

        // El listado siempre comienza filtrando por tienda.
        StringBuilder sql = new StringBuilder(
            "SELECT id, nombre, descripcion, precio, stock, unidad, imagen_url, categoria "
            + "FROM productos WHERE tienda_id = ?"
        );

        List<Object> params = new ArrayList<>();
        params.add(tiendaId);

        if (buscar != null) {
            sql.append(" AND nombre ILIKE ?");
            params.add(
                "%" + buscar.replace("\\", "\\\\")
                    .replace("%", "\\%")
                    .replace("_", "\\_") + "%"
            );
        }

        if (categoria != null) {
            sql.append(" AND categoria = ?");
            params.add(categoria);
        }

        if ("poco".equals(estadoStock)) {
            sql.append(" AND stock BETWEEN 1 AND 5");
        }

        if ("agotado".equals(estadoStock)) {
            sql.append(" AND stock <= 0");
        }

        sql.append(
            "stock".equals(orden)
                ? " ORDER BY stock, nombre"
                : "precio".equals(orden)
                    ? " ORDER BY precio DESC, nombre"
                    : " ORDER BY nombre"
        );

        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new HashMap<>();

                    f.put("id", rs.getInt("id"));
                    f.put("nombre", rs.getString("nombre"));
                    f.put("descripcion", rs.getString("descripcion"));
                    f.put("precio", rs.getDouble("precio"));
                    f.put("stock", rs.getInt("stock"));
                    f.put("unidad", rs.getString("unidad"));
                    f.put("imagen", rs.getString("imagen_url"));
                    f.put("categoria", rs.getString("categoria"));

                    filas.add(f);
                }
            }
        }

    } catch (Exception e) {
        log("Error al listar productos", e);
        errorDatos = true;
    }

    boolean hayFiltros = buscar != null
            || categoria != null
            || !"todos".equals(estadoStock);

    String filtrosActuales = request.getQueryString() == null
            ? "" : request.getQueryString();

    String base = ctx + "/jsp-Productos/producto.jsp";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/jspf/head.jspf" %>
</head>

<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>

    <div class="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
            <h1 class="text-2xl font-semibold tracking-tight text-stone-900">Productos</h1>
            <p class="mt-1 text-sm text-stone-600">Catálogo que ven los clientes en la tienda.</p>
        </div>
        <button type="button" class="btn btn-primario" data-abrir-dialogo="dlg-producto">
            <ui:icono n="add"/>Nuevo producto
        </button>
    </div>

    <%-- Resumen del inventario --%>
    <div class="mt-6 grid gap-3 sm:grid-cols-3">
        <a href="<%= base %>?tienda=<%= tiendaId %>"
           class="tarjeta flex items-center gap-4 p-4 transition hover:ring-stone-300 <%= "todos".equals(estadoStock) && !hayFiltros ? "ring-2 ring-stone-900" : "" %>">
            <span class="grid size-10 place-items-center rounded-lg bg-stone-100 text-stone-600">
                <ui:icono n="inventory_2"/>
            </span>
            <span>
                <span class="block text-2xl font-semibold tabular-nums text-stone-900"><%= total %></span>
                <span class="text-sm text-stone-600">Productos</span>
            </span>
        </a>

        <a href="<%= base %>?tienda=<%= tiendaId %>&amp;stock=poco"
           class="tarjeta flex items-center gap-4 p-4 transition hover:ring-stone-300 <%= "poco".equals(estadoStock) ? "ring-2 ring-amber-600" : "" %>">
            <span class="grid size-10 place-items-center rounded-lg bg-amber-50 text-amber-700">
                <ui:icono n="warning"/>
            </span>
            <span>
                <span class="block text-2xl font-semibold tabular-nums text-stone-900"><%= pocos %></span>
                <span class="text-sm text-stone-600">Con poco stock (1–5)</span>
            </span>
        </a>

        <a href="<%= base %>?tienda=<%= tiendaId %>&amp;stock=agotado"
           class="tarjeta flex items-center gap-4 p-4 transition hover:ring-stone-300 <%= "agotado".equals(estadoStock) ? "ring-2 ring-red-700" : "" %>">
            <span class="grid size-10 place-items-center rounded-lg bg-red-50 text-red-700">
                <ui:icono n="remove_shopping_cart"/>
            </span>
            <span>
                <span class="block text-2xl font-semibold tabular-nums text-stone-900"><%= agotados %></span>
                <span class="text-sm text-stone-600">Agotados</span>
            </span>
        </a>
    </div>

    <section class="tarjeta mt-6" aria-labelledby="h-listado">
        <h2 id="h-listado" class="sr-only">Listado de productos</h2>

        <form method="get" action="<%= base %>"
              class="flex flex-col gap-3 border-b border-stone-200 p-4 md:flex-row md:items-center">

            <input type="hidden" name="tienda" value="<%= tiendaId %>">

            <label for="f-buscar" class="sr-only">Buscar por nombre</label>
            <div class="entrada-icono md:flex-1">
                <ui:icono n="search"/>
                <input id="f-buscar" type="search" name="buscar"
                       value="<%= Html.esc(buscar) %>"
                       class="entrada" placeholder="Buscar por nombre"
                       data-atajo-buscar>
            </div>

            <div class="grid grid-cols-2 gap-3 md:flex">
                <label class="sr-only" for="f-categoria">Categoría</label>
                <select id="f-categoria" name="categoria" class="entrada md:w-48" data-auto-enviar>
                    <option value="">Todas las categorías</option>
                    <% for (String c : Catalogo.categorias(tiendaId).keySet()) { %>
                        <option value="<%= Html.esc(c) %>" <%= c.equals(categoria) ? "selected" : "" %>>
                            <%= Html.esc(c) %>
                        </option>
                    <% } %>
                </select>

                <label class="sr-only" for="f-orden">Ordenar</label>
                <select id="f-orden" name="orden" class="entrada md:w-44" data-auto-enviar>
                    <option value="nombre" <%= "nombre".equals(orden) ? "selected" : "" %>>Nombre (A–Z)</option>
                    <option value="stock" <%= "stock".equals(orden) ? "selected" : "" %>>Menos stock primero</option>
                    <option value="precio" <%= "precio".equals(orden) ? "selected" : "" %>>Precio más alto</option>
                </select>
            </div>

            <% if (!"todos".equals(estadoStock)) { %>
                <input type="hidden" name="stock" value="<%= estadoStock %>">
            <% } %>

            <button type="submit" class="btn btn-secundario" data-sin-carga>Buscar</button>

            <% if (hayFiltros) { %>
                <a href="<%= base %>?tienda=<%= tiendaId %>" class="btn btn-fantasma">
                    <ui:icono n="filter_alt_off"/>Limpiar
                </a>
            <% } %>
        </form>

        <% if (errorDatos) { %>
            <div class="p-4">
                <div class="aviso aviso-error" role="alert">
                    <ui:icono n="error"/>
                    <div>
                        <p class="font-medium">No pudimos cargar los productos.</p>
                        <a class="btn btn-secundario btn-sm mt-2"
                           href="<%= Html.esc(base + "?tienda=" + tiendaId) %>">
                            <ui:icono n="restart_alt" clase="size-4"/>Reintentar
                        </a>
                    </div>
                </div>
            </div>
        <% } else if (filas.isEmpty()) { %>
            <div class="flex flex-col items-center px-6 py-14 text-center">
                <span class="grid size-12 place-items-center rounded-full bg-stone-100 text-stone-500">
                    <ui:icono n="search_off" clase="size-6"/>
                </span>
                <p class="mt-3 font-medium text-stone-900">
                    <%= hayFiltros ? "Ningún producto coincide con los filtros." : "Todavía no hay productos." %>
                </p>
                <p class="mt-1 text-sm text-stone-600">
                    <%= hayFiltros ? "Prueba con otro nombre o limpia los filtros." : "Agrega el primero con «Nuevo producto»." %>
                </p>
                <% if (hayFiltros) { %>
                    <a href="<%= base %>?tienda=<%= tiendaId %>" class="btn btn-secundario mt-4">
                        Limpiar filtros
                    </a>
                <% } %>
            </div>
        <% } else { %>
            <p class="px-4 pt-3 text-xs text-stone-500" aria-live="polite">
                Mostrando <%= filas.size() %> de <%= total %>
            </p>

            <div class="overflow-x-auto">
                <table class="tabla tabla-responsiva">
                    <caption class="sr-only">Productos del catálogo</caption>
                    <thead>
                        <tr>
                            <th scope="col">Producto</th>
                            <th scope="col">Categoría</th>
                            <th scope="col" class="num">Precio</th>
                            <th scope="col" class="num">Stock</th>
                            <th scope="col"><span class="sr-only">Acciones</span></th>
                        </tr>
                    </thead>
                    <tbody class="entrada-escalonada">
                    <% int indice = 0;
                       for (Map<String, Object> f : filas) {
                           int stock = (Integer) f.get("stock");
                           String nombre = (String) f.get("nombre");
                           String img = (String) f.get("imagen"); %>
                        <tr style="--i: <%= indice++ %>">
                            <td data-etiqueta="" class="!text-left">
                                <div class="flex items-center gap-3">
                                    <span class="marco-img grid size-11 shrink-0 place-items-center overflow-hidden rounded-lg bg-stone-100"
                                          <%= img != null && !img.isEmpty() ? "data-cargando" : "" %>>
                                        <% if (img != null && !img.isEmpty()) { %>
                                            <img src="<%= Html.esc(util.Imagenes.url(img)) %>"
                                                 alt="" class="img-progresiva size-full object-contain p-1"
                                                 loading="lazy" width="44" height="44">
                                        <% } else { %>
                                            <ui:icono n="image" clase="text-stone-400"/>
                                        <% } %>
                                    </span>
                                    <span class="min-w-0">
                                        <span class="block font-medium text-stone-900">
                                            <%= Html.esc(nombre) %>
                                        </span>
                                        <span class="block text-xs text-stone-500">
                                            <%= Html.esc(f.get("unidad")) %>
                                        </span>
                                    </span>
                                </div>
                            </td>
                            <td data-etiqueta="Categoría" class="text-stone-700">
                                <%= Html.esc(f.get("categoria")) %>
                            </td>
                            <td data-etiqueta="Precio" class="num">
                                <%= Html.soles((Double) f.get("precio")) %>
                            </td>
                            <td data-etiqueta="Stock" class="num">
                                <% if (stock <= 0) { %>
                                    <span class="estado estado-alerta">Agotado</span>
                                <% } else if (stock <= 5) { %>
                                    <span class="font-semibold text-amber-800"><%= stock %></span>
                                    <span class="sr-only"> (poco stock)</span>
                                <% } else { %>
                                    <%= stock %>
                                <% } %>
                            </td>
                            <td data-etiqueta="" class="whitespace-nowrap">
                                <div class="flex justify-end gap-1">
                                    <a href="<%= ctx %>/jsp-Productos/EditarProducto.jsp?id=<%= f.get("id") %>"
                                       class="btn btn-fantasma btn-sm">
                                        <ui:icono n="edit" clase="size-4"/>Editar
                                        <span class="sr-only"><%= Html.esc(nombre) %></span>
                                    </a>

                                    <form method="post" action="<%= base %>"
                                          data-confirmar="Se quitará «<%= Html.esc(nombre) %>» de la tienda. Esta acción no se puede deshacer."
                                          data-confirmar-titulo="¿Eliminar este producto?"
                                          data-confirmar-boton="Eliminar"
                                          data-confirmar-tono="peligro">
                                        <input type="hidden" name="tienda" value="<%= tiendaId %>">
                                        <input type="hidden" name="accion" value="eliminar">
                                        <input type="hidden" name="id" value="<%= f.get("id") %>">
                                        <input type="hidden" name="nombre" value="<%= Html.esc(nombre) %>">
                                        <input type="hidden" name="filtros" value="<%= Html.esc(filtrosActuales) %>">
                                        <button type="submit" class="btn btn-peligro-suave btn-sm" data-sin-carga>
                                            <ui:icono n="delete" clase="size-4"/>Eliminar
                                            <span class="sr-only"><%= Html.esc(nombre) %></span>
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        <% } %>
    </section>

    <dialog id="dlg-producto" class="dialogo dialogo-grande"
            aria-labelledby="dlg-producto-titulo"
            <%= reabrir ? "data-abrir-al-cargar" : "" %>>
        <form method="post" action="<%= base %>" data-validar>
            <input type="hidden" name="tienda" value="<%= tiendaId %>">
            <input type="hidden" name="accion" value="agregar">
            <input type="hidden" name="filtros" value="<%= Html.esc(filtrosActuales) %>">

            <div class="flex items-start justify-between gap-4 border-b border-stone-200 px-6 py-4">
                <div>
                    <h2 id="dlg-producto-titulo" class="text-lg font-semibold text-stone-900">Nuevo producto</h2>
                    <p class="text-sm text-stone-600">Aparecerá en tu tienda en cuanto lo guardes.</p>
                </div>
                <button type="button" class="btn btn-fantasma btn-sm btn-solo-icono -mr-2"
                        data-cerrar-dialogo aria-label="Cerrar">
                    <ui:icono n="close"/>
                </button>
            </div>

            <div class="max-h-[65vh] overflow-y-auto px-6 py-5">
                <%@ include file="/WEB-INF/jspf/producto-campos.jspf" %>
            </div>

            <div class="flex flex-col-reverse gap-2 border-t border-stone-200 bg-stone-50 px-6 py-4 sm:flex-row sm:justify-end">
                <button type="button" class="btn btn-secundario" data-cerrar-dialogo>
                    Cancelar
                </button>
                <button type="submit" class="btn btn-primario" data-cargando="Guardando…">
                    <span class="btn-icono"><ui:icono n="check"/></span>
                    <ui:icono n="progress_activity" clase="btn-spinner"/>
                    <span class="btn-texto">Guardar producto</span>
                </button>
            </div>
        </form>
    </dialog>

<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
