<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.util.Map" %>
<%
    Map<String, String> form = util.Flash.formulario(session);
    String errorCampo = form.get("__error");
    String errorMsg = form.get("__mensaje");
    String titulo = "Crea una nueva contraseña";
    String subtitulo = "Escribe el correo de tu cuenta y elige una contraseña nueva.";
    String pieAuth = "<p><a class=\"inline-flex items-center gap-1 font-medium text-marca-800 hover:underline\" href=\"" + ctx + "/jsp-Usuarios/login.jsp\">Volver a iniciar sesión</a></p>";
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/auth-inicio.jspf" %>
                <form method="post" action="<%= ctx %>/recuperar-password" class="space-y-5" data-validar>
                    <ui:campo nombre="correo" etiqueta="Correo de tu cuenta" tipo="email" icono="mail" valor='<%= form.get("correo") %>'
                              autocomplete="email" inputmode="email" placeholder="nombre@correo.com"
                              error='<%= "correo".equals(errorCampo) ? errorMsg : null %>'
                              autofocus='<%= errorCampo == null ? "" : null %>'/>
                    <ui:campo nombre="nueva" etiqueta="Nueva contraseña" tipo="password" icono="lock" autocomplete="new-password"
                              minlength="8" pattern="(?=.*[A-Za-z])(?=.*[0-9]).{8,}" data-msg-formato="Incluye al menos una letra y un número."
                              error='<%= "nueva".equals(errorCampo) ? errorMsg : null %>'/>
                    <ui:reglas para="nueva"/>
                    <ui:campo nombre="confirmar" etiqueta="Repite la nueva contraseña" tipo="password" icono="lock" autocomplete="new-password"
                              data-coincide-con="nueva"
                              error='<%= "confirmar".equals(errorCampo) ? errorMsg : null %>'/>
                    <button type="submit" class="btn btn-primario btn-lg w-full" data-cargando="Guardando…">
                        <ui:icono n="progress_activity" clase="btn-spinner"/><span class="btn-texto">Guardar nueva contraseña</span>
                    </button>
                </form>
<%@ include file="/WEB-INF/jspf/auth-fin.jspf" %>
</html>
