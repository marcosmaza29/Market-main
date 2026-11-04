<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, modelo.CarritoItem, util.Html" %>
<%@ page import="javax.servlet.http.HttpServletResponse" %>
<%
    String titulo = "Tu carrito";

    // Validar tienda solicitada
    String tiendaId = request.getParameter("tienda");

    if (!"market".equals(tiendaId)
            && !"juguetes".equals(tiendaId)
            && !"cosmeticos".equals(tiendaId)) {
        response.sendError(
            HttpServletResponse.SC_BAD_REQUEST,
            "La tienda solicitada no es válida."
        );
        return;
    }

    // Recuperar carrito de la sesión
    List<CarritoItem> carrito =
        (List<CarritoItem>) session.getAttribute("carrito");

    if (carrito == null) {
        carrito = new ArrayList<>();
        session.setAttribute("carrito", carrito);
    }

    boolean conSesion = session.getAttribute("correoCliente") != null;

    // Comprobar que el carrito pertenezca a una sola tienda
    String carritoTienda =
        (String) session.getAttribute("carritoTienda");

    if (!carrito.isEmpty()
            && carritoTienda != null
            && !carritoTienda.equals(tiendaId)) {
        response.sendError(
            HttpServletResponse.SC_CONFLICT,
            "Tu carrito pertenece a otra tienda. Vuelve a esa tienda para continuar."
        );
        return;
    }

    if (carritoTienda == null || carrito.isEmpty()) {
        session.setAttribute("carritoTienda", tiendaId);
    }

    // Consultar imágenes y stock únicamente de la tienda actual
    Map<Integer, String> imagenes = new HashMap<>();
    Map<Integer, Integer> stocks = new HashMap<>();

    if (!carrito.isEmpty()) {
        StringBuilder in = new StringBuilder();

        for (int i = 0; i < carrito.size(); i++) {
            in.append(i == 0 ? "?" : ",?");
        }

        try (Connection con = util.Conexion.getConnection();
             PreparedStatement ps = con.prepareStatement(
                 "SELECT id, imagen_url, stock FROM productos " +
                 "WHERE id IN (" + in + ") AND tienda_id = ?")) {

            for (int i = 0; i < carrito.size(); i++) {
                ps.setInt(i + 1, carrito.get(i).getId());
            }

            ps.setString(carrito.size() + 1, tiendaId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    imagenes.put(
                        rs.getInt("id"),
                        rs.getString("imagen_url")
                    );
                    stocks.put(
                        rs.getInt("id"),
                        rs.getInt("stock")
                    );
                }
            }
        } catch (Exception e) {
            log("No se pudo leer el detalle del carrito", e);
            response.sendError(
                HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                "No se pudo consultar el carrito."
            );
            return;
        }

        // No permitir productos inexistentes o de otra tienda
        for (CarritoItem it : carrito) {
            if (!stocks.containsKey(it.getId())) {
                response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "El carrito contiene un producto que no pertenece a esta tienda."
                );
                return;
            }
        }
    }

    // Calcular total y comprobar stock
    double total = 0;
    int unidades = 0;
    boolean faltaStock = false;

    for (CarritoItem it : carrito) {
        total += it.getSubtotal();
        unidades += it.getCantidad();

        Integer stock = stocks.get(it.getId());

        if (stock != null && it.getCantidad() > stock) {
            faltaStock = true;
        }
    }

    int pasoActual = 1;
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/jspf/head.jspf" %>
</head>
<body class="min-h-dvh">

<%@ include file="/WEB-INF/jspf/tienda-header.jspf" %>

<main id="contenido" class="contenedor max-w-5xl pt-8">

    <%@ include file="/WEB-INF/jspf/pasos-compra.jspf" %>

    <div class="mt-6 flex flex-wrap items-end justify-between gap-3">
        <div>
            <h1 class="text-2xl font-semibold tracking-tight text-stone-900">
                Tu carrito
            </h1>
            <p class="mt-1 text-sm text-stone-600">
                <%= carrito.isEmpty()
                    ? "Aún no agregas productos."
                    : Html.plural(unidades, "unidad", "unidades")
                      + " · "
                      + Html.plural(carrito.size(), "producto", "productos") %>
            </p>
        </div>

        <a href="<%= ctx %>/jsp-Interfaz/interfaz.jsp?tienda=<%= tiendaId %>"
           class="btn btn-fantasma">
            <ui:icono n="arrow_back"/> Seguir comprando
        </a>
    </div>

    <% if (carrito.isEmpty()) { %>

        <div class="mt-8 flex flex-col items-center rounded-2xl border border-dashed border-stone-300 bg-white px-6 py-16 text-center">
            <span class="grid size-12 place-items-center rounded-full bg-stone-100 text-stone-500">
                <ui:icono n="remove_shopping_cart" clase="size-6"/>
            </span>

            <h2 class="mt-4 text-base font-semibold text-stone-900">
                Tu carrito está vacío
            </h2>

            <p class="mt-1 max-w-sm text-sm text-stone-600">
                Explora el catálogo y pulsa «Agregar» en los productos que quieras.
                Aparecerán aquí para que los revises antes de comprar.
            </p>

            <a href="<%= ctx %>/jsp-Interfaz/interfaz.jsp?tienda=<%= tiendaId %>"
               class="btn btn-primario mt-5">
                <ui:icono n="storefront"/> Ver productos
            </a>
        </div>

    <% } else { %>

        <div class="mt-6 grid gap-6 lg:grid-cols-[minmax(0,1fr)_20rem] lg:items-start">

            <section aria-label="Productos en tu carrito"
                     class="tarjeta divide-y divide-stone-100">

                <% for (CarritoItem it : carrito) {
                    String img = imagenes.get(it.getId());
                    Integer stock = stocks.get(it.getId());
                    boolean excede = stock != null && it.getCantidad() > stock;
                    String nombre = Html.esc(it.getNombre());
                %>

                <article class="flex gap-4 p-4 sm:p-5"
                         aria-label="<%= nombre %>">

                    <div class="marco-img grid size-20 shrink-0 place-items-center overflow-hidden rounded-lg bg-stone-100 sm:size-24">

                        <% if (img != null && !img.isEmpty()) { %>
                            <img src="<%= Html.esc(util.Imagenes.url(img)) %>"
                                 alt=""
                                 class="img-progresiva size-full object-contain p-2"
                                 loading="lazy"
                                 width="96"
                                 height="96">
                        <% } else { %>
                            <ui:icono n="image" clase="size-8 text-stone-400"/>
                        <% } %>

                    </div>

                    <div class="flex min-w-0 flex-1 flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">

                        <div class="min-w-0">
                            <h2 class="font-medium text-stone-900">
                                <%= nombre %>
                            </h2>

                            <p class="mt-0.5 text-sm text-stone-600">
                                <%= Html.soles(it.getPrecio()) %><%= it.getUnidad() != null ? " / " + Html.esc(it.getUnidad()) : "" %>
                            </p>

                            <% if (excede) { %>
                                <p class="mt-1.5 flex items-center gap-1 text-xs font-medium text-red-700">
                                    <ui:icono n="warning" clase="size-4"/>
                                    Solo quedan <%= stock %>. Reduce la cantidad para poder comprar.
                                </p>
                            <% } else if (stock != null && stock <= 5) { %>
                                <p class="mt-1.5 text-xs text-amber-800">
                                    Quedan <%= stock %> en tienda
                                </p>
                            <% } %>
                        </div>

                        <div class="flex items-center justify-between gap-4 sm:flex-col sm:items-end">

                            <form method="post"
                                  action="<%= ctx %>/carrito"
                                  class="flex h-9 items-center rounded-lg bg-white ring-1 ring-stone-300 ring-inset"
                                  aria-label="Cantidad de <%= nombre %>">

                                <input type="hidden" name="tienda" value="<%= tiendaId %>">
                                <input type="hidden" name="accion" value="actualizar">
                                <input type="hidden" name="id" value="<%= it.getId() %>">

                                <button type="submit"
                                        name="nueva"
                                        value="<%= it.getCantidad() - 1 %>"
                                        class="grid h-full w-9 place-items-center rounded-l-lg text-stone-600 transition-colors hover:bg-stone-100"
                                        aria-label="<%= it.getCantidad() == 1 ? "Quitar del carrito" : "Quitar uno" %>"
                                        data-sin-carga>
                                    <ui:icono n='<%= it.getCantidad() == 1 ? "delete" : "remove" %>' clase="size-4"/>
                                </button>

                                <input type="number"
                                       name="cantidad"
                                       value="<%= it.getCantidad() %>"
                                       min="0"
                                       max="<%= Math.min(99, stock == null ? 99 : stock) %>"
                                       inputmode="numeric"
                                       aria-label="Cantidad"
                                       class="h-full w-12 border-0 bg-transparent text-center text-sm font-semibold tabular-nums [appearance:textfield] focus:outline-none [&::-webkit-inner-spin-button]:appearance-none <%= excede ? "text-red-700" : "" %>"
                                       data-auto-enviar>

                                <button type="submit"
                                        name="nueva"
                                        value="<%= it.getCantidad() + 1 %>"
                                        class="grid h-full w-9 place-items-center rounded-r-lg text-stone-600 transition-colors hover:bg-stone-100 disabled:text-stone-300"
                                        aria-label="Agregar uno"
                                        data-sin-carga
                                        <%= stock != null && it.getCantidad() >= stock ? "disabled" : "" %>>
                                    <ui:icono n="add" clase="size-4"/>
                                </button>
                            </form>

                            <p class="font-semibold tabular-nums text-stone-900">
                                <%= Html.soles(it.getSubtotal()) %>
                            </p>
                        </div>
                    </div>

                    <form method="post"
                          action="<%= ctx %>/carrito"
                          class="-mt-1 -mr-1 shrink-0">
                        <input type="hidden" name="tienda" value="<%= tiendaId %>">
                        <input type="hidden" name="accion" value="eliminar">
                        <input type="hidden" name="id" value="<%= it.getId() %>">

                        <button type="submit"
                                class="btn btn-fantasma btn-sm btn-solo-icono text-stone-500 hover:text-red-700"
                                aria-label="Quitar <%= nombre %> del carrito"
                                title="Quitar del carrito"
                                data-sin-carga>
                            <ui:icono n="close"/>
                        </button>
                    </form>

                </article>

                <% } %>

            </section>

            <aside class="tarjeta tarjeta-cuerpo lg:sticky lg:top-24"
                   aria-labelledby="titulo-resumen">

                <h2 id="titulo-resumen"
                    class="text-base font-semibold text-stone-900">
                    Resumen
                </h2>

                <dl class="mt-4 space-y-2 text-sm">
                    <div class="flex justify-between text-stone-600">
                        <dt>Productos (<%= unidades %>)</dt>
                        <dd class="tabular-nums"><%= Html.soles(total) %></dd>
                    </div>

                    <div class="flex justify-between border-t border-stone-200 pt-3 text-base font-semibold text-stone-900">
                        <dt>Total</dt>
                        <dd class="tabular-nums"><%= Html.soles(total) %></dd>
                    </div>
                </dl>

                <% if (faltaStock) { %>
                    <div class="aviso aviso-error mt-4">
                        <ui:icono n="warning"/>
                        <p>
                            Algunos productos superan el stock disponible.
                            Ajusta las cantidades marcadas para continuar.
                        </p>
                    </div>
                <% } %>

                <% if (!conSesion) { %>

                    <div class="aviso aviso-info mt-4">
                        <ui:icono n="info"/>
                        <p>
                            Para comprar necesitas una cuenta.
                            Tu carrito se mantiene mientras inicias sesión.
                        </p>
                    </div>

                    <a href="<%= ctx %>/jsp-Usuarios/login.jsp?tienda=<%= tiendaId %>&volver=<%= java.net.URLEncoder.encode("/jsp-Interfaz/carrito.jsp?tienda=" + tiendaId, "UTF-8") %>"
                       class="btn btn-primario btn-lg mt-4 w-full">
                        <ui:icono n="login"/> Iniciar sesión para comprar
                    </a>

                    <a href="<%= ctx %>/jsp-Usuarios/registro.jsp?tienda=<%= tiendaId %>"
                       class="btn btn-fantasma mt-2 w-full">
                        Crear una cuenta
                    </a>

                <% } else { %>

                    <form method="post"
                          action="<%= ctx %>/jsp-Interfaz/finalizar-compra.jsp?tienda=<%= tiendaId %>"
                          class="mt-5"
                          data-confirmar="Registraremos tu compra por <%= Html.soles(total) %> y descontaremos los productos del stock. Después podrás descargar tu boleta en PDF."
                          data-confirmar-titulo="¿Confirmas la compra?"
                          data-confirmar-boton="Sí, comprar">

                        <input type="hidden" name="tienda" value="<%= tiendaId %>">

                        <button type="submit"
                                class="btn btn-primario btn-lg w-full"
                                data-cargando="Procesando compra…"
                                <%= faltaStock ? "disabled" : "" %>>
                            <span class="btn-icono">
                                <ui:icono n="shopping_bag"/>
                            </span>
                            <ui:icono n="progress_activity" clase="btn-spinner"/>
                            <span class="btn-texto">Confirmar compra</span>
                        </button>
                    </form>

                <% } %>

                <form method="post"
                      action="<%= ctx %>/carrito"
                      class="mt-3 text-center">
                    <input type="hidden" name="tienda" value="<%= tiendaId %>">
                    <input type="hidden" name="accion" value="vaciar">

                    <button type="submit"
                            class="btn btn-peligro-suave btn-sm"
                            data-sin-carga>
                        <ui:icono n="delete" clase="size-4"/> Vaciar carrito
                    </button>
                </form>

                <p class="mt-4 text-xs leading-relaxed text-stone-500">
                    Revisa cantidades y precios antes de confirmar.
                    <a class="font-medium text-stone-700 underline"
                       href="<%= ctx %>/jsp-Interfaz/ayuda.jsp?tienda=<%= tiendaId %>#como-comprar">
                        ¿Cómo funciona?
                    </a>
                </p>

            </aside>
        </div>

    <% } %>

</main>

<%@ include file="/WEB-INF/jspf/tienda-footer.jspf" %>
<%@ include file="/WEB-INF/jspf/fin.jspf" %>

</body>
</html>
