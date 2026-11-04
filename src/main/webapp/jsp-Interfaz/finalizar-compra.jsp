<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, modelo.CarritoItem, util.Html, util.Flash" %>
<%
    String correoCliente = (String) session.getAttribute("correoCliente");
    if (correoCliente == null || correoCliente.isEmpty()) {
        Flash.info(session, "Inicia sesión para completar tu compra. Tu carrito se mantiene.");
        response.sendRedirect(ctx + "/jsp-Usuarios/login.jsp?volver=" + java.net.URLEncoder.encode("/jsp-Interfaz/carrito.jsp", "UTF-8"));
        return;
    }

    // ---------- POST: registrar la compra y redirigir (evita compras duplicadas al recargar) ----------
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        List<CarritoItem> carrito = (List<CarritoItem>) session.getAttribute("carrito");
        if (carrito == null || carrito.isEmpty()) {
            Flash.info(session, "Tu carrito está vacío.");
            response.sendRedirect(ctx + "/jsp-Interfaz/carrito.jsp");
            return;
        }
        String problema = null;
        double total = 0;
        Connection conn = null;
        try {
            conn = util.Conexion.getConnection();
            conn.setAutoCommit(false);
            // Descuento atómico: solo se actualiza si todavía hay stock suficiente
            try (PreparedStatement ps = conn.prepareStatement("UPDATE productos SET stock = stock - ? WHERE id = ? AND stock >= ? AND tienda_id = ?")) {
                for (CarritoItem item : carrito) {
                    ps.setInt(1, item.getCantidad());
                    ps.setInt(2, item.getId());
                    ps.setInt(3, item.getCantidad());
                    ps.setString(4, (String) session.getAttribute("tiendaId"));
                    if (ps.executeUpdate() == 0) {
                        problema = "Ya no hay suficiente stock de «" + item.getNombre() + "». Ajusta la cantidad e inténtalo otra vez.";
                        break;
                    }
                }
            }
            if (problema == null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO historial_compras (correo_usuario, producto, precio, cantidad, unidad, subtotal, fecha, usuario_id, producto_id, tienda_id) VALUES (?, ?, ?, ?, ?, ?, NOW(), ?, ?, ?)")) {
                    Integer usuarioId = (Integer) session.getAttribute("usuarioId");
                    for (CarritoItem item : carrito) {
                        ps.setString(1, correoCliente.toLowerCase());
                        ps.setString(2, item.getNombre());
                        ps.setDouble(3, item.getPrecio());
                        ps.setInt(4, item.getCantidad());
                        ps.setString(5, item.getUnidad() == null ? "" : item.getUnidad());
                        ps.setDouble(6, item.getSubtotal());
                        if (usuarioId != null) ps.setInt(7, usuarioId); else ps.setNull(7, Types.INTEGER);
                        ps.setInt(8, item.getId());
                        ps.setString(9, (String) session.getAttribute("tiendaId"));
                        ps.executeUpdate();
                        total += item.getSubtotal();
                    }
                }
                conn.commit();
            } else {
                conn.rollback();
            }
        } catch (Exception e) {
            log("Error al finalizar la compra", e);
            if (conn != null) try { conn.rollback(); } catch (SQLException ignorada) { }
            problema = "No pudimos registrar tu compra por un problema de conexión. No se descontó ningún producto; inténtalo de nuevo.";
        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException ignorada) { }
        }

        if (problema != null) {
            Flash.error(session, problema);
            response.sendRedirect(ctx + "/jsp-Interfaz/carrito.jsp");
            return;
        }
        Map<String, Object> compra = new HashMap<>();
        compra.put("items", new ArrayList<>(carrito));
        compra.put("total", total);
        compra.put("fecha", new java.util.Date());
        session.setAttribute("ultima_compra", compra);
        session.setAttribute("carrito_final", new ArrayList<>(carrito)); // usado por /generar-boleta
        session.removeAttribute("carrito");
        response.sendRedirect(ctx + "/jsp-Interfaz/finalizar-compra.jsp");
        return;
    }

    // ---------- GET: mostrar la boleta de la última compra ----------
    Map<String, Object> compra = (Map<String, Object>) session.getAttribute("ultima_compra");
    if (compra == null) {
        response.sendRedirect(ctx + "/jsp-Interfaz/carrito.jsp");
        return;
    }
    List<CarritoItem> items = (List<CarritoItem>) compra.get("items");
    double total = (Double) compra.get("total");
    java.util.Date fecha = (java.util.Date) compra.get("fecha");
    String titulo = "Compra realizada";
    int pasoActual = 3;
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<body class="min-h-dvh">
<%@ include file="/WEB-INF/jspf/tienda-header.jspf" %>

<main id="contenido" class="contenedor max-w-3xl pt-8">
    <%@ include file="/WEB-INF/jspf/pasos-compra.jspf" %>

    <section class="tarjeta mt-6 overflow-hidden" aria-labelledby="titulo-compra">
        <div class="flex flex-col items-center border-b border-stone-200 px-6 py-8 text-center">
            <span class="grid size-14 place-items-center rounded-full bg-green-50 text-green-700 ring-8 ring-green-50/60 motion-safe:animate-aparecer">
                <ui:icono n="check_circle" clase="size-8"/>
            </span>
            <h1 id="titulo-compra" class="mt-4 text-2xl font-semibold tracking-tight text-stone-900">¡Compra realizada!</h1>
            <p class="mt-1 text-sm text-stone-600">Registramos tu compra el <%= Html.fechaLarga(fecha) %> a las <%= Html.hora(fecha) %>.</p>
        </div>

        <dl class="grid gap-4 px-6 py-5 text-sm sm:grid-cols-2">
            <div><dt class="text-stone-500">Cliente</dt><dd class="mt-0.5 font-medium text-stone-900"><%= Html.esc(hdrNombre) %></dd></div>
            <div><dt class="text-stone-500">Correo</dt><dd class="mt-0.5 font-medium break-all text-stone-900"><%= Html.esc(correoCliente) %></dd></div>
        </dl>

        <div class="border-t border-stone-200">
            <table class="tabla tabla-responsiva">
                <caption class="sr-only">Detalle de la compra</caption>
                <thead><tr><th scope="col">Producto</th><th scope="col" class="num">Precio</th><th scope="col" class="num">Cantidad</th><th scope="col" class="num">Subtotal</th></tr></thead>
                <tbody>
                <% for (CarritoItem it : items) { %>
                <tr>
                    <td data-etiqueta="Producto" class="font-medium text-stone-900"><%= Html.esc(it.getNombre()) %><% if (it.getUnidad() != null) { %><span class="block text-xs font-normal text-stone-500"><%= Html.esc(it.getUnidad()) %></span><% } %></td>
                    <td data-etiqueta="Precio" class="num"><%= Html.soles(it.getPrecio()) %></td>
                    <td data-etiqueta="Cantidad" class="num"><%= it.getCantidad() %></td>
                    <td data-etiqueta="Subtotal" class="num font-medium"><%= Html.soles(it.getSubtotal()) %></td>
                </tr>
                <% } %>
                </tbody>
            </table>
        </div>
        <div class="flex items-center justify-between border-t border-stone-200 bg-stone-50 px-6 py-4">
            <span class="text-sm font-medium text-stone-700">Total</span>
            <span class="text-xl font-semibold tabular-nums text-stone-900"><%= Html.soles(total) %></span>
        </div>
    </section>

    <div class="mt-6 flex flex-col gap-2 sm:flex-row">
        <a href="<%= ctx %>/generar-boleta" class="btn btn-primario btn-lg" target="_blank" rel="noopener">
            <ui:icono n="download"/>Descargar boleta (PDF)<span class="sr-only"> — se abre en otra pestaña</span>
        </a>
        <a href="<%= ctx %>/jsp-Interfaz/historial.jsp" class="btn btn-secundario btn-lg"><ui:icono n="receipt_long"/>Ver mis compras</a>
        <a href="<%= ctx %>/jsp-Interfaz/interfaz.jsp" class="btn btn-fantasma btn-lg sm:ml-auto">Seguir comprando</a>
    </div>
    <p class="mt-4 text-xs text-stone-500">También puedes consultar esta compra más tarde en «Mis compras». <a class="underline" href="<%= ctx %>/jsp-Interfaz/ayuda.jsp#boleta">Más sobre tu boleta</a></p>
</main>

<%@ include file="/WEB-INF/jspf/tienda-footer.jspf" %>
<%@ include file="/WEB-INF/jspf/fin.jspf" %>
</body>
</html>
