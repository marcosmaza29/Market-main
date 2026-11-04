<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Html" %>
<%
    String tiendaId = (String) session.getAttribute("adminTiendaId");
    String periodo = request.getParameter("periodo");
    if (periodo == null) periodo = request.getParameter("filtro"); // enlaces antiguos
    if (!Arrays.asList("hoy", "semana", "mes", "rango", "todos").contains(periodo)) periodo = "mes";
    String desde = Html.param(request, "desde");
    String hasta = Html.param(request, "hasta");
    if (desde != null && !desde.matches("\\d{4}-\\d{2}-\\d{2}")) desde = null;
    if (hasta != null && !hasta.matches("\\d{4}-\\d{2}-\\d{2}")) hasta = null;
    if ("rango".equals(periodo) && desde == null && hasta == null) periodo = "mes";
    String cliente = Html.param(request, "cliente");

    StringBuilder where = new StringBuilder(" WHERE tienda_id = ?");
    List<Object> params = new ArrayList<>();
    params.add(tiendaId);
    switch (periodo) {
        case "hoy": where.append(" AND CAST(fecha AS DATE) = CURRENT_DATE"); break;
        case "semana": where.append(" AND date_trunc('week', fecha) = date_trunc('week', CURRENT_DATE)"); break;
        case "mes": where.append(" AND date_trunc('month', fecha) = date_trunc('month', CURRENT_DATE)"); break;
        case "rango":
            if (desde != null) { where.append(" AND fecha >= CAST(? AS date)"); params.add(desde); }
            if (hasta != null) { where.append(" AND fecha < CAST(? AS date) + 1"); params.add(hasta); }
            break;
        default: break;
    }
    if (cliente != null) { where.append(" AND correo_usuario ILIKE ?"); params.add("%" + cliente.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%"); }

    // ---------- Exportar CSV ----------
    if ("csv".equals(request.getParameter("formato"))) {
        response.setContentType("text/csv;charset=UTF-8");
        response.setHeader("Content-Disposition", "attachment; filename=\"ventas-" + periodo + ".csv\"");
        java.io.PrintWriter w = response.getWriter();
        w.write('﻿'); // BOM para que Excel reconozca UTF-8
        w.println("Fecha;Cliente;Producto;Unidad;Precio;Cantidad;Subtotal");
        try (Connection conn = util.Conexion.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT fecha, correo_usuario, producto, unidad, precio, cantidad, subtotal FROM historial_compras" + where + " ORDER BY fecha DESC")) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String[] c = {Html.fechaHora(rs.getTimestamp(1)), rs.getString(2), rs.getString(3), rs.getString(4),
                            String.format(Locale.US, "%.2f", rs.getDouble(5)), rs.getString(6), String.format(Locale.US, "%.2f", rs.getDouble(7))};
                    StringBuilder linea = new StringBuilder();
                    for (int i = 0; i < c.length; i++) {
                        String v = c[i] == null ? "" : c[i];
                        if (v.matches("^[=+\\-@].*")) v = "'" + v; // evita fórmulas al abrir en Excel
                        linea.append(i == 0 ? "" : ";").append('"').append(v.replace("\"", "\"\"")).append('"');
                    }
                    w.println(linea);
                }
            }
        }
        return;
    }

    String titulo = "Ventas";
    String seccion = "ventas";
    List<Map<String, Object>> filas = new ArrayList<>();
    double totalVentas = 0;
    int unidades = 0, compras = 0;
    boolean errorDatos = false;
    try (Connection conn = util.Conexion.getConnection()) {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COALESCE(SUM(subtotal), 0), COALESCE(SUM(cantidad), 0), COUNT(DISTINCT (correo_usuario, fecha)) FROM historial_compras" + where)) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) { rs.next(); totalVentas = rs.getDouble(1); unidades = rs.getInt(2); compras = rs.getInt(3); }
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT correo_usuario, producto, precio, cantidad, unidad, subtotal, fecha FROM historial_compras" + where + " ORDER BY fecha DESC LIMIT 300")) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new HashMap<>();
                    f.put("cliente", rs.getString("correo_usuario"));
                    f.put("producto", rs.getString("producto"));
                    f.put("unidad", rs.getString("unidad"));
                    f.put("precio", rs.getDouble("precio"));
                    f.put("cantidad", rs.getInt("cantidad"));
                    f.put("subtotal", rs.getDouble("subtotal"));
                    f.put("fecha", rs.getTimestamp("fecha"));
                    filas.add(f);
                }
            }
        }
    } catch (Exception e) {
        log("Error al consultar ventas", e);
        errorDatos = true;
    }
    String base = ctx + "/jsp-Admin/ventasAdmin.jsp";
    String qCliente = cliente != null ? "&cliente=" + java.net.URLEncoder.encode(cliente, "UTF-8") : "";
    String qActual = request.getQueryString() == null ? "" : request.getQueryString().replaceAll("&?formato=[^&]*", "");
    String[][] periodos = {{"hoy", "Hoy"}, {"semana", "Esta semana"}, {"mes", "Este mes"}, {"todos", "Todo"}};
    String nombrePeriodo = "rango".equals(periodo) ? "Del " + (desde != null ? desde : "inicio") + " al " + (hasta != null ? hasta : "hoy") : null;
    for (String[] p : periodos) if (p[0].equals(periodo)) nombrePeriodo = p[1];
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
    <div class="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
            <h1 class="text-2xl font-semibold tracking-tight text-stone-900">Ventas</h1>
            <p class="mt-1 text-sm text-stone-600">Compras hechas por los clientes en la tienda en línea.</p>
        </div>
        <a href="<%= base %>?<%= Html.esc(qActual) %><%= qActual.isEmpty() ? "" : "&amp;" %>formato=csv" class="btn btn-secundario"><ui:icono n="download"/>Exportar CSV</a>
    </div>

    <div class="mt-6 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <nav class="segmentos self-start overflow-x-auto" aria-label="Periodo">
            <% for (String[] p : periodos) { %><a href="<%= base %>?periodo=<%= p[0] %><%= qCliente %>" <%= p[0].equals(periodo) ? "aria-current=\"page\"" : "" %>><%= p[1] %></a><% } %>
        </nav>
        <form method="get" action="<%= base %>" class="flex flex-wrap items-end gap-2">
            <input type="hidden" name="periodo" value="rango">
            <% if (cliente != null) { %><input type="hidden" name="cliente" value="<%= Html.esc(cliente) %>"><% } %>
            <div class="campo"><label for="f-desde" class="text-xs font-medium text-stone-600">Desde</label><input id="f-desde" type="date" name="desde" value="<%= desde == null ? "" : desde %>" class="entrada h-9 w-40"></div>
            <div class="campo"><label for="f-hasta" class="text-xs font-medium text-stone-600">Hasta</label><input id="f-hasta" type="date" name="hasta" value="<%= hasta == null ? "" : hasta %>" class="entrada h-9 w-40"></div>
            <button type="submit" class="btn btn-secundario h-9" data-sin-carga><ui:icono n="date_range" clase="size-4"/>Aplicar rango</button>
        </form>
    </div>

    <% if (errorDatos) { %>
    <div class="aviso aviso-error mt-6" role="alert"><ui:icono n="error"/><div><p class="font-medium">No pudimos consultar las ventas.</p><a class="btn btn-secundario btn-sm mt-2" href="<%= base %>"><ui:icono n="restart_alt" clase="size-4"/>Reintentar</a></div></div>
    <% } else { %>
    <section aria-label="Resumen del periodo: <%= Html.esc(nombrePeriodo) %>" class="mt-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <div class="tarjeta p-4"><p class="text-sm text-stone-600">Total vendido</p><p class="mt-1 text-2xl font-semibold tabular-nums text-stone-900"><%= Html.soles(totalVentas) %></p></div>
        <div class="tarjeta p-4"><p class="text-sm text-stone-600">Compras</p><p class="mt-1 text-2xl font-semibold tabular-nums text-stone-900"><%= compras %></p></div>
        <div class="tarjeta p-4"><p class="text-sm text-stone-600">Unidades vendidas</p><p class="mt-1 text-2xl font-semibold tabular-nums text-stone-900"><%= unidades %></p></div>
        <div class="tarjeta p-4"><p class="text-sm text-stone-600">Ticket promedio</p><p class="mt-1 text-2xl font-semibold tabular-nums text-stone-900"><%= compras > 0 ? Html.soles(totalVentas / compras) : "—" %></p></div>
    </section>

    <section class="tarjeta mt-6" aria-labelledby="h-detalle">
        <div class="flex flex-col gap-3 border-b border-stone-200 p-4 sm:flex-row sm:items-center sm:justify-between">
            <h2 id="h-detalle" class="font-semibold text-stone-900">Detalle · <span class="font-normal text-stone-600"><%= Html.esc(nombrePeriodo) %></span></h2>
            <form method="get" action="<%= base %>" class="flex gap-2" role="search">
                <input type="hidden" name="periodo" value="<%= periodo %>">
                <% if (desde != null) { %><input type="hidden" name="desde" value="<%= desde %>"><% } %>
                <% if (hasta != null) { %><input type="hidden" name="hasta" value="<%= hasta %>"><% } %>
                <label for="f-cliente" class="sr-only">Buscar cliente por correo</label>
                <div class="entrada-icono sm:w-64"><ui:icono n="search"/><input id="f-cliente" type="search" name="cliente" value="<%= Html.esc(cliente) %>" class="entrada h-9" placeholder="Correo del cliente" data-atajo-buscar></div>
                <button type="submit" class="btn btn-secundario h-9" data-sin-carga>Buscar</button>
                <% if (cliente != null) { %><a href="<%= base %>?periodo=<%= periodo %>" class="btn btn-fantasma h-9" aria-label="Quitar búsqueda de cliente"><ui:icono n="close" clase="size-4"/></a><% } %>
            </form>
        </div>
        <% if (filas.isEmpty()) { %>
        <div class="flex flex-col items-center px-6 py-14 text-center">
            <span class="grid size-12 place-items-center rounded-full bg-stone-100 text-stone-500"><ui:icono n="point_of_sale" clase="size-6"/></span>
            <p class="mt-3 font-medium text-stone-900">No hay ventas en este periodo<%= cliente != null ? " para ese cliente" : "" %>.</p>
            <a href="<%= base %>?periodo=todos" class="btn btn-secundario mt-4">Ver todas las ventas</a>
        </div>
        <% } else { %>
        <div class="overflow-x-auto">
            <table class="tabla tabla-responsiva">
                <caption class="sr-only">Ventas: <%= Html.esc(nombrePeriodo) %></caption>
                <thead><tr><th scope="col">Fecha</th><th scope="col">Cliente</th><th scope="col">Producto</th><th scope="col" class="num">Precio</th><th scope="col" class="num">Cant.</th><th scope="col" class="num">Subtotal</th></tr></thead>
                <tbody>
                <% for (Map<String, Object> f : filas) { %>
                <tr>
                    <td data-etiqueta="Fecha" class="whitespace-nowrap text-stone-600"><%= Html.fechaHora((Timestamp) f.get("fecha")) %></td>
                    <td data-etiqueta="Cliente" class="break-all"><a class="hover:underline" href="<%= base %>?periodo=<%= periodo %>&amp;cliente=<%= java.net.URLEncoder.encode((String) f.get("cliente"), "UTF-8") %>" title="Ver solo este cliente"><%= Html.esc(f.get("cliente")) %></a></td>
                    <td data-etiqueta="Producto"><%= Html.esc(f.get("producto")) %><span class="block text-xs text-stone-500"><%= Html.esc(f.get("unidad")) %></span></td>
                    <td data-etiqueta="Precio" class="num"><%= Html.soles((Double) f.get("precio")) %></td>
                    <td data-etiqueta="Cant." class="num"><%= f.get("cantidad") %></td>
                    <td data-etiqueta="Subtotal" class="num font-medium"><%= Html.soles((Double) f.get("subtotal")) %></td>
                </tr>
                <% } %>
                </tbody>
            </table>
        </div>
        <% if (filas.size() == 300) { %><p class="border-t border-stone-200 px-4 py-3 text-xs text-stone-500">Se muestran las 300 ventas más recientes. Exporta a CSV para ver todas.</p><% } %>
        <% } %>
    </section>
    <% } %>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
