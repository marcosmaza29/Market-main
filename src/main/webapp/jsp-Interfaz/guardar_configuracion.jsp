<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, java.net.URI, java.nio.charset.StandardCharsets, java.security.MessageDigest" %>
<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%
    // Aceptar únicamente solicitudes POST
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        return;
    }

    request.setCharacterEncoding("UTF-8");

    // Validar sesión y tienda del administrador
    String[] tiendasPermitidas = {"market", "juguetes", "cosmeticos"};
    String tiendaId = (String) session.getAttribute("adminTiendaId");

    boolean autenticado =
        Boolean.TRUE.equals(session.getAttribute("adminLogueado"))
        && tiendaId != null
        && Arrays.asList(tiendasPermitidas).contains(tiendaId);

    if (!autenticado) {
        response.sendError(
            HttpServletResponse.SC_FORBIDDEN,
            "Debes iniciar sesión como administrador."
        );
        return;
    }

    // Validar token del formulario
    String tokenSesion =
        (String) session.getAttribute("configTiendaToken");

    String tokenFormulario = request.getParameter("token");

    if (tokenSesion == null
            || tokenFormulario == null
            || !MessageDigest.isEqual(
                tokenSesion.getBytes(StandardCharsets.UTF_8),
                tokenFormulario.getBytes(StandardCharsets.UTF_8)
            )) {

        response.sendError(
            HttpServletResponse.SC_FORBIDDEN,
            "El formulario ha caducado. Vuelve a abrir la configuración."
        );
        return;
    }

    // Obtener los datos enviados
    String nombre = request.getParameter("nombre");
    String fuente = request.getParameter("fuente");
    String primario = request.getParameter("color_primario");
    String secundario = request.getParameter("color_secundario");
    String fondo = request.getParameter("color_fondo");
    String logo = request.getParameter("logo_url");
    String banner = request.getParameter("banner_url");

    // Normalizar los valores recibidos
    nombre = nombre == null ? "" : nombre.trim();
    fuente = fuente == null ? "" : fuente.trim();
    primario = primario == null ? "" : primario.trim();
    secundario = secundario == null ? "" : secundario.trim();
    fondo = fondo == null ? "" : fondo.trim();
    logo = logo == null ? "" : logo.trim();
    banner = banner == null ? "" : banner.trim();

    // Validar tipografías permitidas
    String[] fuentesPermitidas = {
        "Inter",
        "'Segoe UI', sans-serif",
        "Georgia, serif",
        "'Comic Sans MS', cursive"
    };

    boolean fuenteValida =
        Arrays.asList(fuentesPermitidas).contains(fuente);

    // Validar colores HEX
    boolean coloresValidos =
        primario.matches("#[0-9a-fA-F]{6}")
        && secundario.matches("#[0-9a-fA-F]{6}")
        && fondo.matches("#[0-9a-fA-F]{6}");

    // Validar nombre y longitud de las URL
    boolean nombreValido =
        !nombre.isEmpty() && nombre.length() <= 100;

    boolean urlsValidas =
        logo.length() <= 1000 && banner.length() <= 1000;

    // Permitir solamente URL HTTPS válidas para logo y banner
    try {
        if (!logo.isEmpty()) {
            URI uriLogo = new URI(logo);

            urlsValidas = urlsValidas
                && "https".equalsIgnoreCase(uriLogo.getScheme())
                && uriLogo.getHost() != null;
        }

        if (!banner.isEmpty()) {
            URI uriBanner = new URI(banner);

            urlsValidas = urlsValidas
                && "https".equalsIgnoreCase(uriBanner.getScheme())
                && uriBanner.getHost() != null;
        }
    } catch (Exception e) {
        urlsValidas = false;
    }

    // Rechazar datos inválidos
    if (!nombreValido || !coloresValidos
            || !fuenteValida || !urlsValidas) {

        response.sendError(
            HttpServletResponse.SC_BAD_REQUEST,
            "Revisa el nombre, los colores, la tipografía y las URL HTTPS."
        );
        return;
    }

    // Actualizar exclusivamente la tienda de la sesión autenticada
    try (
        Connection con = util.Conexion.getConnection();
        PreparedStatement ps = con.prepareStatement(
            "UPDATE tiendas SET nombre = ?, tipo_fuente = ?, " +
            "color_primario = ?, color_secundario = ?, color_fondo = ?, " +
            "logo_url = ?, banner_url = ?, personalizacion_completa = TRUE, " +
            "actualizado_en = CURRENT_TIMESTAMP WHERE id = ?"
        )
    ) {
        ps.setString(1, nombre);
        ps.setString(2, fuente);
        ps.setString(3, primario);
        ps.setString(4, secundario);
        ps.setString(5, fondo);
        ps.setString(6, logo.isEmpty() ? null : logo);
        ps.setString(7, banner.isEmpty() ? null : banner);
        ps.setString(8, tiendaId);

        int actualizadas = ps.executeUpdate();

        if (actualizadas != 1) {
            response.sendError(
                HttpServletResponse.SC_NOT_FOUND,
                "No se encontró la tienda que debes configurar."
            );
            return;
        }

        // Invalidar el token para impedir su reutilización
        session.removeAttribute("configTiendaToken");

        // Volver a la configuración de la tienda autenticada
        response.sendRedirect(
            ctx + "/jsp-Interfaz/configurar_tienda.jsp?tienda=" + tiendaId
        );

    } catch (Exception e) {
        log("Error al guardar configuración de la tienda " + tiendaId, e);

        util.Flash.error(session, "No se pudo guardar la configuración. Comprueba la actualización de la base y vuelve a intentar.");
        response.sendRedirect(ctx + "/jsp-Interfaz/configurar_tienda.jsp?tienda=" + tiendaId);
    }
%>