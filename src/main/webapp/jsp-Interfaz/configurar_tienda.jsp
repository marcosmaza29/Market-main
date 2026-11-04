<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ include file="/WEB-INF/jspf/comun.jspf" %>

<%
    String[] tiendasPermitidas = {"market", "juguetes", "cosmeticos"};

    // Obtener la tienda de la sesión autenticada.
    String tiendaId = (String) session.getAttribute("adminTiendaId");

    boolean autenticado =
        Boolean.TRUE.equals(session.getAttribute("adminLogueado"))
        && tiendaId != null
        && Arrays.asList(tiendasPermitidas).contains(tiendaId);

    // Si no hay sesión válida, enviar al login y guardar el destino.
    if (!autenticado) {
        String tiendaSolicitada = request.getParameter("tienda");

        if (tiendaSolicitada == null ||
            !Arrays.asList(tiendasPermitidas).contains(tiendaSolicitada)) {
            tiendaSolicitada = "market";
        }

        session.setAttribute(
            "admin.volver",
            "/jsp-Interfaz/configurar_tienda.jsp"
        );

        response.sendRedirect(
            ctx + "/jsp-Admin/loginAdmin.jsp?tienda=" + tiendaSolicitada
        );
        return;
    }

    String token = (String) session.getAttribute("configTiendaToken");

    if (token == null) {
        token = java.util.UUID.randomUUID().toString();
        session.setAttribute("configTiendaToken", token);
    }

    String nombreActual = "";
    String fuenteActual = "Inter";
    String primarioActual = "#2563EB";
    String secundarioActual = "#1D4ED8";
    String fondoActual = "#FFFFFF";
    String logoActual = "";
    String bannerActual = "";
    String errorCarga = null;

    try (
        Connection con = util.Conexion.getConnection();
        PreparedStatement ps = con.prepareStatement(
            "SELECT nombre, tipo_fuente, color_primario, " +
            "color_secundario, color_fondo, logo_url, banner_url " +
            "FROM tiendas WHERE id = ?"
        )
    ) {
        // La tienda siempre se determina mediante la sesión autenticada.
        ps.setString(1, tiendaId);

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                nombreActual = rs.getString("nombre");
                fuenteActual = rs.getString("tipo_fuente");
                primarioActual = rs.getString("color_primario");
                secundarioActual = rs.getString("color_secundario");
                fondoActual = rs.getString("color_fondo");
                logoActual = rs.getString("logo_url");
                bannerActual = rs.getString("banner_url");
            } else {
                errorCarga = "No se encontró la configuración de esta tienda.";
            }
        }
    } catch (Exception e) {
        log("Error al cargar la configuración de la tienda " + tiendaId, e);
        errorCarga = "No se pudo cargar la configuración. Inténtalo nuevamente.";
    }

    if (nombreActual == null) nombreActual = "";
    if (fuenteActual == null) fuenteActual = "Inter";

    if (primarioActual == null ||
        !primarioActual.matches("#[0-9a-fA-F]{6}")) {
        primarioActual = "#2563EB";
    }

    if (secundarioActual == null ||
        !secundarioActual.matches("#[0-9a-fA-F]{6}")) {
        secundarioActual = "#1D4ED8";
    }

    if (fondoActual == null ||
        !fondoActual.matches("#[0-9a-fA-F]{6}")) {
        fondoActual = "#FFFFFF";
    }

    if (logoActual == null) logoActual = "";
    if (bannerActual == null) bannerActual = "";

    String[] fuentesPermitidas = {
        "Inter",
        "'Segoe UI', sans-serif",
        "Georgia, serif",
        "'Comic Sans MS', cursive"
    };

    if (!Arrays.asList(fuentesPermitidas).contains(fuenteActual)) {
        fuenteActual = "Inter";
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Personalizar tienda</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            padding: 24px;
            background: #f3f4f6;
            color: #1f2937;
            font-family: Arial, sans-serif;
        }

        .contenedor {
            max-width: 760px;
            margin: 0 auto;
            padding: 28px;
            background: #ffffff;
            border-radius: 16px;
            box-shadow: 0 5px 24px #00000012;
        }

        h1 {
            margin-top: 0;
            font-size: 1.6rem;
        }

        .ayuda {
            color: #6b7280;
            font-size: .92rem;
        }

        .campo {
            margin: 20px 0;
        }

        label {
            display: block;
            margin-bottom: 7px;
            font-weight: 600;
        }

        input[type="text"],
        input[type="url"],
        select {
            width: 100%;
            min-height: 42px;
            padding: 10px;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            background: #ffffff;
        }

        input[type="color"] {
            width: 100%;
            height: 44px;
            padding: 3px;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            background: #ffffff;
            cursor: pointer;
        }

        .colores {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 16px;
        }

        .boton {
            display: inline-block;
            border: 0;
            border-radius: 8px;
            padding: 12px 18px;
            background: #2563eb;
            color: #ffffff;
            font-weight: 700;
            cursor: pointer;
            text-decoration: none;
        }

        .boton:hover {
            filter: brightness(.94);
        }

        .secundario {
            background: #e5e7eb;
            color: #111827;
        }

        .mensaje {
            padding: 12px;
            margin: 16px 0;
            border-radius: 8px;
            background: #fef2f2;
            color: #991b1b;
        }

        .vista-previa {
            margin: 20px 0;
            padding: 18px;
            border: 1px solid #e5e7eb;
            border-radius: 12px;
        }

        .vista-previa-cabecera {
            padding: 14px;
            border-radius: 8px;
            color: #ffffff;
        }

        .vista-previa-boton {
            display: inline-block;
            margin-top: 12px;
            padding: 9px 14px;
            border-radius: 7px;
            color: #ffffff;
        }

        .acciones {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 24px;
        }

        @media (max-width: 520px) {
            body {
                padding: 12px;
            }

            .contenedor {
                padding: 18px;
            }

            .acciones .boton {
                width: 100%;
                text-align: center;
            }
        }
    </style>
</head>

<body>
<div class="contenedor">
    <h1>Personalizar mi tienda</h1>
    <% for (util.Flash.Mensaje aviso : util.Flash.consumir(session)) { %>
    <p class="mensaje" role="status"><%= util.Html.esc(aviso.texto) %></p>
    <% } %>

    <p class="ayuda">
        Tienda:
        <strong><%= util.Html.esc(tiendaId) %></strong>.
        Los cambios se aplicarán únicamente a esta tienda.
    </p>

    <% if (errorCarga != null) { %>
        <div class="mensaje">
            <%= util.Html.esc(errorCarga) %>
        </div>
    <% } else { %>

    <form action="<%= ctx %>/jsp-Interfaz/guardar_configuracion.jsp"
          method="post">

        <input type="hidden"
               name="token"
               value="<%= util.Html.esc(token) %>">

        <div class="campo">
            <label for="nombre">Nombre del negocio</label>
            <input
                id="nombre"
                type="text"
                name="nombre"
                maxlength="100"
                required
                value="<%= util.Html.esc(nombreActual) %>">
        </div>

        <div class="campo">
            <label for="fuente">Tipografía</label>
            <select id="fuente" name="fuente">
                <option value="Inter"
                    <%= "Inter".equals(fuenteActual) ? "selected" : "" %>>
                    Inter — moderna
                </option>

                <option value="'Segoe UI', sans-serif"
                    <%= "'Segoe UI', sans-serif".equals(fuenteActual) ? "selected" : "" %>>
                    Segoe UI — sencilla
                </option>

                <option value="Georgia, serif"
                    <%= "Georgia, serif".equals(fuenteActual) ? "selected" : "" %>>
                    Georgia — elegante
                </option>

                <option value="'Comic Sans MS', cursive"
                    <%= "'Comic Sans MS', cursive".equals(fuenteActual) ? "selected" : "" %>>
                    Comic Sans — divertida
                </option>
            </select>
        </div>

        <div class="colores">
            <div class="campo">
                <label for="primario">Color principal</label>
                <input
                    id="primario"
                    type="color"
                    name="color_primario"
                    value="<%= primarioActual %>">
            </div>

            <div class="campo">
                <label for="secundario">Color secundario</label>
                <input
                    id="secundario"
                    type="color"
                    name="color_secundario"
                    value="<%= secundarioActual %>">
            </div>

            <div class="campo">
                <label for="fondo">Color de fondo</label>
                <input
                    id="fondo"
                    type="color"
                    name="color_fondo"
                    value="<%= fondoActual %>">
            </div>
        </div>

        <div class="vista-previa" id="vistaPrevia">
            <div class="vista-previa-cabecera" id="previaCabecera">
                <strong id="previaNombre"><%= util.Html.esc(nombreActual) %></strong>
                <div>Vista previa de tu tienda</div>
            </div>

            <span class="vista-previa-boton" id="previaBoton">
                Botón de ejemplo
            </span>
        </div>

        <div class="campo">
            <label for="logo">URL del logo (opcional)</label>
            <input
                id="logo"
                type="url"
                name="logo_url"
                maxlength="1000"
                value="<%= util.Html.esc(logoActual) %>"
                placeholder="https://...">

            <p class="ayuda">
                Introduce un enlace HTTPS público a la imagen.
            </p>
        </div>

        <div class="campo">
            <label for="banner">URL del banner (opcional)</label>
            <input
                id="banner"
                type="url"
                name="banner_url"
                maxlength="1000"
                value="<%= util.Html.esc(bannerActual) %>"
                placeholder="https://...">

            <p class="ayuda">
                Introduce un enlace HTTPS público a la imagen.
            </p>
        </div>

        <div class="acciones">
            <button class="boton" type="submit">
                Guardar personalización
            </button>

            <a class="boton secundario"
               href="<%= ctx %>/jsp-Interfaz/interfaz.jsp?tienda=<%= tiendaId %>">
                Ver mi tienda
            </a>
        </div>
    </form>

    <% } %>
</div>

<script>
(function () {
    const nombre = document.getElementById('nombre');
    const primario = document.getElementById('primario');
    const secundario = document.getElementById('secundario');
    const fondo = document.getElementById('fondo');
    const fuente = document.getElementById('fuente');

    const previaNombre = document.getElementById('previaNombre');
    const previaCabecera = document.getElementById('previaCabecera');
    const previaBoton = document.getElementById('previaBoton');
    const vistaPrevia = document.getElementById('vistaPrevia');

    function actualizar() {
        if (!nombre || !primario || !secundario ||
            !fondo || !fuente || !previaNombre ||
            !previaCabecera || !previaBoton || !vistaPrevia) {
            return;
        }

        previaNombre.textContent = nombre.value;
        previaCabecera.style.backgroundColor = primario.value;
        previaBoton.style.backgroundColor = secundario.value;
        vistaPrevia.style.backgroundColor = fondo.value;
        vistaPrevia.style.fontFamily = fuente.value;
    }

    [nombre, primario, secundario, fondo, fuente].forEach(
        function (elemento) {
            if (elemento) {
                elemento.addEventListener('input', actualizar);
                elemento.addEventListener('change', actualizar);
            }
        }
    );

    actualizar();
})();
</script>

</body>
</html>