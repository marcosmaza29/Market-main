<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Html, util.Flash" %>
<%!
    static final class Linea {
        String producto, unidad;
        double precio, subtotal;
        int cantidad;
    }
    static final class Compra {
        Timestamp fecha;
        double total;
        int unidades;
        List<Linea> lineas = new ArrayList<>();
    }
%>
<%
    String correoCliente = (String) session.getAttribute("correoCliente");
    if (correoCliente == null) {
        Flash.info(session, "Inicia sesión para ver tus compras.");
        response.sendRedirect(ctx + "/jsp-Usuarios/login.jsp?volver=" + java.net.URLEncoder.encode("/jsp-Interfaz/historial.jsp", "UTF-8"));
        return;
    }
    String titulo = "Mis compras";

    // Cada compra registra varias filas con la misma fecha: se agrupan por fecha exacta
    List<Compra> compras = new ArrayList<>();
    boolean errorDatos = false;
    double totalGastado = 0;
    try (Connection con = util.Conexion.getConnection();
         PreparedStatement ps = con.prepareStatement(
                 "SELECT producto, precio, cantidad, unidad, subtotal, fecha FROM historial_compras WHERE lower(correo_usuario) = lower(?) AND tienda_id = ? ORDER BY fecha DESC, id")) {
        ps.setString(1, correoCliente);
        ps.setString(2, contextoTienda);
        try (ResultSet rs = ps.executeQuery()) {
            Compra actual = null;
            while (rs.next()) {
                Timestamp f = rs.getTimestamp("fecha");
                if (actual == null || !Objects.equals(actual.fecha, f)) {
                    actual = new Compra();
                    actual.fecha = f;
                    compras.add(actual);
                }
                Linea l = new Linea();
                l.producto = rs.getString("producto");
                l.unidad = rs.getString("unidad");
                l.precio = rs.getDouble("precio");
                l.cantidad = rs.getInt("cantidad");
                l.subtotal = rs.getDouble("subtotal");
                actual.lineas.add(l);
                actual.total += l.subtotal;
                actual.unidades += l.cantidad;
                totalGastado += l.subtotal;
            }
        }
    } catch (Exception e) {
        log("No se pudo cargar el historial del cliente", e);
        errorDatos = true;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<body class="min-h-dvh">
<%@ include file="/WEB-INF/jspf/tienda-header.jspf" %>

<main id="contenido" class="contenedor max-w-4xl pt-8">
    <div class="flex flex-wrap items-end justify-between gap-3">
        <div>
            <h1 class="text-2xl font-semibold tracking-tight text-stone-900">Mis compras</h1>
            <% if (!compras.isEmpty()) { %>
            <p class="mt-1 text-sm text-stone-600"><%= Html.plural(compras.size(), "compra", "compras") %> · <%= Html.soles(totalGastado) %> en total</p>
            <% } %>
        </div>
        <a href="<%= ctx %>/jsp-Interfaz/interfaz.jsp" class="btn btn-secundario"><ui:icono n="storefront"/>Seguir comprando</a>
    </div>

    <% if (errorDatos) { %>
    <div class="aviso aviso-error mt-6" role="alert">
        <ui:icono n="error"/>
        <div><p class="font-medium">No pudimos cargar tus compras.</p><p class="mt-1">Inténtalo de nuevo en unos segundos.</p>
            <a href="<%= ctx %>/jsp-Interfaz/historial.jsp" class="btn btn-secundario btn-sm mt-3"><ui:icono n="restart_alt" clase="size-4"/>Reintentar</a></div>
    </div>
    <% } else if (compras.isEmpty()) { %>
    <div class="mt-8 flex flex-col items-center rounded-2xl border border-dashed border-stone-300 bg-white px-6 py-16 text-center">
        <span class="grid size-12 place-items-center rounded-full bg-stone-100 text-stone-500"><ui:icono n="receipt_long" clase="size-6"/></span>
        <h2 class="mt-4 text-base font-semibold text-stone-900">Todavía no tienes compras</h2>
        <p class="mt-1 max-w-sm text-sm text-stone-600">Cuando confirmes una compra aparecerá aquí con su detalle, para que la consultes cuando quieras.</p>
        <a href="<%= ctx %>/jsp-Interfaz/interfaz.jsp" class="btn btn-primario mt-5">Explorar productos</a>
    </div>
    <% } else { %>
    <ol class="mt-6 space-y-3" aria-label="Compras, de la más reciente a la más antigua">
        <% for (int i = 0; i < compras.size(); i++) {
               Compra c = compras.get(i); %>
        <li>
            <details class="group tarjeta overflow-hidden" <%= i == 0 ? "open" : "" %>>
                <summary class="flex cursor-pointer list-none items-center gap-4 p-4 transition-colors hover:bg-stone-50 sm:p-5 [&::-webkit-details-marker]:hidden">
                    <span class="grid size-10 shrink-0 place-items-center rounded-lg bg-stone-100 text-stone-600"><ui:icono n="shopping_bag"/></span>
                    <span class="min-w-0 flex-1">
                        <span class="block font-medium text-stone-900 first-letter:uppercase"><%= Html.fechaLarga(c.fecha) %></span>
                        <span class="block text-sm text-stone-600"><%= Html.hora(c.fecha) %> · <%= Html.plural(c.unidades, "unidad", "unidades") %></span>
                    </span>
                    <span class="font-semibold tabular-nums text-stone-900"><%= Html.soles(c.total) %></span>
                    <ui:icono n="expand_more" clase="text-stone-500 transition-transform duration-200 group-open:rotate-180"/>
                    <span class="sr-only">Ver detalle</span>
                </summary>
                <div class="border-t border-stone-200">
                    <table class="tabla tabla-responsiva">
                        <caption class="sr-only">Productos de la compra del <%= Html.fechaHora(c.fecha) %></caption>
                        <thead><tr><th scope="col">Producto</th><th scope="col" class="num">Precio</th><th scope="col" class="num">Cantidad</th><th scope="col" class="num">Subtotal</th></tr></thead>
                        <tbody>
                        <% for (Linea l : c.lineas) { %>
                        <tr>
                            <td data-etiqueta="Producto" class="text-stone-900"><%= Html.esc(l.producto) %><% if (l.unidad != null && !l.unidad.isEmpty()) { %><span class="block text-xs text-stone-500"><%= Html.esc(l.unidad) %></span><% } %></td>
                            <td data-etiqueta="Precio" class="num"><%= Html.soles(l.precio) %></td>
                            <td data-etiqueta="Cantidad" class="num"><%= l.cantidad %></td>
                            <td data-etiqueta="Subtotal" class="num font-medium"><%= Html.soles(l.subtotal) %></td>
                        </tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </details>
        </li>
        <% } %>
    </ol>
    <% } %>
</main>

<%@ include file="/WEB-INF/jspf/tienda-footer.jspf" %>
<%@ include file="/WEB-INF/jspf/fin.jspf" %>
</body>
</html>
