<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Flash" %>
<%
    // Identificar y validar la tienda solicitada.
    String tiendaSolicitada = request.getParameter("tienda");

    if (tiendaSolicitada == null || tiendaSolicitada.trim().isEmpty()) {
        tiendaSolicitada = contextoTienda;
    }

    String[] tiendasPermitidas = {"market", "juguetes", "cosmeticos"};

    if (!Arrays.asList(tiendasPermitidas).contains(tiendaSolicitada)) {
        response.sendError(
            HttpServletResponse.SC_BAD_REQUEST,
            "Tienda no válida."
        );
        return;
    }

    // Comprobar si existe una sesión de administrador.
    String tiendaSesion = (String) session.getAttribute("adminTiendaId");

    if (Boolean.TRUE.equals(session.getAttribute("adminLogueado"))) {
        if (tiendaSolicitada.equals(tiendaSesion)) {
            response.sendRedirect(
                ctx + "/jsp-Productos/producto.jsp?tienda=" + tiendaSolicitada
            );
            return;
        }

        // Una sesión de otra tienda no puede utilizarse aquí.
        session.removeAttribute("adminLogueado");
        session.removeAttribute("adminTiendaId");
        session.removeAttribute("adminUsuario");
        session.removeAttribute("admin.volver");
    }

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String usuario = request.getParameter("usuario") == null
                ? "" : request.getParameter("usuario").trim();

        String clave = request.getParameter("clave") == null
                ? "" : request.getParameter("clave");

        boolean valido = false;
        boolean errorConexion = false;
        String tiendaId = null;

        try (
            Connection conn = util.Conexion.getConnection();
            PreparedStatement ps = conn.prepareStatement(
                "SELECT clave, tienda_id FROM admin "
                + "WHERE usuario = ? AND tienda_id = ?"
            )
        ) {
            ps.setString(1, usuario);
            ps.setString(2, tiendaSolicitada);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    try {
                        valido = util.PasswordUtil.checkPassword(
                            clave,
                            rs.getString("clave")
                        );

                        if (valido) {
                            tiendaId = rs.getString("tienda_id");

                            if (tiendaId == null
                                    || !Arrays.asList(tiendasPermitidas)
                                              .contains(tiendaId)) {
                                valido = false;
                            }
                        }
                    } catch (IllegalArgumentException hashInvalido) {
                        valido = false;
                    }
                }
            }
        } catch (Exception e) {
            log("Error en el inicio de sesión del administrador", e);
            errorConexion = true;
        }

        if (valido) {
            // Recuperar la ruta antes de invalidar la sesión anterior.
            String volver = (String) session.getAttribute("admin.volver");

            // Evitar conservar atributos de la sesión anterior.
            session.invalidate();

            HttpSession nueva = request.getSession(true);
            nueva.setAttribute("adminLogueado", true);
            nueva.setAttribute("adminUsuario", usuario);
            nueva.setAttribute("adminTiendaId", tiendaId);

            Flash.exito(nueva, "Bienvenido, " + usuario + ".");

            // Solo permitir destinos internos conocidos.
            boolean destinoConfiguracion =
                "/jsp-Interfaz/configurar_tienda.jsp".equals(volver);

            boolean destinoAdministrativo =
                volver != null
                && volver.matches(
                    "^/jsp-(Productos|Proveedores|Admin)/[A-Za-z]+\\.jsp(\\?.*)?$"
                );

            if (destinoConfiguracion) {
                // La tienda procede de las credenciales autenticadas.
                response.sendRedirect(
                    ctx + "/jsp-Interfaz/configurar_tienda.jsp?tienda="
                    + tiendaId
                );
            } else if (destinoAdministrativo) {
                response.sendRedirect(ctx + volver.split("\\?", 2)[0] + "?tienda=" + tiendaId);
            } else {
                // Destino predeterminado del panel administrativo.
                response.sendRedirect(
                    ctx + "/jsp-Productos/producto.jsp?tienda=" + tiendaId
                );
            }
        } else {
            if (errorConexion) {
                Flash.error(
                    session,
                    "No pudimos conectarnos a la base de datos. "
                    + "Inténtalo de nuevo en unos segundos."
                );

                Flash.formulario(
                    session,
                    request.getParameterMap(),
                    null
                );
            } else {
                Flash.formulario(
                    session,
                    request.getParameterMap(),
                    "clave",
                    "El usuario o la contraseña no son correctos."
                );
            }

            response.sendRedirect(
                ctx + "/jsp-Admin/loginAdmin.jsp?tienda=" + tiendaSolicitada
            );
        }

        return;
    }

    Map<String, String> form = Flash.formulario(session);
    String errorCampo = form.get("__error");
    String titulo = "Administración · " + util.Tienda.nombre(tiendaSolicitada);
    String subtitulo = "Ingresa con tu usuario de administrador.";

    String pieAuth = "<p>¿Eres cliente? <a "
        + "class=\"font-medium text-marca-800 hover:underline\" href=\""
        + ctx
        + "/jsp-Usuarios/login.jsp\">Inicia sesión en la tienda</a></p>";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <%@ include file="/WEB-INF/jspf/head.jspf" %>
</head>

<%@ include file="/WEB-INF/jspf/auth-inicio.jspf" %>

<form method="post"
      action="<%= ctx %>/jsp-Admin/loginAdmin.jsp?tienda=<%= tiendaSolicitada %>"
      class="space-y-5"
      data-validar>

    <ui:campo
        nombre="usuario"
        etiqueta="Usuario"
        icono="admin_panel_settings"
        valor='<%= form.get("usuario") %>'
        autocomplete="username"
        autocapitalize="none"
        spellcheck="false"
        autofocus='<%= errorCampo == null ? "" : null %>' />

    <ui:campo
        nombre="clave"
        etiqueta="Contraseña"
        tipo="password"
        icono="key"
        autocomplete="current-password"
        error='<%= "clave".equals(errorCampo) ? form.get("__mensaje") : null %>' />

    <button type="submit"
            class="btn btn-primario btn-lg w-full"
            data-cargando="Ingresando…">
        <ui:icono n="progress_activity" clase="btn-spinner" />
        <span class="btn-texto">Ingresar al panel</span>
    </button>
</form>

<%@ include file="/WEB-INF/jspf/auth-fin.jspf" %>
</html>
