<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Html, util.Flash, util.ProveedorForm" %>
<%
    String tiendaId = (String) session.getAttribute("adminTiendaId");
    int id;
    try {
        id = Integer.parseInt(request.getParameter("id"));
    } catch (Exception e) {
        Flash.error(session, "No indicaste qué proveedor editar.");
        response.sendRedirect(ctx + "/jsp-Proveedores/Proveedores.jsp");
        return;
    }
    String urlEditar = ctx + "/jsp-Proveedores/editarProveedor.jsp?id=" + id;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        ProveedorForm f = ProveedorForm.leer(request);
        if (f.campoError != null) {
            Flash.formulario(session, request.getParameterMap(), f.campoError, f.mensajeError);
            response.sendRedirect(urlEditar);
            return;
        }
        try (Connection con = util.Conexion.getConnection()) {
            int filas;
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE proveedores SET nombre=?, ruc=?, contacto=?, telefono=?, direccion=?, tipo=? WHERE id=? AND tienda_id=?")) {
                ps.setString(1, f.nombre);
                ps.setString(2, f.ruc);
                ps.setString(3, f.contacto);
                ps.setString(4, f.telefono.isEmpty() ? null : f.telefono);
                ps.setString(5, f.direccion.isEmpty() ? null : f.direccion);
                ps.setString(6, f.tipo);
                ps.setInt(7, id);
                ps.setString(8, tiendaId);
                filas = ps.executeUpdate();
            }
            if (filas == 0) {
                Flash.error(session, "Ese proveedor ya no existe.");
            } else {
                ProveedorForm.registrar(con, (String) session.getAttribute("adminUsuario"), tiendaId, "EDITAR", id, "Datos actualizados: " + f.nombre);
                Flash.exito(session, "Guardaste los cambios de «" + f.nombre + "».");
            }
            response.sendRedirect(ctx + "/jsp-Proveedores/Proveedores.jsp");
        } catch (SQLException e) {
            if ("23505".equals(e.getSQLState())) {
                Flash.formulario(session, request.getParameterMap(), "ruc", "Ese RUC ya pertenece a otro proveedor.");
            } else {
                log("Error al editar proveedor", e);
                Flash.error(session, "No pudimos guardar los cambios. Inténtalo de nuevo.");
                Flash.formulario(session, request.getParameterMap(), null);
            }
            response.sendRedirect(urlEditar);
        }
        return;
    }

    String titulo = "Editar proveedor";
    String seccion = "proveedores";
    Map<String, String> pv = new HashMap<>(Flash.formulario(session));
    String pvError = pv.get("__error");
    String pvMsg = pv.get("__mensaje");
    String nombreOriginal = null;
    try (Connection con = util.Conexion.getConnection();
         PreparedStatement ps = con.prepareStatement("SELECT * FROM proveedores WHERE id = ? AND tienda_id = ?")) {
        ps.setInt(1, id);
        ps.setString(2, tiendaId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                nombreOriginal = rs.getString("nombre");
                if (!pv.containsKey("nombre")) {
                    for (String c : new String[]{"nombre", "ruc", "contacto", "telefono", "direccion", "tipo"}) pv.put(c, rs.getString(c));
                }
            }
        }
    } catch (Exception e) {
        log("Error al cargar proveedor", e);
    }
    if (nombreOriginal == null) {
        Flash.error(session, "No encontramos ese proveedor.");
        response.sendRedirect(ctx + "/jsp-Proveedores/Proveedores.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
    <nav aria-label="Ruta de navegación" class="text-sm text-stone-600">
        <ol class="flex items-center gap-1.5">
            <li><a href="<%= ctx %>/jsp-Proveedores/Proveedores.jsp" class="hover:text-stone-900 hover:underline">Proveedores</a></li>
            <li aria-hidden="true"><ui:icono n="chevron_right" clase="size-4 text-stone-400"/></li>
            <li aria-current="page" class="truncate font-medium text-stone-900"><%= Html.esc(nombreOriginal) %></li>
        </ol>
    </nav>
    <h1 class="mt-3 text-2xl font-semibold tracking-tight text-stone-900">Editar proveedor</h1>
    <p class="mt-1 text-sm text-stone-600">Los cambios quedan registrados en el historial del proveedor.</p>

    <form method="post" action="<%= urlEditar %>" class="tarjeta mt-6 max-w-3xl" data-validar data-avisar-cambios>
        <div class="tarjeta-cuerpo"><%@ include file="/WEB-INF/jspf/proveedor-campos.jspf" %></div>
        <div class="flex flex-col-reverse gap-3 border-t border-stone-200 bg-stone-50 px-4 py-4 sm:flex-row sm:items-center sm:justify-end sm:px-6">
            <p class="text-sm text-amber-800 sm:mr-auto" data-indicador-cambios hidden>Tienes cambios sin guardar.</p>
            <a href="<%= ctx %>/jsp-Proveedores/Proveedores.jsp" class="btn btn-secundario">Cancelar</a>
            <button type="submit" class="btn btn-primario" data-cargando="Guardando…">
                <span class="btn-icono"><ui:icono n="check"/></span><ui:icono n="progress_activity" clase="btn-spinner"/><span class="btn-texto">Guardar cambios</span>
            </button>
        </div>
    </form>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
