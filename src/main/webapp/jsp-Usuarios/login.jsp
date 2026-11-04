<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.util.Map, util.Html" %>
<%
    if (session.getAttribute("correoCliente") != null) {
        response.sendRedirect(util.Rutas.volver(request, "/jsp-Interfaz/interfaz.jsp"));
        return;
    }
    Map<String, String> form = util.Flash.formulario(session);
    String errorCampo = form.get("__error");
    String volver = request.getParameter("volver");
    String titulo = "Inicia sesión";
    String subtitulo = "Para comprar y consultar tus compras.";
    String pieAuth = "<p>¿No tienes cuenta? <a class=\"font-medium text-marca-800 hover:underline\" href=\"" + ctx + "/jsp-Usuarios/registro.jsp\">Crea una gratis</a></p>";
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/auth-inicio.jspf" %>
                <form method="post" action="<%= ctx %>/login-usuario" class="space-y-5" data-validar>
                    <% if (volver != null) { %><input type="hidden" name="volver" value="<%= Html.esc(volver) %>"><% } %>
                    <ui:campo nombre="correo" etiqueta="Correo electrónico" tipo="email" icono="mail" valor='<%= form.get("correo") %>'
                              autocomplete="email" inputmode="email" placeholder="nombre@correo.com"
                              autofocus='<%= errorCampo == null ? "" : null %>'/>
                    <div class="space-y-1.5">
                        <ui:campo nombre="contrasena" etiqueta="Contraseña" tipo="password" icono="lock" autocomplete="current-password"
                                  error='<%= "contrasena".equals(errorCampo) ? form.get("__mensaje") : null %>'/>
                        <p class="text-right text-sm"><a href="<%= ctx %>/jsp-Usuarios/recuperar.jsp" class="font-medium text-marca-800 hover:underline">¿Olvidaste tu contraseña?</a></p>
                    </div>
                    <button type="submit" class="btn btn-primario btn-lg w-full" data-cargando="Ingresando…">
                        <ui:icono n="progress_activity" clase="btn-spinner"/><span class="btn-texto">Ingresar</span>
                    </button>
                </form>
<%@ include file="/WEB-INF/jspf/auth-fin.jspf" %>
</html>
