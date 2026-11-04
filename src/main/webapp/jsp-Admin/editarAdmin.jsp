<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Flash, util.PasswordUtil" %>
<%
    String urlForm = ctx + "/jsp-Admin/editarAdmin.jsp";
    String usuarioSesion = (String) session.getAttribute("adminUsuario");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String nuevoUsuario = request.getParameter("nuevo_usuario") == null ? "" : request.getParameter("nuevo_usuario").trim();
        String actual = request.getParameter("clave_actual") == null ? "" : request.getParameter("clave_actual");
        String nueva = request.getParameter("nueva_clave") == null ? "" : request.getParameter("nueva_clave");
        String confirmar = request.getParameter("confirmar_clave") == null ? "" : request.getParameter("confirmar_clave");
        boolean cambiaClave = !nueva.isEmpty();

        String campo = null, mensaje = null;
        if (nuevoUsuario.length() < 3) { campo = "nuevo_usuario"; mensaje = "El usuario debe tener al menos 3 caracteres."; }
        else if (actual.isEmpty()) { campo = "clave_actual"; mensaje = "Escribe tu contraseña actual para confirmar los cambios."; }
        else if (cambiaClave && (nueva.length() < 8 || !nueva.matches(".*[A-Za-z].*") || !nueva.matches(".*[0-9].*"))) { campo = "nueva_clave"; mensaje = "La nueva contraseña necesita al menos 8 caracteres, una letra y un número."; }
        else if (cambiaClave && !nueva.equals(confirmar)) { campo = "confirmar_clave"; mensaje = "Las contraseñas no coinciden."; }
        if (campo != null) {
            Flash.formulario(session, request.getParameterMap(), campo, mensaje);
            response.sendRedirect(urlForm);
            return;
        }

        try (Connection conn = util.Conexion.getConnection()) {
            int id = -1; String hash = null;
            try (PreparedStatement ps = conn.prepareStatement("SELECT id, clave FROM admin WHERE usuario = ? AND tienda_id = ?")) {
                ps.setString(1, usuarioSesion);
                ps.setString(2, (String) session.getAttribute("adminTiendaId"));
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) { id = rs.getInt(1); hash = rs.getString(2); } }
            }
            boolean ok = false;
            try { ok = hash != null && PasswordUtil.checkPassword(actual, hash); } catch (IllegalArgumentException ignorada) { }
            if (!ok) {
                Flash.formulario(session, request.getParameterMap(), "clave_actual", "La contraseña actual no es correcta.");
                response.sendRedirect(urlForm);
                return;
            }
            try (PreparedStatement ps = conn.prepareStatement(cambiaClave
                    ? "UPDATE admin SET usuario = ?, clave = ? WHERE id = ?"
                    : "UPDATE admin SET usuario = ? WHERE id = ?")) {
                ps.setString(1, nuevoUsuario);
                if (cambiaClave) { ps.setString(2, PasswordUtil.hashPassword(nueva)); ps.setInt(3, id); } else { ps.setInt(2, id); }
                ps.executeUpdate();
            }
            session.setAttribute("adminUsuario", nuevoUsuario);
            Flash.exito(session, cambiaClave ? "Guardaste tu usuario y tu nueva contraseña." : "Guardaste tu usuario.");
        } catch (Exception e) {
            log("Error al actualizar la cuenta del administrador", e);
            Flash.error(session, "No pudimos guardar los cambios. Inténtalo de nuevo.");
            Flash.formulario(session, request.getParameterMap(), null);
        }
        response.sendRedirect(urlForm);
        return;
    }

    String titulo = "Mi cuenta";
    String seccion = "cuenta";
    Map<String, String> form = Flash.formulario(session);
    String errorCampo = form.get("__error");
    String errorMsg = form.get("__mensaje");
    String usuarioForm = form.containsKey("nuevo_usuario") ? form.get("nuevo_usuario") : usuarioSesion;
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
    <h1 class="text-2xl font-semibold tracking-tight text-stone-900">Mi cuenta</h1>
    <p class="mt-1 text-sm text-stone-600">Usuario y contraseña con los que entras al panel.</p>

    <form method="post" action="<%= urlForm %>" class="mt-6 max-w-2xl space-y-6" data-validar data-avisar-cambios>
        <section class="tarjeta" aria-labelledby="h-acceso">
            <div class="border-b border-stone-200 px-4 py-4 sm:px-6"><h2 id="h-acceso" class="font-semibold text-stone-900">Datos de acceso</h2></div>
            <div class="tarjeta-cuerpo space-y-5">
                <ui:campo nombre="nuevo_usuario" etiqueta="Usuario" icono="admin_panel_settings" valor='<%= usuarioForm %>' minlength="3" maxlength="100"
                          autocomplete="username" autocapitalize="none" spellcheck="false"
                          error='<%= "nuevo_usuario".equals(errorCampo) ? errorMsg : null %>'/>
            </div>
        </section>

        <details class="group tarjeta" <%= "nueva_clave".equals(errorCampo) || "confirmar_clave".equals(errorCampo) ? "open" : "" %>>
            <summary class="flex cursor-pointer list-none items-center justify-between gap-4 px-4 py-4 sm:px-6 [&::-webkit-details-marker]:hidden">
                <span><span class="block font-semibold text-stone-900">Cambiar contraseña</span><span class="block text-sm text-stone-600">Opcional. Si lo dejas cerrado, tu contraseña se mantiene.</span></span>
                <ui:icono n="expand_more" clase="text-stone-500 transition-transform duration-200 group-open:rotate-180"/>
            </summary>
            <div class="space-y-5 border-t border-stone-200 px-4 py-5 sm:px-6">
                <ui:campo nombre="nueva_clave" etiqueta="Nueva contraseña" tipo="password" icono="lock" autocomplete="new-password" opcional="true"
                          minlength="8" pattern="(?=.*[A-Za-z])(?=.*[0-9]).{8,}" data-msg-formato="Incluye al menos una letra y un número."
                          error='<%= "nueva_clave".equals(errorCampo) ? errorMsg : null %>'/>
                <ui:reglas para="nueva_clave"/>
                <ui:campo nombre="confirmar_clave" etiqueta="Repite la nueva contraseña" tipo="password" icono="lock" autocomplete="new-password" opcional="true"
                          data-coincide-con="nueva_clave" error='<%= "confirmar_clave".equals(errorCampo) ? errorMsg : null %>'/>
            </div>
        </details>

        <section class="tarjeta" aria-labelledby="h-confirmar">
            <div class="tarjeta-cuerpo space-y-5">
                <h2 id="h-confirmar" class="sr-only">Confirmar cambios</h2>
                <ui:campo nombre="clave_actual" etiqueta="Contraseña actual" tipo="password" icono="key" autocomplete="current-password"
                          ayuda="Por seguridad, la pedimos para guardar cualquier cambio."
                          error='<%= "clave_actual".equals(errorCampo) ? errorMsg : null %>'/>
            </div>
            <div class="flex flex-col-reverse gap-3 border-t border-stone-200 bg-stone-50 px-4 py-4 sm:flex-row sm:items-center sm:justify-end sm:px-6">
                <p class="text-sm text-amber-800 sm:mr-auto" data-indicador-cambios hidden>Tienes cambios sin guardar.</p>
                <a href="<%= ctx %>/jsp-Productos/producto.jsp" class="btn btn-secundario">Cancelar</a>
                <button type="submit" class="btn btn-primario" data-cargando="Guardando…">
                    <span class="btn-icono"><ui:icono n="check"/></span><ui:icono n="progress_activity" clase="btn-spinner"/><span class="btn-texto">Guardar cambios</span>
                </button>
            </div>
        </section>
    </form>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
