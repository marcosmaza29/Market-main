<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Html" %>
<%!
    // Nombres de acción en lenguaje claro (las claves vienen de la base y de los triggers)
    static final Map<String, String[]> ACCIONES = new LinkedHashMap<>();
    static {
        ACCIONES.put("COMPRA_PROV", new String[]{"Compra registrada", "add_business"});
        ACCIONES.put("AGREGAR", new String[]{"Proveedor registrado", "add"});
        ACCIONES.put("EDITAR", new String[]{"Datos editados", "edit"});
        ACCIONES.put("DESACTIVAR", new String[]{"Proveedor desactivado", "remove_shopping_cart"});
        ACCIONES.put("REACTIVAR", new String[]{"Proveedor reactivado", "undo"});
    }
%>
<%
    String tiendaId = (String) session.getAttribute("adminTiendaId");
    String titulo = "Historial de proveedores";
    String seccion = "proveedores";
    Integer proveedorId = null;
    try { proveedorId = Integer.valueOf(request.getParameter("id")); } catch (Exception ignorada) { }
    String accion = request.getParameter("accion");
    if (accion != null && !ACCIONES.containsKey(accion)) accion = null;
    String desde = Html.param(request, "desde");
    String hasta = Html.param(request, "hasta");
    if (desde != null && !desde.matches("\\d{4}-\\d{2}-\\d{2}")) desde = null;
    if (hasta != null && !hasta.matches("\\d{4}-\\d{2}-\\d{2}")) hasta = null;
    boolean hayFiltros = proveedorId != null || accion != null || desde != null || hasta != null;

    List<String[]> proveedores = new ArrayList<>();
    List<Map<String, Object>> eventos = new ArrayList<>();
    String nombreProveedor = null;
    boolean errorDatos = false;
    try (Connection con = util.Conexion.getConnection()) {
        try (PreparedStatement st = con.prepareStatement("SELECT id, nombre, activo FROM proveedores WHERE tienda_id = ? ORDER BY nombre")) {
            st.setString(1, tiendaId);
            try (ResultSet rs = st.executeQuery()) {
            while (rs.next()) {
                proveedores.add(new String[]{rs.getString("id"), rs.getString("nombre") + (rs.getBoolean("activo") ? "" : " (desactivado)")});
                if (proveedorId != null && proveedorId == rs.getInt("id")) nombreProveedor = rs.getString("nombre");
            }
        }
        }
        StringBuilder sql = new StringBuilder(
                "SELECT h.fecha, h.accion, h.detalles, h.usuario_admin, COALESCE(pd.nombre, pc.nombre) AS proveedor "
                + "FROM historial_admin h "
                + "LEFT JOIN proveedores pd ON h.tabla_afectada = 'proveedores' AND pd.id = h.id_afectado "
                + "LEFT JOIN compras_proveedores c ON h.tabla_afectada = 'compras_proveedores' AND c.id = h.id_afectado "
                + "LEFT JOIN proveedores pc ON pc.id = c.proveedor_id "
                + "WHERE h.tienda_id = ? AND h.tabla_afectada IN ('proveedores', 'compras_proveedores')");
        List<Object> params = new ArrayList<>();
        params.add(tiendaId);
        if (proveedorId != null) { sql.append(" AND COALESCE(pd.id, pc.id) = ?"); params.add(proveedorId); }
        if (accion != null) { sql.append(" AND h.accion = ?"); params.add(accion); }
        if (desde != null) { sql.append(" AND h.fecha >= CAST(? AS date)"); params.add(desde); }
        if (hasta != null) { sql.append(" AND h.fecha < CAST(? AS date) + 1"); params.add(hasta); }
        sql.append(" ORDER BY h.fecha DESC LIMIT 200");
        try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> e = new HashMap<>();
                    e.put("fecha", rs.getTimestamp("fecha"));
                    e.put("accion", rs.getString("accion"));
                    e.put("detalles", rs.getString("detalles"));
                    e.put("usuario", rs.getString("usuario_admin"));
                    e.put("proveedor", rs.getString("proveedor"));
                    eventos.add(e);
                }
            }
        }
    } catch (Exception e) {
        log("Error al cargar el historial de proveedores", e);
        errorDatos = true;
    }
    String base = ctx + "/jsp-Proveedores/historialProveedor.jsp";
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
    <nav aria-label="Ruta de navegación" class="text-sm text-stone-600">
        <ol class="flex items-center gap-1.5">
            <li><a href="<%= ctx %>/jsp-Proveedores/Proveedores.jsp" class="hover:text-stone-900 hover:underline">Proveedores</a></li>
            <li aria-hidden="true"><ui:icono n="chevron_right" clase="size-4 text-stone-400"/></li>
            <li aria-current="page" class="font-medium text-stone-900">Historial</li>
        </ol>
    </nav>
    <h1 class="mt-3 text-2xl font-semibold tracking-tight text-stone-900"><%= nombreProveedor != null ? "Historial de " + Html.esc(nombreProveedor) : "Historial de proveedores" %></h1>
    <p class="mt-1 text-sm text-stone-600">Compras, altas y cambios, del más reciente al más antiguo.</p>

    <form method="get" action="<%= base %>" class="tarjeta mt-6 grid gap-4 p-4 sm:grid-cols-2 lg:grid-cols-[1.4fr_1fr_1fr_1fr_auto] lg:items-end">
        <div class="campo">
            <label for="f-prov" class="etiqueta">Proveedor</label>
            <select id="f-prov" name="id" class="entrada" data-auto-enviar>
                <option value="">Todos</option>
                <% for (String[] p : proveedores) { %><option value="<%= p[0] %>" <%= proveedorId != null && p[0].equals(String.valueOf(proveedorId)) ? "selected" : "" %>><%= Html.esc(p[1]) %></option><% } %>
            </select>
        </div>
        <div class="campo">
            <label for="f-accion" class="etiqueta">Tipo</label>
            <select id="f-accion" name="accion" class="entrada" data-auto-enviar>
                <option value="">Todos</option>
                <% for (Map.Entry<String, String[]> a : ACCIONES.entrySet()) { %><option value="<%= a.getKey() %>" <%= a.getKey().equals(accion) ? "selected" : "" %>><%= a.getValue()[0] %></option><% } %>
            </select>
        </div>
        <div class="campo">
            <label for="f-desde" class="etiqueta">Desde</label>
            <input id="f-desde" type="date" name="desde" value="<%= desde == null ? "" : desde %>" class="entrada" data-auto-enviar>
        </div>
        <div class="campo">
            <label for="f-hasta" class="etiqueta">Hasta</label>
            <input id="f-hasta" type="date" name="hasta" value="<%= hasta == null ? "" : hasta %>" class="entrada" data-auto-enviar>
        </div>
        <div class="flex gap-2">
            <noscript><button type="submit" class="btn btn-secundario">Filtrar</button></noscript>
            <% if (hayFiltros) { %><a href="<%= base %>" class="btn btn-fantasma"><ui:icono n="filter_alt_off"/>Limpiar</a><% } %>
        </div>
    </form>

    <% if (errorDatos) { %>
    <div class="aviso aviso-error mt-6" role="alert"><ui:icono n="error"/><div><p class="font-medium">No pudimos cargar el historial.</p><a class="btn btn-secundario btn-sm mt-2" href="<%= base %>"><ui:icono n="restart_alt" clase="size-4"/>Reintentar</a></div></div>
    <% } else if (eventos.isEmpty()) { %>
    <div class="mt-6 flex flex-col items-center rounded-2xl border border-dashed border-stone-300 bg-white px-6 py-14 text-center">
        <span class="grid size-12 place-items-center rounded-full bg-stone-100 text-stone-500"><ui:icono n="history" clase="size-6"/></span>
        <p class="mt-3 font-medium text-stone-900">No hay movimientos<%= hayFiltros ? " con estos filtros" : " todavía" %>.</p>
        <% if (hayFiltros) { %><a href="<%= base %>" class="btn btn-secundario mt-4">Limpiar filtros</a><% } %>
    </div>
    <% } else { %>
    <ol class="mt-6 space-y-6">
        <% String diaActual = null;
           for (int i = 0; i < eventos.size(); i++) {
               Map<String, Object> e = eventos.get(i);
               Timestamp f = (Timestamp) e.get("fecha");
               String dia = Html.fechaLarga(f);
               String[] a = ACCIONES.getOrDefault((String) e.get("accion"), new String[]{(String) e.get("accion"), "info"});
               String usuario = (String) e.get("usuario");
               if ("postgres".equals(usuario)) usuario = "Registro automático";
               if (!dia.equals(diaActual)) {
                   if (diaActual != null) { %></ol></li><% }
                   diaActual = dia; %>
        <li>
            <h2 class="text-sm font-semibold text-stone-500 first-letter:uppercase"><%= dia %></h2>
            <ol class="tarjeta mt-2 divide-y divide-stone-100">
        <%     } %>
                <li class="flex gap-4 p-4">
                    <span class="grid size-9 shrink-0 place-items-center rounded-full bg-stone-100 text-stone-600"><ui:icono n="<%= a[1] %>" clase="size-4"/></span>
                    <div class="min-w-0 flex-1">
                        <p class="text-sm"><span class="font-medium text-stone-900"><%= a[0] %></span><% if (nombreProveedor == null && e.get("proveedor") != null) { %> · <span class="text-stone-700"><%= Html.esc(e.get("proveedor")) %></span><% } %></p>
                        <% if (e.get("detalles") != null) { %><p class="mt-0.5 text-sm break-words text-stone-600"><%= Html.esc(((String) e.get("detalles")).replace(" | ", " · ")) %></p><% } %>
                        <p class="mt-1 text-xs text-stone-500"><%= Html.hora(f) %> · <%= Html.esc(usuario) %></p>
                    </div>
                </li>
        <% } %>
            </ol>
        </li>
    </ol>
    <p class="mt-4 text-xs text-stone-500">Se muestran hasta 200 movimientos. Usa los filtros para acotar.</p>
    <% } %>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
