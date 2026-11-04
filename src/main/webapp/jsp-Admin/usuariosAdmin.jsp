<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, java.security.SecureRandom, java.util.Base64, util.Html, util.Flash" %>
<%
    String tiendaId = (String) session.getAttribute("adminTiendaId");
    String titulo = "Usuarios";
    String seccion = "usuarios";

    // Crear token de seguridad para el formulario
    String csrf = (String) session.getAttribute("csrf.admin.usuarios");

    if (csrf == null) {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        csrf = Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(bytes);

        session.setAttribute("csrf.admin.usuarios", csrf);
    }

    Map<String, String> form = Flash.formulario(session);
    String errorCampo = form.get("__error");
    String errorMsg = form.get("__mensaje");

    List<Map<String, Object>> usuarios = new ArrayList<>();
    boolean errorDatos = false;

    // Consultar las cuentas registradas
    try (
        Connection con = util.Conexion.getConnection();
        PreparedStatement ps = con.prepareStatement(
            "SELECT id, nombre, apellidos, correo " +
            "FROM usuarios WHERE tienda_id = ? ORDER BY id DESC LIMIT 300"
        )
    ) {
        ps.setString(1, tiendaId);
        try (ResultSet rs = ps.executeQuery()) {
        while (rs.next()) {
            Map<String, Object> u = new HashMap<>();
            u.put("id", rs.getInt("id"));
            u.put("nombre", rs.getString("nombre"));
            u.put("apellidos", rs.getString("apellidos"));
            u.put("correo", rs.getString("correo"));
            usuarios.add(u);
        }
        }
    } catch (Exception e) {
        log("Error al listar usuarios desde el panel", e);
        errorDatos = true;
    }
%>

<!DOCTYPE html>
<html lang="es">

<head>
    <%@ include file="/WEB-INF/jspf/head.jspf" %>
</head>

<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>

<div class="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
    <div>
        <h1 class="text-2xl font-semibold tracking-tight text-stone-900">
            Creación de usuarios
        </h1>

        <p class="mt-1 text-sm text-stone-600">
            Registra cuentas de clientes y consulta las cuentas existentes.
        </p>
    </div>

    <span class="text-sm text-stone-500">
        Se muestran hasta 300 cuentas
    </span>
</div>

<!-- Formulario para crear usuarios -->
<section class="tarjeta mt-6 p-4 sm:p-6"
         aria-labelledby="titulo-crear">

    <h2 id="titulo-crear"
        class="text-lg font-semibold text-stone-900">
        Crear una cuenta
    </h2>

    <p class="mt-1 text-sm text-stone-600">
        La contraseña se guarda protegida mediante BCrypt.
    </p>

    <form method="post"
          action="<%= ctx %>/admin/crear-usuario"
          class="mt-5 grid gap-4 sm:grid-cols-2"
          autocomplete="off">

        <input type="hidden"
               name="csrf"
               value="<%= Html.esc(csrf) %>">

        <!-- Nombre -->
        <div class="campo">
            <label for="nombre"
                   class="text-sm font-medium text-stone-700">
                Nombre
            </label>

            <input id="nombre"
                   name="nombre"
                   required
                   maxlength="100"
                   class="entrada"
                   value="<%= Html.esc(form.get("nombre")) %>"
                   autocomplete="given-name">

            <% if ("nombre".equals(errorCampo)) { %>
                <p class="mt-1 text-sm text-red-700">
                    <%= Html.esc(errorMsg) %>
                </p>
            <% } %>
        </div>

        <!-- Apellidos -->
        <div class="campo">
            <label for="apellidos"
                   class="text-sm font-medium text-stone-700">
                Apellidos
            </label>

            <input id="apellidos"
                   name="apellidos"
                   required
                   maxlength="100"
                   class="entrada"
                   value="<%= Html.esc(form.get("apellidos")) %>"
                   autocomplete="family-name">

            <% if ("apellidos".equals(errorCampo)) { %>
                <p class="mt-1 text-sm text-red-700">
                    <%= Html.esc(errorMsg) %>
                </p>
            <% } %>
        </div>

        <!-- Correo -->
        <div class="campo sm:col-span-2">
            <label for="correo"
                   class="text-sm font-medium text-stone-700">
                Correo electrónico
            </label>

            <input id="correo"
                   name="correo"
                   type="email"
                   required
                   maxlength="100"
                   class="entrada"
                   value="<%= Html.esc(form.get("correo")) %>"
                   autocomplete="email">

            <% if ("correo".equals(errorCampo)) { %>
                <p class="mt-1 text-sm text-red-700">
                    <%= Html.esc(errorMsg) %>
                </p>
            <% } %>
        </div>

        <!-- Contraseña -->
        <div class="campo">
            <label for="contrasena"
                   class="text-sm font-medium text-stone-700">
                Contraseña temporal
            </label>

            <input id="contrasena"
                   name="contrasena"
                   type="password"
                   required
                   minlength="8"
                   pattern="(?=.*[A-Za-z])(?=.*[0-9]).{8,}"
                   class="entrada"
                   autocomplete="new-password">

            <p class="mt-1 text-xs text-stone-500">
                Mínimo 8 caracteres, una letra y un número.
            </p>

            <% if ("contrasena".equals(errorCampo)) { %>
                <p class="mt-1 text-sm text-red-700">
                    <%= Html.esc(errorMsg) %>
                </p>
            <% } %>
        </div>

        <!-- Confirmación -->
        <div class="campo">
            <label for="confirmar"
                   class="text-sm font-medium text-stone-700">
                Confirmar contraseña
            </label>

            <input id="confirmar"
                   name="confirmar"
                   type="password"
                   required
                   minlength="8"
                   class="entrada"
                   autocomplete="new-password">

            <% if ("confirmar".equals(errorCampo)) { %>
                <p class="mt-1 text-sm text-red-700">
                    <%= Html.esc(errorMsg) %>
                </p>
            <% } %>
        </div>

        <div class="sm:col-span-2">
            <button type="submit"
                    class="btn btn-primario">
                <ui:icono n="person_add" clase="size-4"/>
                Crear usuario
            </button>
        </div>

    </form>
</section>

<!-- Lista de usuarios registrados -->
<section class="tarjeta mt-6"
         aria-labelledby="titulo-lista">

    <div class="border-b border-stone-200 p-4 sm:p-5">
        <h2 id="titulo-lista"
            class="font-semibold text-stone-900">
            Cuentas registradas
        </h2>
    </div>

    <% if (errorDatos) { %>

        <div class="aviso aviso-error m-4" role="alert">
            No pudimos consultar los usuarios.
            Revisa la conexión a la base de datos.
        </div>

    <% } else if (usuarios.isEmpty()) { %>

        <p class="p-6 text-sm text-stone-600">
            Todavía no hay cuentas registradas.
        </p>

    <% } else { %>

        <div class="overflow-x-auto">
            <table class="tabla tabla-responsiva">

                <thead>
                    <tr>
                        <th scope="col">ID</th>
                        <th scope="col">Nombre</th>
                        <th scope="col">Correo</th>
                    </tr>
                </thead>

                <tbody>
                    <% for (Map<String, Object> u : usuarios) { %>

                        <tr>
                            <td data-etiqueta="ID">
                                <%= u.get("id") %>
                            </td>

                            <td data-etiqueta="Nombre">
                                <%= Html.esc(u.get("nombre")) %>
                                <%= Html.esc(u.get("apellidos")) %>
                            </td>

                            <td data-etiqueta="Correo"
                                class="break-all">
                                <%= Html.esc(u.get("correo")) %>
                            </td>
                        </tr>

                    <% } %>
                </tbody>

            </table>
        </div>

    <% } %>

</section>

<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>

</html>