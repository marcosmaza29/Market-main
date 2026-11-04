<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Html, util.Flash, util.ProveedorForm" %>
<%
    String admin = (String) session.getAttribute("adminUsuario");
    String tiendaId = (String) session.getAttribute("adminTiendaId");
    String base = ctx + "/jsp-Proveedores/Proveedores.jsp";

    // ---------- Desactivar / reactivar (con deshacer) ----------
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String accion = request.getParameter("accion");
        try (Connection con = util.Conexion.getConnection()) {
            int id = Integer.parseInt(request.getParameter("id"));
            boolean activar = "reactivar".equals(accion);
            String nombre = null;
            try (PreparedStatement ps = con.prepareStatement("UPDATE proveedores SET activo = ? WHERE id = ? AND tienda_id = ? RETURNING nombre")) {
                ps.setBoolean(1, activar);
                ps.setInt(2, id);
                ps.setString(3, tiendaId);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) nombre = rs.getString(1); }
            }
            if (nombre == null) {
                Flash.error(session, "Ese proveedor ya no existe.");
            } else {
                ProveedorForm.registrar(con, admin, tiendaId, activar ? "REACTIVAR" : "DESACTIVAR", id, (activar ? "Proveedor reactivado: " : "Proveedor desactivado: ") + nombre);
                if (activar) {
                    Flash.exito(session, "Reactivaste a «" + nombre + "».");
                } else {
                    Flash.exito(session, "Desactivaste a «" + nombre + "». Ya no aparecerá al registrar compras.",
                            "Deshacer", base + "?accion=reactivar&id=" + id);
                }
            }
        } catch (Exception e) {
            log("Error al cambiar el estado del proveedor", e);
            Flash.error(session, "No pudimos actualizar el proveedor. Inténtalo de nuevo.");
        }
        response.sendRedirect(base + ("reactivar".equals(accion) && "inactivos".equals(request.getParameter("ver")) ? "?ver=inactivos" : ""));
        return;
    }

    String titulo = "Proveedores";
    String seccion = "proveedores";
    boolean verInactivos = "inactivos".equals(request.getParameter("ver"));
    List<Map<String, Object>> proveedores = new ArrayList<>();
    List<Map<String, Object>> compras = new ArrayList<>();
    int activos = 0, inactivos = 0;
    boolean errorDatos = false;
    try (Connection con = util.Conexion.getConnection()) {
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FILTER (WHERE activo), COUNT(*) FILTER (WHERE NOT activo) FROM proveedores WHERE tienda_id = '" + tiendaId + "'")) {
            rs.next(); activos = rs.getInt(1); inactivos = rs.getInt(2);
        }
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT p.*, (SELECT MAX(fecha_registro) FROM compras_proveedores c WHERE c.proveedor_id = p.id AND c.tienda_id = p.tienda_id) AS ultima_compra "
                + "FROM proveedores p WHERE activo = ? AND p.tienda_id = ? ORDER BY nombre")) {
            ps.setBoolean(1, !verInactivos);
            ps.setString(2, tiendaId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> p = new HashMap<>();
                    for (String c : new String[]{"nombre", "ruc", "contacto", "telefono", "tipo"}) p.put(c, rs.getString(c));
                    p.put("id", rs.getInt("id"));
                    p.put("ultima", rs.getTimestamp("ultima_compra"));
                    proveedores.add(p);
                }
            }
        }
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery("SELECT cp.fecha_registro, cp.cantidad, cp.precio_unitario, p.nombre AS proveedor, pr.nombre AS producto "
                     + "FROM compras_proveedores cp JOIN proveedores p ON cp.proveedor_id = p.id JOIN productos pr ON cp.producto_id = pr.id "
                     + "WHERE cp.tienda_id = '" + tiendaId + "' ORDER BY cp.fecha_registro DESC LIMIT 5")) {
            while (rs.next()) {
                Map<String, Object> c = new HashMap<>();
                c.put("fecha", rs.getTimestamp("fecha_registro"));
                c.put("cantidad", rs.getInt("cantidad"));
                c.put("precio", rs.getDouble("precio_unitario"));
                c.put("proveedor", rs.getString("proveedor"));
                c.put("producto", rs.getString("producto"));
                compras.add(c);
            }
        }
    } catch (Exception e) {
        log("Error al cargar proveedores", e);
        errorDatos = true;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
    <div class="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
            <h1 class="text-2xl font-semibold tracking-tight text-stone-900">Proveedores</h1>
            <p class="mt-1 text-sm text-stone-600">Empresas a las que compras mercadería. Al registrar una compra, el stock se suma solo.</p>
        </div>
        <div class="flex flex-wrap gap-2">
            <a href="<%= ctx %>/jsp-Proveedores/comprasProveedor.jsp" class="btn btn-secundario"><ui:icono n="add_business"/>Registrar compra</a>
            <a href="<%= ctx %>/jsp-Proveedores/nuevoProveedor.jsp" class="btn btn-primario"><ui:icono n="add"/>Nuevo proveedor</a>
        </div>
    </div>

    <nav class="segmentos mt-6" aria-label="Estado de los proveedores">
        <a href="<%= base %>" <%= !verInactivos ? "aria-current=\"page\"" : "" %>>Activos <span class="tabular-nums text-stone-500"><%= activos %></span></a>
        <a href="<%= base %>?ver=inactivos" <%= verInactivos ? "aria-current=\"page\"" : "" %>>Desactivados <span class="tabular-nums text-stone-500"><%= inactivos %></span></a>
    </nav>

    <% if (errorDatos) { %>
    <div class="aviso aviso-error mt-6" role="alert"><ui:icono n="error"/><div><p class="font-medium">No pudimos cargar los proveedores.</p><a class="btn btn-secundario btn-sm mt-2" href="<%= base %>"><ui:icono n="restart_alt" clase="size-4"/>Reintentar</a></div></div>
    <% } else if (proveedores.isEmpty()) { %>
    <div class="mt-6 flex flex-col items-center rounded-2xl border border-dashed border-stone-300 bg-white px-6 py-14 text-center">
        <span class="grid size-12 place-items-center rounded-full bg-stone-100 text-stone-500"><ui:icono n="local_shipping" clase="size-6"/></span>
        <p class="mt-3 font-medium text-stone-900"><%= verInactivos ? "No hay proveedores desactivados." : "Aún no registras proveedores." %></p>
        <% if (!verInactivos) { %><a href="<%= ctx %>/jsp-Proveedores/nuevoProveedor.jsp" class="btn btn-primario mt-4"><ui:icono n="add"/>Nuevo proveedor</a><% } %>
    </div>
    <% } else { %>
    <ul class="entrada-escalonada mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-3" role="list">
        <% int indice = 0;
           for (Map<String, Object> p : proveedores) {
               String nombre = (String) p.get("nombre");
               String tel = (String) p.get("telefono");
               Timestamp ultima = (Timestamp) p.get("ultima"); %>
        <li class="tarjeta flex flex-col transition-shadow duration-200 hover:shadow-md" style="--i: <%= indice++ %>">
            <div class="flex-1 p-5">
                <div class="flex items-start justify-between gap-3">
                    <h2 class="font-semibold text-stone-900"><%= Html.esc(nombre) %></h2>
                    <span class="shrink-0 text-xs text-stone-500"><%= Html.esc(p.get("tipo")) %></span>
                </div>
                <dl class="mt-3 space-y-1.5 text-sm">
                    <div class="flex items-center gap-2 text-stone-700"><dt><ui:icono n="person" clase="size-4 text-stone-400" etiqueta="Contacto"/></dt><dd><%= Html.esc(p.get("contacto")) %></dd></div>
                    <div class="flex items-center gap-2 text-stone-700"><dt><ui:icono n="call" clase="size-4 text-stone-400" etiqueta="Teléfono"/></dt>
                        <dd><% if (tel != null && !tel.isEmpty()) { %><a class="hover:underline" href="tel:<%= Html.esc(tel.replaceAll("[^+0-9]", "")) %>"><%= Html.esc(tel) %></a><% } else { %><span class="text-stone-400">Sin teléfono</span><% } %></dd></div>
                    <div class="flex items-center gap-2 text-stone-700"><dt><ui:icono n="badge" clase="size-4 text-stone-400" etiqueta="RUC"/></dt><dd class="tabular-nums">RUC <%= Html.esc(p.get("ruc")) %></dd></div>
                </dl>
                <p class="mt-3 text-xs text-stone-500"><%= ultima != null ? "Última compra: " + Html.fecha(ultima) : "Sin compras registradas" %></p>
            </div>
            <div class="flex flex-wrap items-center gap-1 border-t border-stone-200 px-3 py-2">
                <% if (!verInactivos) { %>
                <a href="<%= ctx %>/jsp-Proveedores/comprasProveedor.jsp?proveedor=<%= p.get("id") %>" class="btn btn-fantasma btn-sm"><ui:icono n="add_business" clase="size-4"/>Compra</a>
                <a href="<%= ctx %>/jsp-Proveedores/editarProveedor.jsp?id=<%= p.get("id") %>" class="btn btn-fantasma btn-sm"><ui:icono n="edit" clase="size-4"/>Editar</a>
                <a href="<%= ctx %>/jsp-Proveedores/historialProveedor.jsp?id=<%= p.get("id") %>" class="btn btn-fantasma btn-sm"><ui:icono n="history" clase="size-4"/>Historial</a>
                <form method="post" action="<%= base %>" class="ml-auto" data-confirmar="«<%= Html.esc(nombre) %>» dejará de aparecer al registrar compras. Su historial se conserva y podrás reactivarlo cuando quieras." data-confirmar-titulo="¿Desactivar este proveedor?" data-confirmar-boton="Desactivar" data-confirmar-tono="peligro">
                    <input type="hidden" name="accion" value="desactivar"><input type="hidden" name="id" value="<%= p.get("id") %>">
                    <button type="submit" class="btn btn-peligro-suave btn-sm" data-sin-carga>Desactivar<span class="sr-only"> <%= Html.esc(nombre) %></span></button>
                </form>
                <% } else { %>
                <a href="<%= ctx %>/jsp-Proveedores/historialProveedor.jsp?id=<%= p.get("id") %>" class="btn btn-fantasma btn-sm"><ui:icono n="history" clase="size-4"/>Historial</a>
                <form method="post" action="<%= base %>?ver=inactivos" class="ml-auto">
                    <input type="hidden" name="accion" value="reactivar"><input type="hidden" name="id" value="<%= p.get("id") %>">
                    <button type="submit" class="btn btn-secundario btn-sm" data-sin-carga><ui:icono n="undo" clase="size-4"/>Reactivar<span class="sr-only"> <%= Html.esc(nombre) %></span></button>
                </form>
                <% } %>
            </div>
        </li>
        <% } %>
    </ul>
    <% } %>

    <section class="tarjeta mt-8" aria-labelledby="h-compras">
        <div class="flex items-center justify-between gap-3 border-b border-stone-200 px-4 py-3 sm:px-5">
            <h2 id="h-compras" class="font-semibold text-stone-900">Últimas compras</h2>
            <a href="<%= ctx %>/jsp-Proveedores/historialProveedor.jsp" class="text-sm font-medium text-marca-800 hover:underline">Ver historial completo</a>
        </div>
        <% if (compras.isEmpty()) { %>
        <p class="px-5 py-8 text-center text-sm text-stone-600">Todavía no registras compras a proveedores.</p>
        <% } else { %>
        <div class="overflow-x-auto">
            <table class="tabla tabla-responsiva">
                <thead><tr><th scope="col">Fecha</th><th scope="col">Proveedor</th><th scope="col">Producto</th><th scope="col" class="num">Cantidad</th><th scope="col" class="num">Precio unit.</th><th scope="col" class="num">Total</th></tr></thead>
                <tbody>
                <% for (Map<String, Object> c : compras) { %>
                <tr>
                    <td data-etiqueta="Fecha" class="whitespace-nowrap text-stone-600"><%= Html.fechaHora((Timestamp) c.get("fecha")) %></td>
                    <td data-etiqueta="Proveedor"><%= Html.esc(c.get("proveedor")) %></td>
                    <td data-etiqueta="Producto"><%= Html.esc(c.get("producto")) %></td>
                    <td data-etiqueta="Cantidad" class="num"><%= c.get("cantidad") %></td>
                    <td data-etiqueta="Precio unit." class="num"><%= Html.soles((Double) c.get("precio")) %></td>
                    <td data-etiqueta="Total" class="num font-medium"><%= Html.soles((Integer) c.get("cantidad") * (Double) c.get("precio")) %></td>
                </tr>
                <% } %>
                </tbody>
            </table>
        </div>
        <% } %>
    </section>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
