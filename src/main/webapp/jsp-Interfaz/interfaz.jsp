<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Html, util.Catalogo" %>
<%
    // --- 1. CONFIGURACIÓN DINÁMICA DE LA TIENDA ---
    String tienda = request.getParameter("tienda");

    if (tienda == null || tienda.trim().isEmpty()) {
        tienda = contextoTienda;
    } else {
        tienda = tienda.trim().toLowerCase(Locale.ROOT);
    }

    if (!Arrays.asList("market", "juguetes", "cosmeticos").contains(tienda)) {
        tienda = contextoTienda;
    }

    // Valores predeterminados
    String nombreTienda = util.Tienda.nombre(tienda);
    String colorPrimario = "#2563EB";
    String colorSecundario = "#1D4ED8";
    String colorFondo = "#EFF6FF";
    String fuenteTienda = "Inter";
    String logoTienda = "";
    String bannerTienda = "";

    List<String> fuentesPermitidas = Arrays.asList(
        "Inter",
        "'Segoe UI', sans-serif",
        "Georgia, serif",
        "'Comic Sans MS', cursive"
    );

    // Leer configuración desde Supabase
    // La columna correcta es tipo_fuente, no fuente.
    try (Connection con = util.Conexion.getConnection();
         PreparedStatement ps = con.prepareStatement(
             "SELECT nombre, tipo_fuente, color_primario, " +
             "color_secundario, color_fondo, logo_url, banner_url " +
             "FROM tiendas WHERE id = ?")) {

        ps.setString(1, tienda);

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                String valor;

                valor = rs.getString("nombre");
                if (valor != null && !valor.trim().isEmpty()) {
                    nombreTienda = valor.trim();
                }

                valor = rs.getString("tipo_fuente");
                if (valor != null &&
                    fuentesPermitidas.contains(valor.trim())) {
                    fuenteTienda = valor.trim();
                }

                valor = rs.getString("color_primario");
                if (valor != null &&
                    valor.matches("#[0-9a-fA-F]{6}")) {
                    colorPrimario = valor;
                }

                valor = rs.getString("color_secundario");
                if (valor != null &&
                    valor.matches("#[0-9a-fA-F]{6}")) {
                    colorSecundario = valor;
                }

                valor = rs.getString("color_fondo");
                if (valor != null &&
                    valor.matches("#[0-9a-fA-F]{6}")) {
                    colorFondo = valor;
                }

                logoTienda = rs.getString("logo_url");
                bannerTienda = rs.getString("banner_url");

                if (logoTienda == null) {
                    logoTienda = "";
                } else {
                    logoTienda = logoTienda.trim();
                }

                if (bannerTienda == null) {
                    bannerTienda = "";
                } else {
                    bannerTienda = bannerTienda.trim();
                }
            }
        }
    } catch (Exception e) {
        log("Error al obtener la configuración de la tienda: " + tienda, e);
    }
%>

<%!
    static final class Producto {
        int id, stock;
        String nombre, descripcion, unidad, categoria, imagen;
        double precio;
    }

    static String escaparLike(String s) {
        return s.replace("\\", "\\\\")
                .replace("%", "\\%")
                .replace("_", "\\_");
    }

    static String urlTienda(
            String ctx,
            String tienda,
            String categoria,
            String buscar,
            String orden,
            boolean ocultar) {

        StringBuilder q = new StringBuilder("?tienda=" + tienda);

        try {
            if (categoria != null) {
                q.append("&categoria=").append(
                    java.net.URLEncoder.encode(categoria, "UTF-8"));
            }

            if (buscar != null) {
                q.append("&buscar=").append(
                    java.net.URLEncoder.encode(buscar, "UTF-8"));
            }
        } catch (java.io.UnsupportedEncodingException e) {
            // UTF-8 siempre existe
        }

        if (orden != null && !"relevancia".equals(orden)) {
            q.append("&orden=").append(orden);
        }

        if (ocultar) {
            q.append("&disponibles=1");
        }

        return ctx + "/jsp-Interfaz/interfaz.jsp" + q.toString();
    }
%>

<%
    String titulo = "Inicio";
    Map<String, String> categoriasTienda = Catalogo.categorias(tienda);

    // --- Filtros ---
    String categoria = Html.param(request, "categoria");

    if (!Catalogo.esCategoria(categoria, tienda)) {
        categoria = null;
    }

    String buscar = Html.param(request, "buscar");

    if (buscar != null && buscar.length() > 80) {
        buscar = buscar.substring(0, 80);
    }

    String orden = request.getParameter("orden");

    if (!Arrays.asList(
            "relevancia", "precio_asc", "precio_desc", "nombre"
        ).contains(orden)) {
        orden = "relevancia";
    }

    boolean ocultarAgotados =
        "1".equals(request.getParameter("disponibles"));

    boolean hayFiltros =
        categoria != null || buscar != null || ocultarAgotados;

    if (buscar != null) {
        titulo = "Resultados para «" + buscar + "»";
    } else if (categoria != null) {
        titulo = categoria;
    }

    // --- Productos filtrados por tienda ---
    Map<String, Integer> conteo = new LinkedHashMap<>();
    int totalCatalogo = 0;
    List<Producto> productos = new ArrayList<>();
    boolean errorDatos = false;

    try (Connection con = util.Conexion.getConnection()) {

        // Conteo de productos por categoría
        try (PreparedStatement psCat = con.prepareStatement(
                "SELECT categoria, COUNT(*) AS n " +
                "FROM productos WHERE tienda_id = ? GROUP BY categoria")) {

            psCat.setString(1, tienda);

            try (ResultSet rs = psCat.executeQuery()) {
                while (rs.next()) {
                    conteo.put(rs.getString("categoria"), rs.getInt("n"));
                    totalCatalogo += rs.getInt("n");
                }
            }
        }

        StringBuilder sql = new StringBuilder(
            "SELECT id, nombre, descripcion, precio, stock, unidad, " +
            "imagen_url, categoria FROM productos WHERE tienda_id = ?"
        );

        List<Object> params = new ArrayList<>();
        params.add(tienda);

        if (categoria != null) {
            sql.append(" AND categoria = ?");
            params.add(categoria);
        }

        if (buscar != null) {
            sql.append(
                " AND (nombre ILIKE ? OR descripcion ILIKE ? " +
                "OR categoria ILIKE ?)"
            );

            String patron = "%" + escaparLike(buscar) + "%";

            params.add(patron);
            params.add(patron);
            params.add(patron);
        }

        if (ocultarAgotados) {
            sql.append(" AND stock > 0");
        }

        switch (orden) {
            case "precio_asc":
                sql.append(" ORDER BY precio ASC, nombre");
                break;

            case "precio_desc":
                sql.append(" ORDER BY precio DESC, nombre");
                break;

            case "nombre":
                sql.append(" ORDER BY nombre");
                break;

            default:
                if (buscar != null) {
                    sql.append(
                        " ORDER BY (stock <= 0), " +
                        "CASE WHEN nombre ILIKE ? THEN 0 ELSE 1 END, nombre"
                    );
                    params.add(escaparLike(buscar) + "%");
                } else {
                    sql.append(" ORDER BY (stock <= 0), nombre");
                }
        }

        try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Producto p = new Producto();

                    p.id = rs.getInt("id");
                    p.nombre = rs.getString("nombre");
                    p.descripcion = rs.getString("descripcion");
                    p.precio = rs.getDouble("precio");
                    p.stock = rs.getInt("stock");
                    p.unidad = rs.getString("unidad");
                    p.categoria = rs.getString("categoria");
                    p.imagen = rs.getString("imagen_url");

                    productos.add(p);
                }
            }
        }

    } catch (Exception e) {
        log("Error al cargar el catálogo de la tienda: " + tienda, e);
        errorDatos = true;
    }

    List<String[]> publicidad = new ArrayList<>();
    try (Connection con = util.Conexion.getConnection();
         PreparedStatement ps = con.prepareStatement("SELECT id, texto_alternativo FROM carrusel_publicidad WHERE tienda_id = ? ORDER BY orden, id")) {
        ps.setString(1, tienda);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) publicidad.add(new String[]{ctx + "/publicidad-imagen?id=" + rs.getLong(1) + "&tienda=" + tienda, "1120", "600", rs.getString(2)});
        }
    } catch (Exception e) { log("No se pudo cargar el carrusel de " + tienda, e); }
    if (publicidad.isEmpty() && "market".equals(tienda)) {
        for (String promo : new String[]{"promo1", "promo2", "promo3", "promoA", "promoB", "promoC"})
            publicidad.add(new String[]{util.Imagenes.url("promociones/" + promo + ".jpg"), "1120", "600", "Promoción de Market"});
    }
    String[][] promos = publicidad.toArray(new String[0][]);

    String urlBase =
        ctx + "/jsp-Interfaz/interfaz.jsp?tienda=" + tienda;
    request.setAttribute("tienda.nombre", nombreTienda);
    request.setAttribute("tienda.logo", logoTienda);
    request.setAttribute("tienda.fuente", fuenteTienda);
    request.setAttribute("tienda.colorPrimario", colorPrimario);
    request.setAttribute("tienda.colorSecundario", colorSecundario);
    request.setAttribute("tienda.colorFondo", colorFondo);
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/jspf/head.jspf" %>



    <script
        src="<%= ctx %>/assets/tienda.js?v=<%= Catalogo.VERSION %>"
        defer>
    </script>

    <style>
        :root {
            --color-marca-principal: <%= colorPrimario %>;
            --color-marca-secundario: <%= colorSecundario %>;
            --color-fondo-tienda: <%= colorFondo %>;
        }

        body {
            font-family: <%= fuenteTienda %>;
            background-color: var(--color-fondo-tienda);
        }

        .btn-primario {
            background-color: var(--color-marca-principal);
            border-color: var(--color-marca-principal);
        }

        .btn-primario:hover {
            filter: brightness(0.92);
        }

        .texto-marca {
            color: var(--color-marca-principal);
        }

        .fondo-marca {
            background-color: var(--color-marca-principal);
        }

        a:focus-visible,
        button:focus-visible {
            outline: 2px solid var(--color-marca-secundario);
            outline-offset: 2px;
        }
    </style>
</head>

<body class="min-h-dvh">

<%@ include file="/WEB-INF/jspf/tienda-header.jspf" %>

<main id="contenido" class="contenedor pt-6">
    <% if (!bannerTienda.isEmpty() && !hayFiltros) { %>
    <section class="mb-6 overflow-hidden rounded-2xl" aria-label="Imagen principal de la tienda">
        <img src="<%= Html.esc(bannerTienda) %>" alt="Presentación de <%= Html.esc(nombreTienda) %>"
             class="block max-h-72 w-full object-cover" loading="eager">
    </section>
    <% } %>

    <% if (!hayFiltros && promos.length > 0) { %>
    <section
        data-carrusel
        class="relative mb-8"
        aria-roledescription="carrusel"
        aria-label="Promociones">

        <div class="carrusel-pista -mx-4 gap-3 px-4 sm:mx-0 sm:px-0">

            <%
            for (int i = 0; i < promos.length; i++) { %>

            <figure
                class="marco-img relative h-44 overflow-hidden rounded-xl bg-stone-200 ring-1 ring-stone-200 sm:h-56 lg:h-64"
                style="aspect-ratio: <%= promos[i][1] %> / <%= promos[i][2] %>"
                aria-roledescription="diapositiva"
                aria-label="<%= (i + 1) %> de <%= promos.length %>"
                data-cargando>

                <img
                    src="<%= Html.esc(promos[i][0]) %>"
                    alt="<%= Html.esc(promos[i][3]) %>"
                    class="img-progresiva size-full object-contain"
                    <%= i < 2 ? "fetchpriority=\"high\"" : "loading=\"lazy\"" %>
                    decoding="async"
                    width="<%= promos[i][1] %>"
                    height="<%= promos[i][2] %>">
            </figure>

            <% } %>
        </div>

        <div class="mt-3 flex items-center justify-between gap-3">
            <div class="flex items-center gap-1.5">
                <% for (int i = 0; i < promos.length; i++) { %>
                <button
                    type="button"
                    class="carrusel-punto"
                    data-ir-a="<%= i %>"
                    aria-label="Ir a la promoción <%= (i + 1) %>">
                </button>
                <% } %>
            </div>

            <div class="flex items-center gap-1">
                <button
                    type="button"
                    class="btn btn-fantasma btn-sm btn-solo-icono"
                    data-pausa
                    aria-pressed="false"
                    aria-label="Pausar el pase automático">
                    <span data-icono="pausa">
                        <ui:icono n="pause" clase="size-4"/>
                    </span>
                    <span data-icono="play" class="hidden">
                        <ui:icono n="play_arrow" clase="size-4"/>
                    </span>
                </button>

                <button
                    type="button"
                    class="btn btn-secundario btn-sm btn-solo-icono rounded-full"
                    data-anterior
                    aria-label="Promoción anterior">
                    <ui:icono n="chevron_left" clase="size-4"/>
                </button>

                <button
                    type="button"
                    class="btn btn-secundario btn-sm btn-solo-icono rounded-full"
                    data-siguiente
                    aria-label="Promoción siguiente">
                    <ui:icono n="chevron_right" clase="size-4"/>
                </button>
            </div>
        </div>
    </section>
    <% } %>

    <!-- Categorías en móvil -->
    <nav
        aria-label="Categorías"
        class="-mx-4 mb-6 flex gap-2 overflow-x-auto px-4 pb-1 [scrollbar-width:none] lg:hidden">

        <a
            class="chip"
            href="<%= urlTienda(ctx, tienda, null, buscar, orden, ocultarAgotados) %>"
            <%= categoria == null ? "aria-current=\"page\"" : "" %>>
            Todos
            <span class="contador"><%= totalCatalogo %></span>
        </a>

        <% for (String cat : categoriasTienda.keySet()) { %>
        <a
            class="chip"
            href="<%= urlTienda(ctx, tienda, cat, buscar, orden, ocultarAgotados) %>"
            <%= cat.equals(categoria) ? "aria-current=\"page\"" : "" %>>
            <ui:icono n="<%= Catalogo.iconoCategoria(cat, tienda) %>" clase="size-4"/>
            <%= Html.esc(cat) %>
            <span class="contador"><%= conteo.getOrDefault(cat, 0) %></span>
        </a>
        <% } %>
    </nav>

    <div class="lg:grid lg:grid-cols-[14rem_minmax(0,1fr)] lg:gap-10">

        <aside class="hidden lg:block">
            <div class="sticky top-24 space-y-6">

                <nav aria-labelledby="titulo-categorias" class="nav-lateral">
                    <h2
                        id="titulo-categorias"
                        class="mb-2 px-3 text-xs font-medium text-stone-500">
                        Categorías
                    </h2>

                    <a
                        href="<%= urlTienda(ctx, tienda, null, buscar, orden, ocultarAgotados) %>"
                        <%= categoria == null ? "aria-current=\"page\"" : "" %>>
                        <ui:icono n="apps"/>
                        Todos
                        <span class="contador"><%= totalCatalogo %></span>
                    </a>

                    <% for (String cat : categoriasTienda.keySet()) { %>
                    <a
                        href="<%= urlTienda(ctx, tienda, cat, buscar, orden, ocultarAgotados) %>"
                        <%= cat.equals(categoria) ? "aria-current=\"page\"" : "" %>>
                        <ui:icono n="<%= Catalogo.iconoCategoria(cat, tienda) %>"/>
                        <%= Html.esc(cat) %>
                        <span class="contador"><%= conteo.getOrDefault(cat, 0) %></span>
                    </a>
                    <% } %>
                </nav>

                <div class="rounded-xl bg-white p-4 text-sm ring-1 ring-stone-200">
                    <p class="font-medium text-stone-900">¿Primera compra?</p>
                    <p class="mt-1 text-stone-600">
                        Agrega productos, revisa tu carrito y confirma.
                        Tu boleta queda disponible en PDF.
                    </p>
                    <a
                        href="<%= ctx %>/jsp-Interfaz/ayuda.jsp#como-comprar"
                        class="mt-2 inline-flex items-center gap-1 font-medium hover:underline"
                        style="color: <%= colorPrimario %>;">
                        Cómo comprar
                        <ui:icono n="arrow_forward" clase="size-4"/>
                    </a>
                </div>
            </div>
        </aside>

        <section aria-labelledby="titulo-listado" data-zona-resultados>

            <div class="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
                <div>
                    <h1
                        id="titulo-listado"
                        class="text-2xl font-semibold tracking-tight text-stone-900">
                        <%= Html.esc(buscar != null
                            ? titulo
                            : categoria != null
                                ? categoria
                                : "Todos los productos") %>
                    </h1>

                    <p class="mt-1 text-sm text-stone-600">
                        <%= errorDatos
                            ? "&nbsp;"
                            : Html.plural(productos.size(), "producto", "productos") %>
                    </p>
                </div>

                <form
                    method="get"
                    action="<%= ctx %>/jsp-Interfaz/interfaz.jsp"
                    class="flex flex-wrap items-center gap-3">

                    <input type="hidden" name="tienda" value="<%= tienda %>">

                    <% if (categoria != null) { %>
                    <input
                        type="hidden"
                        name="categoria"
                        value="<%= Html.esc(categoria) %>">
                    <% } %>

                    <% if (buscar != null) { %>
                    <input
                        type="hidden"
                        name="buscar"
                        value="<%= Html.esc(buscar) %>">
                    <% } %>

                    <label class="inline-flex cursor-pointer items-center gap-2 text-sm text-stone-700">
                        <input
                            type="checkbox"
                            name="disponibles"
                            value="1"
                            class="size-4 rounded border-stone-300 accent-marca-700"
                            <%= ocultarAgotados ? "checked" : "" %>
                            data-auto-enviar>
                        Solo disponibles
                    </label>

                    <div class="flex items-center gap-2">
                        <label for="orden" class="text-sm text-stone-600">
                            Ordenar por
                        </label>

                        <select
                            id="orden"
                            name="orden"
                            class="entrada h-9 w-auto pr-8"
                            data-auto-enviar>

                            <option
                                value="relevancia"
                                <%= "relevancia".equals(orden) ? "selected" : "" %>>
                                <%= buscar != null ? "Más relevantes" : "Destacados" %>
                            </option>

                            <option
                                value="precio_asc"
                                <%= "precio_asc".equals(orden) ? "selected" : "" %>>
                                Precio: menor a mayor
                            </option>

                            <option
                                value="precio_desc"
                                <%= "precio_desc".equals(orden) ? "selected" : "" %>>
                                Precio: mayor a menor
                            </option>

                            <option
                                value="nombre"
                                <%= "nombre".equals(orden) ? "selected" : "" %>>
                                Nombre (A–Z)
                            </option>
                        </select>
                    </div>

                    <noscript>
                        <button type="submit" class="btn btn-secundario btn-sm">
                            Aplicar
                        </button>
                    </noscript>
                </form>
            </div>

            <% if (hayFiltros) { %>
            <div
                class="mt-4 flex flex-wrap items-center gap-2"
                aria-label="Filtros activos">

                <% if (buscar != null) { %>
                <a
                    href="<%= urlTienda(ctx, tienda, categoria, null, orden, ocultarAgotados) %>"
                    class="chip h-8 gap-1 pr-2 text-xs">
                    Búsqueda: «<%= Html.esc(buscar) %>»
                    <ui:icono n="close" clase="size-4 text-stone-500" etiqueta="Quitar búsqueda"/>
                </a>
                <% } %>

                <% if (categoria != null) { %>
                <a
                    href="<%= urlTienda(ctx, tienda, null, buscar, orden, ocultarAgotados) %>"
                    class="chip h-8 gap-1 pr-2 text-xs">
                    Categoría: <%= Html.esc(categoria) %>
                    <ui:icono n="close" clase="size-4 text-stone-500" etiqueta="Quitar categoría"/>
                </a>
                <% } %>

                <% if (ocultarAgotados) { %>
                <a
                    href="<%= urlTienda(ctx, tienda, categoria, buscar, orden, false) %>"
                    class="chip h-8 gap-1 pr-2 text-xs">
                    Solo disponibles
                    <ui:icono n="close" clase="size-4 text-stone-500" etiqueta="Mostrar también agotados"/>
                </a>
                <% } %>

                <a href="<%= urlBase %>" class="btn btn-fantasma btn-sm">
                    <ui:icono n="filter_alt_off" clase="size-4"/>
                    Limpiar filtros
                </a>
            </div>
            <% } %>

            <% if (errorDatos) { %>
            <div class="aviso aviso-error mt-6" role="alert">
                <ui:icono n="error"/>
                <div>
                    <p class="font-medium">No pudimos cargar los productos.</p>
                    <p class="mt-1">
                        Puede ser un problema momentáneo de conexión.
                        Inténtalo de nuevo en unos segundos.
                    </p>
                    <a
                        href="<%= Html.esc(request.getRequestURI() +
                            (request.getQueryString() != null
                                ? "?" + request.getQueryString()
                                : "")) %>"
                        class="btn btn-secundario btn-sm mt-3">
                        <ui:icono n="restart_alt" clase="size-4"/>
                        Reintentar
                    </a>
                </div>
            </div>

            <% } else if (productos.isEmpty()) { %>
            <div class="mt-10 flex flex-col items-center rounded-2xl border border-dashed border-stone-300 bg-white px-6 py-14 text-center">
                <span class="grid size-12 place-items-center rounded-full bg-stone-100 text-stone-500">
                    <ui:icono n="search_off" clase="size-6"/>
                </span>

                <h2 class="mt-4 text-base font-semibold text-stone-900">
                    No encontramos productos<%= buscar != null
                        ? " para «" + Html.esc(buscar) + "»"
                        : "" %>
                    en <%= Html.esc(nombreTienda) %>
                </h2>

                <p class="mt-1 max-w-sm text-sm text-stone-600">
                    Revisa la ortografía o busca en otra categoría.
                </p>

                <div class="mt-5 flex flex-wrap justify-center gap-2">
                    <a href="<%= urlBase %>" class="btn btn-secundario">
                        Ver todos los productos
                    </a>
                </div>
            </div>

            <% } else { %>
            <ul
                class="entrada-escalonada mt-6 grid grid-cols-2 gap-3 sm:gap-4 md:grid-cols-3 xl:grid-cols-4"
                role="list">

                <% int indice = 0;

                for (Producto p : productos) {
                    boolean agotado = p.stock <= 0;
                    int maximo = Math.max(1, Math.min(p.stock, 99));
                    String nombre = Html.esc(p.nombre);
                %>

                <li style="--i: <%= indice++ %>">
                    <article
                        class="@container flex h-full flex-col overflow-hidden rounded-xl bg-white ring-1 ring-stone-200 transition-[box-shadow,--tw-ring-color] duration-200 hover:shadow-md hover:ring-stone-300"
                        aria-labelledby="p-<%= p.id %>-nombre"
                        <%= agotado ? "data-agotado" : "" %>>

                        <div
                            class="marco-img relative grid aspect-[4/3] place-items-center overflow-hidden border-b border-stone-100 bg-white"
                            <%= p.imagen != null && !p.imagen.isEmpty()
                                ? "data-cargando"
                                : "" %>>

                            <% if (p.imagen != null && !p.imagen.trim().isEmpty()) { %>
                            <img
                                src="<%= Html.esc(util.Imagenes.url(p.imagen)) %>"
                                alt="<%= nombre %>"
                                loading="lazy"
                                decoding="async"
                                width="400"
                                height="400"
                                class="img-progresiva absolute inset-0 size-full object-contain p-3 <%= agotado ? "grayscale" : "" %>">
                            <% } else { %>
                            <div class="flex flex-col items-center gap-1 text-stone-400">
                                <ui:icono n="image" clase="size-8"/>
                                <span class="text-xs">Sin imagen</span>
                            </div>
                            <% } %>

                            <% if (agotado) { %>
                            <span class="estado estado-neutro absolute top-2 left-2">
                                Agotado
                            </span>
                            <% } else if (p.stock <= 5) { %>
                            <span class="estado estado-aviso absolute top-2 left-2">
                                Quedan <%= p.stock %>
                            </span>
                            <% } %>
                        </div>

                        <div class="flex flex-1 flex-col p-3 sm:p-4">

                            <% if (p.categoria != null) { %>
                            <p class="flex items-center gap-1 text-xs text-stone-500">
                                <ui:icono n="<%= Catalogo.iconoCategoria(p.categoria, tienda) %>" clase="size-3.5"/>
                                <%= Html.esc(p.categoria) %>
                            </p>
                            <% } %>

                            <h3
                                id="p-<%= p.id %>-nombre"
                                class="mt-1 line-clamp-2 min-h-10 text-sm leading-snug font-semibold text-stone-900 sm:text-[15px]"
                                title="<%= nombre %>">
                                <%= nombre %>
                            </h3>

                            <% if (p.descripcion != null && !p.descripcion.isEmpty()) { %>
                            <p class="mt-1 line-clamp-2 hidden text-[13px] leading-snug text-stone-600 @[13rem]:block">
                                <%= Html.esc(p.descripcion) %>
                            </p>
                            <% } %>

                            <p class="mt-2 text-lg font-semibold tabular-nums text-stone-900">
                                <%= Html.soles(p.precio) %>

                                <% if (p.unidad != null && !p.unidad.isEmpty()) { %>
                                <span class="block text-xs font-normal text-stone-500 @[13rem]:inline">
                                    / <%= Html.esc(p.unidad) %>
                                </span>
                                <% } %>
                            </p>

                            <form
                                method="post"
                                action="<%= ctx %>/agregar-carrito"
                                class="mt-auto flex flex-col gap-2 pt-3 @[15rem]:flex-row"
                                data-agregar>

                                <input type="hidden" name="id" value="<%= p.id %>">
                                <input type="hidden" name="tienda" value="<%= tienda %>">

                                <div
                                    class="flex h-10 items-center justify-between rounded-lg bg-white ring-1 ring-stone-300 ring-inset"
                                    role="group"
                                    aria-label="Cantidad de <%= nombre %>">

                                    <button
                                        type="button"
                                        class="grid h-full w-9 place-items-center rounded-l-lg text-stone-600 transition-colors hover:bg-stone-100 disabled:text-stone-300"
                                        data-paso="-1"
                                        aria-label="Quitar uno"
                                        <%= agotado ? "disabled" : "" %>>
                                        <ui:icono n="remove" clase="size-4"/>
                                    </button>

                                    <input
                                        type="number"
                                        name="cantidad"
                                        value="1"
                                        min="1"
                                        max="<%= maximo %>"
                                        inputmode="numeric"
                                        aria-label="Cantidad"
                                        <%= agotado ? "disabled" : "" %>
                                        class="h-full w-10 border-0 bg-transparent text-center text-sm font-semibold tabular-nums [appearance:textfield] focus:outline-none [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none">

                                    <button
                                        type="button"
                                        class="grid h-full w-9 place-items-center rounded-r-lg text-stone-600 transition-colors hover:bg-stone-100 disabled:text-stone-300"
                                        data-paso="1"
                                        aria-label="Agregar uno"
                                        <%= agotado ? "disabled" : "" %>>
                                        <ui:icono n="add" clase="size-4"/>
                                    </button>
                                </div>

                                <button
                                    type="submit"
                                    class="btn btn-primario flex-1 px-3 transition-[background-color,transform] duration-200"
                                    data-sin-carga
                                    <%= agotado ? "disabled" : "" %>>

                                    <span class="btn-icono" data-icono="normal">
                                        <ui:icono n="add_shopping_cart"/>
                                    </span>

                                    <ui:icono n="progress_activity" clase="btn-spinner"/>

                                    <span class="hidden" data-icono="exito">
                                        <ui:icono n="check"/>
                                    </span>

                                    <span class="btn-texto">
                                        <%= agotado ? "Agotado" : "Agregar" %>
                                    </span>
                                </button>
                            </form>

                            <p class="mt-2 min-h-4 text-xs" role="status" aria-live="polite" data-mensaje></p>
                        </div>
                    </article>
                </li>

                <% } %>
            </ul>
            <% } %>
        </section>
    </div>
</main>

<%@ include file="/WEB-INF/jspf/tienda-footer.jspf" %>
<%@ include file="/WEB-INF/jspf/fin.jspf" %>

</body>
</html>