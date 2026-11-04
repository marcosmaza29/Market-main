<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Html, util.Flash, util.ProductoForm" %>
<%
    // Validar sesión del administrador y su tienda
    String admin = (String) session.getAttribute("adminUsuario");
    String tiendaId = (String) session.getAttribute("adminTiendaId");

    boolean tiendaValida =
        "market".equals(tiendaId) ||
        "juguetes".equals(tiendaId) ||
        "cosmeticos".equals(tiendaId);

    if (admin == null || admin.trim().isEmpty() || !tiendaValida) {
        response.sendRedirect(ctx + "/jsp-Admin/loginAdmin.jsp");
        return;
    }

    // Impedir que se solicite otra tienda mediante la URL
    String tiendaSolicitada = request.getParameter("tienda");

    if (tiendaSolicitada != null && !tiendaId.equals(tiendaSolicitada)) {
        response.sendError(
            HttpServletResponse.SC_FORBIDDEN,
            "No tienes permiso para acceder a esta tienda."
        );
        return;
    }

    // Obtener y validar el ID del producto
    int id;

    try {
        id = Integer.parseInt(request.getParameter("id"));

        if (id <= 0) {
            throw new NumberFormatException();
        }
    } catch (Exception e) {
        Flash.error(session, "No indicaste qué producto editar.");
        response.sendRedirect(
            ctx + "/jsp-Productos/producto.jsp?tienda=" + tiendaId
        );
        return;
    }

    // Procesar formulario de edición
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        ProductoForm f = ProductoForm.leer(request, tiendaId);

        if (f.campoError != null) {
            Flash.formulario(
                session,
                request.getParameterMap(),
                f.campoError,
                f.mensajeError
            );

            response.sendRedirect(
                ctx + "/jsp-Productos/EditarProducto.jsp?id="
                + id + "&tienda=" + tiendaId
            );
            return;
        }

        try (Connection conn = util.Conexion.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "UPDATE productos SET nombre=?, descripcion=?, precio=?, " +
                 "stock=?, unidad=?, imagen_url=?, categoria=? " +
                 "WHERE id=? AND tienda_id=?")) {

            ps.setString(1, f.nombre);
            ps.setString(
                2,
                f.descripcion.isEmpty() ? null : f.descripcion
            );
            ps.setDouble(3, f.precio);
            ps.setInt(4, f.stock);
            ps.setString(5, f.unidadCompleta());
            ps.setString(6, f.imagen.isEmpty() ? null : f.imagen);
            ps.setString(7, f.categoria);
            ps.setInt(8, id);
            ps.setString(9, tiendaId);

            int filasActualizadas = ps.executeUpdate();

            if (filasActualizadas == 0) {
                Flash.error(
                    session,
                    "No encontramos ese producto en tu tienda."
                );
            } else {
                Flash.exito(
                    session,
                    "Guardaste los cambios de «" + f.nombre + "»."
                );
            }

            response.sendRedirect(
                ctx + "/jsp-Productos/producto.jsp?tienda=" + tiendaId
            );

        } catch (Exception e) {
            log("Error al actualizar producto", e);

            Flash.error(
                session,
                "No pudimos guardar los cambios. Inténtalo de nuevo."
            );

            Flash.formulario(session, request.getParameterMap(), null);

            response.sendRedirect(
                ctx + "/jsp-Productos/EditarProducto.jsp?id="
                + id + "&tienda=" + tiendaId
            );
        }

        return;
    }

    // Preparar los datos para mostrar el formulario
    String titulo = "Editar producto";
    String seccion = "productos";

    Map<String, String> pf = new HashMap<>(Flash.formulario(session));
    String pfError = pf.get("__error");
    String pfMsg = pf.get("__mensaje");
    String nombreOriginal = null;

    // Buscar exclusivamente un producto de la tienda autenticada
    try (Connection conn = util.Conexion.getConnection();
         PreparedStatement ps = conn.prepareStatement(
             "SELECT * FROM productos WHERE id = ? AND tienda_id = ?")) {

        ps.setInt(1, id);
        ps.setString(2, tiendaId);

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                nombreOriginal = rs.getString("nombre");

                if (!pf.containsKey("nombre")) {
                    String u = rs.getString("unidad") == null
                        ? "" : rs.getString("unidad").trim();

                    int sp = u.indexOf(' ');

                    pf.put("nombre", rs.getString("nombre"));
                    pf.put("descripcion", rs.getString("descripcion"));
                    pf.put(
                        "precio",
                        String.format(Locale.US, "%.2f", rs.getDouble("precio"))
                    );
                    pf.put("stock", String.valueOf(rs.getInt("stock")));
                    pf.put("cantidad", sp > 0 ? u.substring(0, sp) : "1");
                    pf.put("unidad", sp > 0 ? u.substring(sp + 1) : u);
                    pf.put("categoria", rs.getString("categoria"));
                    pf.put("imagen", rs.getString("imagen_url"));
                }
            }
        }

    } catch (Exception e) {
        log("Error al cargar producto", e);
        Flash.error(session, "No pudimos cargar el producto.");

        response.sendRedirect(
            ctx + "/jsp-Productos/producto.jsp?tienda=" + tiendaId
        );
        return;
    }

    // Bloquear productos inexistentes o pertenecientes a otra tienda
    if (nombreOriginal == null) {
        Flash.error(
            session,
            "No encontramos ese producto en tu tienda."
        );

        response.sendRedirect(
            ctx + "/jsp-Productos/producto.jsp?tienda=" + tiendaId
        );
        return;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/jspf/head.jspf" %>
</head>

<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>

    <nav aria-label="Ruta de navegación"
         class="text-sm text-stone-600">
        <ol class="flex items-center gap-1.5">
            <li>
                <a href="<%= ctx %>/jsp-Productos/producto.jsp?tienda=<%= tiendaId %>"
                   class="hover:text-stone-900 hover:underline">
                    Productos
                </a>
            </li>

            <li aria-hidden="true">
                <ui:icono n="chevron_right" clase="size-4 text-stone-400"/>
            </li>

            <li aria-current="page"
                class="truncate font-medium text-stone-900">
                <%= Html.esc(nombreOriginal) %>
            </li>
        </ol>
    </nav>

    <h1 class="mt-3 text-2xl font-semibold tracking-tight text-stone-900">
        Editar producto
    </h1>

    <p class="mt-1 text-sm text-stone-600">
        Los cambios se ven en la tienda al guardar y quedan registrados en «Actividad».
    </p>

    <form method="post"
          action="<%= ctx %>/jsp-Productos/EditarProducto.jsp?id=<%= id %>&tienda=<%= tiendaId %>"
          class="tarjeta mt-6 max-w-3xl"
          data-validar
          data-avisar-cambios>

        <div class="tarjeta-cuerpo">
            <%@ include file="/WEB-INF/jspf/producto-campos.jspf" %>
        </div>

        <div class="flex flex-col-reverse gap-3 border-t border-stone-200 bg-stone-50 px-4 py-4 sm:flex-row sm:items-center sm:justify-end sm:px-6">

            <p class="text-sm text-amber-800 sm:mr-auto"
               data-indicador-cambios
               hidden>
                Tienes cambios sin guardar.
            </p>

            <a href="<%= ctx %>/jsp-Productos/producto.jsp?tienda=<%= tiendaId %>"
               class="btn btn-secundario">
                Cancelar
            </a>

            <button type="submit"
                    class="btn btn-primario"
                    data-cargando="Guardando…">

                <span class="btn-icono">
                    <ui:icono n="check"/>
                </span>

                <ui:icono n="progress_activity" clase="btn-spinner"/>

                <span class="btn-texto">
                    Guardar cambios
                </span>
            </button>
        </div>
    </form>

<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
