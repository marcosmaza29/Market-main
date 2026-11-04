<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Flash, util.ProveedorForm" %>
<%
    String tiendaId = (String) session.getAttribute("adminTiendaId");
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        ProveedorForm f = ProveedorForm.leer(request);
        if (f.campoError != null) {
            Flash.formulario(session, request.getParameterMap(), f.campoError, f.mensajeError);
            response.sendRedirect(ctx + "/jsp-Proveedores/nuevoProveedor.jsp");
            return;
        }
        try (Connection con = util.Conexion.getConnection()) {
            int id;
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO proveedores (nombre, ruc, contacto, telefono, direccion, tipo, tienda_id) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id")) {
                ps.setString(1, f.nombre);
                ps.setString(2, f.ruc);
                ps.setString(3, f.contacto);
                ps.setString(4, f.telefono.isEmpty() ? null : f.telefono);
                ps.setString(5, f.direccion.isEmpty() ? null : f.direccion);
                ps.setString(6, f.tipo);
                ps.setString(7, tiendaId);
                try (ResultSet rs = ps.executeQuery()) { rs.next(); id = rs.getInt(1); }
            }
            ProveedorForm.registrar(con, (String) session.getAttribute("adminUsuario"), tiendaId, "AGREGAR", id, "Proveedor registrado: " + f.nombre + " | RUC: " + f.ruc);
            Flash.exito(session, "Registraste a «" + f.nombre + "».");
            response.sendRedirect(ctx + "/jsp-Proveedores/Proveedores.jsp");
        } catch (SQLException e) {
            if ("23505".equals(e.getSQLState())) {
                Flash.formulario(session, request.getParameterMap(), "ruc", "Ya existe un proveedor con ese RUC. Búscalo en la lista (también entre los desactivados).");
            } else {
                log("Error al registrar proveedor", e);
                Flash.error(session, "No pudimos guardar el proveedor. Inténtalo de nuevo.");
                Flash.formulario(session, request.getParameterMap(), null);
            }
            response.sendRedirect(ctx + "/jsp-Proveedores/nuevoProveedor.jsp");
        }
        return;
    }

    String titulo = "Nuevo proveedor";
    String seccion = "proveedores";
    Map<String, String> pv = Flash.formulario(session);
    String pvError = pv.get("__error");
    String pvMsg = pv.get("__mensaje");
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
    <nav aria-label="Ruta de navegación" class="text-sm text-stone-600">
        <ol class="flex items-center gap-1.5">
            <li><a href="<%= ctx %>/jsp-Proveedores/Proveedores.jsp" class="hover:text-stone-900 hover:underline">Proveedores</a></li>
            <li aria-hidden="true"><ui:icono n="chevron_right" clase="size-4 text-stone-400"/></li>
            <li aria-current="page" class="font-medium text-stone-900">Nuevo</li>
        </ol>
    </nav>
    <h1 class="mt-3 text-2xl font-semibold tracking-tight text-stone-900">Nuevo proveedor</h1>
    <p class="mt-1 text-sm text-stone-600">Los campos sin «(opcional)» son obligatorios.</p>

    <form method="post" action="<%= ctx %>/jsp-Proveedores/nuevoProveedor.jsp" class="tarjeta mt-6 max-w-3xl" data-validar data-avisar-cambios>
        <div class="tarjeta-cuerpo"><%@ include file="/WEB-INF/jspf/proveedor-campos.jspf" %></div>
        <div class="flex flex-col-reverse gap-3 border-t border-stone-200 bg-stone-50 px-4 py-4 sm:flex-row sm:justify-end sm:px-6">
            <a href="<%= ctx %>/jsp-Proveedores/Proveedores.jsp" class="btn btn-secundario">Cancelar</a>
            <button type="submit" class="btn btn-primario" data-cargando="Guardando…">
                <span class="btn-icono"><ui:icono n="check"/></span><ui:icono n="progress_activity" clase="btn-spinner"/><span class="btn-texto">Guardar proveedor</span>
            </button>
        </div>
    </form>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
