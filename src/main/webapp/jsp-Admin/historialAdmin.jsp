<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Html" %>
<%!
    static final Map<String, String[]> ACCIONES = new LinkedHashMap<>();
    static {
        ACCIONES.put("AGREGAR", new String[]{"Producto agregado", "add", "estado-ok"});
        ACCIONES.put("EDITAR", new String[]{"Producto editado", "edit", "estado-neutro"});
        ACCIONES.put("ELIMINAR", new String[]{"Producto eliminado", "delete", "estado-alerta"});
    }

    static String iconoCambio(String c) {
        if (c.startsWith("Precio")) return "sell";
        if (c.startsWith("Stock")) return "inventory_2";
        if (c.startsWith("Imagen")) return "image";
        if (c.startsWith("Categor")) return "category";
        if (c.startsWith("Unidad")) return "local_drink";
        return "edit";
    }
    static final int POR_PAGINA = 30;
%>
<%
    String tiendaId = (String) session.getAttribute("adminTiendaId");
    String titulo = "Actividad";
    String seccion = "actividad";
    String accion = request.getParameter("accion");
    if (accion != null && !ACCIONES.containsKey(accion)) accion = null;
    String buscar = Html.param(request, "buscar");
    int pagina = 1;
    try { pagina = Math.max(1, Integer.parseInt(request.getParameter("pagina"))); } catch (Exception ignorada) { }

    List<Map<String, Object>> eventos = new ArrayList<>();
    Set<Integer> existentes = new HashSet<>();
    int total = 0;
    boolean errorDatos = false;
    try (Connection con = util.Conexion.getConnection()) {
        StringBuilder where = new StringBuilder(" WHERE tabla_afectada = 'productos' AND tienda_id = ?");
        List<Object> params = new ArrayList<>();
        params.add(tiendaId);
        if (accion != null) { where.append(" AND accion = ?"); params.add(accion); }
        if (buscar != null) { where.append(" AND detalles ILIKE ?"); params.add("%" + buscar.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%"); }
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM historial_admin" + where)) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) { rs.next(); total = rs.getInt(1); }
        }
        try (PreparedStatement ps = con.prepareStatement("SELECT * FROM historial_admin" + where + " ORDER BY fecha DESC, id DESC LIMIT ? OFFSET ?")) {
            int i = 0;
            for (; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            ps.setInt(i + 1, POR_PAGINA);
            ps.setInt(i + 2, (pagina - 1) * POR_PAGINA);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> e = new HashMap<>();
                    e.put("fecha", rs.getTimestamp("fecha"));
                    e.put("accion", rs.getString("accion"));
                    e.put("id", rs.getInt("id_afectado"));
                    e.put("detalles", rs.getString("detalles"));
                    e.put("usuario", rs.getString("usuario_admin"));
                    eventos.add(e);
                }
            }
        }
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery("SELECT id FROM productos WHERE tienda_id = '" + tiendaId + "'")) {
            while (rs.next()) existentes.add(rs.getInt(1));
        }
    } catch (Exception e) {
        log("Error al cargar la actividad", e);
        errorDatos = true;
    }
    int paginas = Math.max(1, (total + POR_PAGINA - 1) / POR_PAGINA);
    String base = ctx + "/jsp-Admin/historialAdmin.jsp";
    String filtrosQ = (accion != null ? "&accion=" + accion : "") + (buscar != null ? "&buscar=" + java.net.URLEncoder.encode(buscar, "UTF-8") : "");
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
    <h1 class="text-2xl font-semibold tracking-tight text-stone-900">Actividad</h1>
    <p class="mt-1 text-sm text-stone-600">Altas, cambios y bajas de productos. Se registran automáticamente.</p>

    <div class="mt-6 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <nav class="segmentos self-start" aria-label="Tipo de acción">
            <a href="<%= base %><%= buscar != null ? "?buscar=" + java.net.URLEncoder.encode(buscar, "UTF-8") : "" %>" <%= accion == null ? "aria-current=\"page\"" : "" %>>Todas</a>
            <% for (Map.Entry<String, String[]> a : ACCIONES.entrySet()) { %>
            <a href="<%= base %>?accion=<%= a.getKey() %><%= buscar != null ? "&buscar=" + java.net.URLEncoder.encode(buscar, "UTF-8") : "" %>" <%= a.getKey().equals(accion) ? "aria-current=\"page\"" : "" %>><%= a.getValue()[0].replace("Producto ", "") %></a>
            <% } %>
        </nav>
        <form method="get" action="<%= base %>" class="flex gap-2" role="search">
            <% if (accion != null) { %><input type="hidden" name="accion" value="<%= accion %>"><% } %>
            <label for="f-buscar" class="sr-only">Buscar en la actividad</label>
            <div class="entrada-icono md:w-72"><ui:icono n="search"/><input id="f-buscar" type="search" name="buscar" value="<%= Html.esc(buscar) %>" class="entrada" placeholder="Buscar producto o cambio" data-atajo-buscar></div>
            <button type="submit" class="btn btn-secundario" data-sin-carga>Buscar</button>
        </form>
    </div>

    <% if (errorDatos) { %>
    <div class="aviso aviso-error mt-6" role="alert"><ui:icono n="error"/><div><p class="font-medium">No pudimos cargar la actividad.</p><a class="btn btn-secundario btn-sm mt-2" href="<%= base %>"><ui:icono n="restart_alt" clase="size-4"/>Reintentar</a></div></div>
    <% } else if (eventos.isEmpty()) { %>
    <div class="mt-6 flex flex-col items-center rounded-2xl border border-dashed border-stone-300 bg-white px-6 py-14 text-center">
        <span class="grid size-12 place-items-center rounded-full bg-stone-100 text-stone-500"><ui:icono n="history" clase="size-6"/></span>
        <p class="mt-3 font-medium text-stone-900">No hay actividad<%= accion != null || buscar != null ? " con estos filtros" : "" %>.</p>
        <% if (accion != null || buscar != null) { %><a href="<%= base %>" class="btn btn-secundario mt-4">Ver toda la actividad</a><% } %>
    </div>
    <% } else { %>
    <ol class="entrada-escalonada tarjeta mt-6 divide-y divide-stone-100">
        <% int indice = 0;
           for (Map<String, Object> e : eventos) {
               String[] a = ACCIONES.getOrDefault((String) e.get("accion"), new String[]{(String) e.get("accion"), "info", "estado-neutro"});
               String detalles = (String) e.get("detalles");
               int idProducto = (Integer) e.get("id");
               String usuario = (String) e.get("usuario");
               if ("postgres".equals(usuario)) usuario = "Registro automático"; %>
        <li class="flex gap-4 p-4 sm:p-5" style="--i: <%= indice++ %>">
            <span class="grid size-9 shrink-0 place-items-center rounded-full bg-stone-100 text-stone-600"><ui:icono n="<%= a[1] %>" clase="size-4"/></span>
            <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
                    <p class="font-medium text-stone-900"><%= a[0] %></p>
                    <time class="text-xs text-stone-500" datetime="<%= e.get("fecha") %>"><%= Html.fechaHora((Timestamp) e.get("fecha")) %></time>
                </div>
                <% if (detalles != null && !detalles.trim().isEmpty()) { %>
                <ul class="mt-2 space-y-1">
                    <% for (String cambio : detalles.split("\\|")) { if (cambio.trim().isEmpty()) continue; %>
                    <li class="flex items-start gap-2 text-sm text-stone-700"><ui:icono n="<%= iconoCambio(cambio.trim()) %>" clase="mt-0.5 size-4 text-stone-400"/><span class="break-words"><%= Html.esc(cambio.trim()) %></span></li>
                    <% } %>
                </ul>
                <% } %>
                <p class="mt-2 flex flex-wrap items-center gap-x-3 text-xs text-stone-500">
                    <span><%= Html.esc(usuario) %></span>
                    <% if (existentes.contains(idProducto)) { %><a class="font-medium text-marca-800 hover:underline" href="<%= ctx %>/jsp-Productos/EditarProducto.jsp?id=<%= idProducto %>">Abrir producto</a><% } else { %><span>Producto #<%= idProducto %> (ya no existe)</span><% } %>
                </p>
            </div>
        </li>
        <% } %>
    </ol>

    <nav class="mt-4 flex items-center justify-between gap-3 text-sm" aria-label="Paginación">
        <p class="text-stone-600">Página <%= pagina %> de <%= paginas %> · <%= total %> registros</p>
        <div class="flex gap-2">
            <% if (pagina > 1) { %><a class="btn btn-secundario btn-sm" href="<%= base %>?pagina=<%= pagina - 1 %><%= filtrosQ %>" rel="prev"><ui:icono n="chevron_left" clase="size-4"/>Anterior</a><% } %>
            <% if (pagina < paginas) { %><a class="btn btn-secundario btn-sm" href="<%= base %>?pagina=<%= pagina + 1 %><%= filtrosQ %>" rel="next">Siguiente<ui:icono n="chevron_right" clase="size-4"/></a><% } %>
        </div>
    </nav>
    <% } %>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
