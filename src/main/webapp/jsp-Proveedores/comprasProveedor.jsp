<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Html, util.Flash" %>
<%
    String tiendaId = (String) session.getAttribute("adminTiendaId");
    String urlForm = ctx + "/jsp-Proveedores/comprasProveedor.jsp";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        int proveedorId, productoId, cantidad;
        double precio;
        String campo = null, mensaje = null;
        proveedorId = entero(request.getParameter("proveedor_id"));
        productoId = entero(request.getParameter("producto_id"));
        cantidad = entero(request.getParameter("cantidad"));
        try { precio = Double.parseDouble(request.getParameter("precio").replace(',', '.')); } catch (Exception e) { precio = -1; }
        if (proveedorId <= 0) { campo = "proveedor_id"; mensaje = "Elige el proveedor."; }
        else if (productoId <= 0) { campo = "producto_id"; mensaje = "Elige el producto que compraste."; }
        else if (cantidad <= 0) { campo = "cantidad"; mensaje = "La cantidad debe ser un número entero mayor que 0."; }
        else if (precio <= 0) { campo = "precio"; mensaje = "Escribe el precio unitario, por ejemplo 2.50."; }
        if (campo != null) {
            Flash.formulario(session, request.getParameterMap(), campo, mensaje);
            response.sendRedirect(urlForm);
            return;
        }
        Connection con = null;
        try {
            con = util.Conexion.getConnection();
            con.setAutoCommit(false); // compra y stock se guardan juntos o no se guarda nada
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO compras_proveedores (proveedor_id, producto_id, cantidad, precio_unitario, estado, tienda_id) " +
                    "SELECT ?, ?, ?, ?, 'recibido', ? WHERE EXISTS (SELECT 1 FROM proveedores WHERE id=? AND tienda_id=?) " +
                    "AND EXISTS (SELECT 1 FROM productos WHERE id=? AND tienda_id=?)")) {
                ps.setInt(1, proveedorId); ps.setInt(2, productoId); ps.setInt(3, cantidad); ps.setDouble(4, precio); ps.setString(5, tiendaId);
                ps.setInt(6, proveedorId); ps.setString(7, tiendaId); ps.setInt(8, productoId); ps.setString(9, tiendaId);
                if (ps.executeUpdate() != 1) throw new IllegalArgumentException("El proveedor o producto no pertenece a esta tienda.");
            }
            String nombre; int nuevoStock;
            try (PreparedStatement ps = con.prepareStatement("UPDATE productos SET stock = stock + ? WHERE id = ? AND tienda_id = ? RETURNING nombre, stock")) {
                ps.setInt(1, cantidad); ps.setInt(2, productoId); ps.setString(3, tiendaId);
                try (ResultSet rs = ps.executeQuery()) { if (!rs.next()) throw new IllegalArgumentException("El producto no pertenece a esta tienda."); nombre = rs.getString(1); nuevoStock = rs.getInt(2); }
            }
            con.commit();
            Flash.exito(session, "Registraste " + cantidad + " × «" + nombre + "». Stock actual: " + nuevoStock + ".");
            response.sendRedirect(ctx + "/jsp-Proveedores/Proveedores.jsp");
        } catch (Exception e) {
            log("Error al registrar compra a proveedor", e);
            if (con != null) try { con.rollback(); } catch (SQLException ignorada) { }
            Flash.error(session, "No pudimos registrar la compra; no se modificó el stock. Inténtalo de nuevo.");
            Flash.formulario(session, request.getParameterMap(), null);
            response.sendRedirect(urlForm);
        } finally {
            if (con != null) try { con.close(); } catch (SQLException ignorada) { }
        }
        return;
    }

    String titulo = "Registrar compra";
    String seccion = "compras";
    Map<String, String> form = Flash.formulario(session);
    String errorCampo = form.get("__error");
    String errorMsg = form.get("__mensaje");
    String provSel = form.containsKey("proveedor_id") ? form.get("proveedor_id") : request.getParameter("proveedor");

    List<String[]> proveedores = new ArrayList<>();
    Map<String, List<String[]>> productosPorCategoria = new LinkedHashMap<>();
    boolean errorDatos = false;
    try (Connection con = util.Conexion.getConnection()) {
        try (PreparedStatement st = con.prepareStatement("SELECT id, nombre FROM proveedores WHERE activo = TRUE AND tienda_id = ? ORDER BY nombre")) {
            st.setString(1, tiendaId);
            try (ResultSet rs = st.executeQuery()) {
            while (rs.next()) proveedores.add(new String[]{rs.getString("id"), rs.getString("nombre")});
            }
        }
        try (PreparedStatement st = con.prepareStatement("SELECT id, nombre, stock, unidad, COALESCE(categoria, 'Sin categoría') AS categoria FROM productos WHERE tienda_id = ? ORDER BY categoria, nombre")) {
            st.setString(1, tiendaId);
            try (ResultSet rs = st.executeQuery()) {
            while (rs.next()) {
                productosPorCategoria.computeIfAbsent(rs.getString("categoria"), k -> new ArrayList<>())
                        .add(new String[]{rs.getString("id"), rs.getString("nombre"), rs.getString("stock"), rs.getString("unidad")});
            }
            }
        }
    } catch (Exception e) {
        log("Error al cargar el formulario de compras", e);
        errorDatos = true;
    }
%>
<%!
    static int entero(String v) {
        try { return Integer.parseInt(v.trim()); } catch (Exception e) { return -1; }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
    <h1 class="text-2xl font-semibold tracking-tight text-stone-900">Registrar compra a proveedor</h1>
    <p class="mt-1 text-sm text-stone-600">La cantidad se suma al stock del producto en cuanto guardas.</p>

    <% if (errorDatos) { %>
    <div class="aviso aviso-error mt-6" role="alert"><ui:icono n="error"/><div><p class="font-medium">No pudimos cargar proveedores y productos.</p><a class="btn btn-secundario btn-sm mt-2" href="<%= urlForm %>"><ui:icono n="restart_alt" clase="size-4"/>Reintentar</a></div></div>
    <% } else if (proveedores.isEmpty()) { %>
    <div class="aviso aviso-advertencia mt-6"><ui:icono n="warning"/><div><p class="font-medium">No hay proveedores activos.</p><p class="mt-1">Registra o reactiva un proveedor para poder anotar compras.</p>
        <a class="btn btn-secundario btn-sm mt-2" href="<%= ctx %>/jsp-Proveedores/nuevoProveedor.jsp"><ui:icono n="add" clase="size-4"/>Nuevo proveedor</a></div></div>
    <% } else { %>
    <form method="post" action="<%= urlForm %>" class="mt-6 grid max-w-4xl gap-6 lg:grid-cols-[minmax(0,1fr)_16rem]" data-validar data-avisar-cambios>
        <div class="tarjeta tarjeta-cuerpo space-y-5">
            <div class="campo">
                <label for="proveedor_id" class="etiqueta">Proveedor</label>
                <select id="proveedor_id" name="proveedor_id" class="entrada" required <%= "proveedor_id".equals(errorCampo) ? "aria-invalid=\"true\"" : "" %>>
                    <option value="" disabled <%= provSel == null ? "selected" : "" %>>Elige un proveedor</option>
                    <% for (String[] p : proveedores) { %><option value="<%= p[0] %>" <%= p[0].equals(provSel) ? "selected" : "" %>><%= Html.esc(p[1]) %></option><% } %>
                </select>
                <% if ("proveedor_id".equals(errorCampo)) { %><p class="error-campo"><ui:icono n="error"/><span><%= Html.esc(errorMsg) %></span></p><% } %>
            </div>
            <div class="campo">
                <label for="producto_id" class="etiqueta">Producto</label>
                <select id="producto_id" name="producto_id" class="entrada" required aria-describedby="producto-ayuda" <%= "producto_id".equals(errorCampo) ? "aria-invalid=\"true\"" : "" %>>
                    <option value="" disabled <%= form.get("producto_id") == null ? "selected" : "" %>>Elige un producto</option>
                    <% for (Map.Entry<String, List<String[]>> g : productosPorCategoria.entrySet()) { %>
                    <optgroup label="<%= Html.esc(g.getKey()) %>">
                        <% for (String[] p : g.getValue()) { %>
                        <option value="<%= p[0] %>" data-stock="<%= p[2] %>" <%= p[0].equals(form.get("producto_id")) ? "selected" : "" %>><%= Html.esc(p[1]) %> — stock <%= p[2] %></option>
                        <% } %>
                    </optgroup>
                    <% } %>
                </select>
                <p id="producto-ayuda" class="ayuda">Agrupados por categoría; junto a cada uno, su stock actual.</p>
                <% if ("producto_id".equals(errorCampo)) { %><p class="error-campo"><ui:icono n="error"/><span><%= Html.esc(errorMsg) %></span></p><% } %>
            </div>
            <div class="grid gap-5 sm:grid-cols-2">
                <ui:campo nombre="cantidad" etiqueta="Cantidad recibida" tipo="number" icono="inventory_2" valor='<%= form.get("cantidad") %>'
                          min="1" step="1" inputmode="numeric" data-msg-minimo="La cantidad debe ser al menos 1."
                          error='<%= "cantidad".equals(errorCampo) ? errorMsg : null %>'/>
                <ui:campo nombre="precio" etiqueta="Precio unitario (S/)" tipo="number" icono="sell" valor='<%= form.get("precio") %>'
                          min="0.01" step="0.01" inputmode="decimal" ayuda="Lo que pagaste por cada unidad."
                          error='<%= "precio".equals(errorCampo) ? errorMsg : null %>'/>
            </div>
        </div>

        <aside class="tarjeta tarjeta-cuerpo h-fit lg:sticky lg:top-24" aria-live="polite">
            <h2 class="font-semibold text-stone-900">Resumen</h2>
            <dl class="mt-3 space-y-2 text-sm">
                <div class="flex justify-between text-stone-600"><dt>Total de la compra</dt><dd class="font-semibold tabular-nums text-stone-900" data-resumen-total>—</dd></div>
                <div class="flex justify-between text-stone-600"><dt>Stock después</dt><dd class="tabular-nums" data-resumen-stock>—</dd></div>
            </dl>
            <button type="submit" class="btn btn-primario mt-5 w-full" data-cargando="Registrando…">
                <span class="btn-icono"><ui:icono n="check"/></span><ui:icono n="progress_activity" clase="btn-spinner"/><span class="btn-texto">Registrar compra</span>
            </button>
            <a href="<%= ctx %>/jsp-Proveedores/Proveedores.jsp" class="btn btn-fantasma mt-2 w-full">Cancelar</a>
        </aside>
    </form>
    <script>
        (function () {
            var f = document.currentScript.previousElementSibling;
            var prod = f.querySelector('#producto_id'), cant = f.querySelector('[name=cantidad]'), precio = f.querySelector('[name=precio]');
            var total = f.querySelector('[data-resumen-total]'), stock = f.querySelector('[data-resumen-stock]');
            function soles(n) { return 'S/ ' + n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }); }
            function actualizar() {
                var c = parseInt(cant.value, 10), p = parseFloat(precio.value);
                total.textContent = c > 0 && p > 0 ? soles(c * p) : '—';
                var op = prod.selectedOptions[0];
                if (op && op.dataset.stock !== undefined) {
                    var actual = parseInt(op.dataset.stock, 10);
                    stock.textContent = c > 0 ? actual + ' → ' + (actual + c) : String(actual);
                } else { stock.textContent = '—'; }
            }
            [prod, cant, precio].forEach(function (el) { el.addEventListener('input', actualizar); el.addEventListener('change', actualizar); });
            actualizar();
        })();
    </script>
    <% } %>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
