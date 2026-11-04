<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.Map, util.Flash" %>
<%
    String correo = (String) session.getAttribute("correoCliente");
    if (correo == null) {
        Flash.info(session, "Inicia sesión para editar tu cuenta.");
        response.sendRedirect(ctx + "/jsp-Usuarios/login.jsp?volver=" + java.net.URLEncoder.encode("/jsp-Usuarios/editarUsuario.jsp", "UTF-8"));
        return;
    }
    String titulo = "Mi cuenta";
    Map<String, String> form = Flash.formulario(session);
    String errorCampo = form.get("__error");
    String errorMsg = form.get("__mensaje");

    // Datos actuales desde la base (no se deducen partiendo el nombre completo)
    String nombre = "", apellidos = "";
    try (Connection con = util.Conexion.getConnection();
         PreparedStatement ps = con.prepareStatement("SELECT nombre, apellidos FROM usuarios WHERE lower(correo) = lower(?)")) {
        ps.setString(1, correo);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                nombre = rs.getString("nombre");
                apellidos = rs.getString("apellidos");
            }
        }
    } catch (Exception e) {
        log("No se pudo cargar la cuenta", e);
    }
    if (form.containsKey("nombre")) nombre = form.get("nombre");
    if (form.containsKey("apellidos")) apellidos = form.get("apellidos");
    String correoForm = form.containsKey("correo") ? form.get("correo") : correo;
    boolean abrirContrasena = "contrasena".equals(errorCampo) || "confirmar".equals(errorCampo);
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<body class="min-h-dvh">
<%@ include file="/WEB-INF/jspf/tienda-header.jspf" %>

<main id="contenido" class="contenedor max-w-2xl pt-8">
    <h1 class="text-2xl font-semibold tracking-tight text-stone-900">Mi cuenta</h1>
    <p class="mt-1 text-sm text-stone-600">Actualiza tus datos. Los cambios se aplican al guardar.</p>

    <form method="post" action="<%= ctx %>/editar-usuario" class="mt-6 space-y-6" data-validar data-avisar-cambios>
        <section class="tarjeta" aria-labelledby="h-datos">
            <div class="border-b border-stone-200 px-4 py-4 sm:px-6">
                <h2 id="h-datos" class="font-semibold text-stone-900">Datos personales</h2>
            </div>
            <div class="tarjeta-cuerpo space-y-5">
                <div class="grid gap-5 sm:grid-cols-2">
                    <ui:campo nombre="nombre" etiqueta="Nombres" valor="<%= nombre %>" autocomplete="given-name" maxlength="100"
                              error='<%= "nombre".equals(errorCampo) ? errorMsg : null %>'/>
                    <ui:campo nombre="apellidos" etiqueta="Apellidos" valor="<%= apellidos %>" autocomplete="family-name" maxlength="100"
                              error='<%= "apellidos".equals(errorCampo) ? errorMsg : null %>'/>
                </div>
                <ui:campo nombre="correo" etiqueta="Correo electrónico" tipo="email" icono="mail" valor="<%= correoForm %>"
                          autocomplete="email" inputmode="email" maxlength="100" ayuda="Si lo cambias, úsalo la próxima vez que inicies sesión."
                          error='<%= "correo".equals(errorCampo) ? errorMsg : null %>'/>
            </div>
        </section>

        <details class="group tarjeta" <%= abrirContrasena ? "open" : "" %>>
            <summary class="flex cursor-pointer list-none items-center justify-between gap-4 px-4 py-4 sm:px-6 [&::-webkit-details-marker]:hidden">
                <span>
                    <span class="block font-semibold text-stone-900">Cambiar contraseña</span>
                    <span class="block text-sm text-stone-600">Opcional. Si no lo abres, tu contraseña actual se mantiene.</span>
                </span>
                <ui:icono n="expand_more" clase="text-stone-500 transition-transform duration-200 group-open:rotate-180"/>
            </summary>
            <div class="space-y-5 border-t border-stone-200 px-4 py-5 sm:px-6">
                <ui:campo nombre="contrasena" etiqueta="Nueva contraseña" tipo="password" icono="lock" autocomplete="new-password" opcional="true"
                          minlength="8" pattern="(?=.*[A-Za-z])(?=.*[0-9]).{8,}" data-msg-formato="Incluye al menos una letra y un número."
                          error='<%= "contrasena".equals(errorCampo) ? errorMsg : null %>'/>
                <ui:reglas para="contrasena"/>
                <ui:campo nombre="confirmar" etiqueta="Repite la nueva contraseña" tipo="password" icono="lock" autocomplete="new-password" opcional="true"
                          data-coincide-con="contrasena"
                          error='<%= "confirmar".equals(errorCampo) ? errorMsg : null %>'/>
            </div>
        </details>

        <div class="flex flex-col-reverse gap-3 sm:flex-row sm:items-center sm:justify-end">
            <p class="text-sm text-amber-800 sm:mr-auto" data-indicador-cambios hidden>Tienes cambios sin guardar.</p>
            <a href="<%= ctx %>/jsp-Interfaz/interfaz.jsp" class="btn btn-secundario">Cancelar</a>
            <button type="submit" class="btn btn-primario" data-cargando="Guardando…">
                <span class="btn-icono"><ui:icono n="check"/></span><ui:icono n="progress_activity" clase="btn-spinner"/><span class="btn-texto">Guardar cambios</span>
            </button>
        </div>
    </form>
</main>

<%@ include file="/WEB-INF/jspf/tienda-footer.jspf" %>
<%@ include file="/WEB-INF/jspf/fin.jspf" %>
</body>
</html>
