<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.util.Map" %>
<%
    Map<String, String> form = util.Flash.formulario(session);
    String errorCampo = form.get("__error");
    String errorMsg = form.get("__mensaje");
    String titulo = "Crea tu cuenta";
    String subtitulo = "Te toma un minuto y podrás comprar y ver tus boletas.";
    String pieAuth = "<p>¿Ya tienes cuenta? <a class=\"font-medium text-marca-800 hover:underline\" href=\"" + ctx + "/jsp-Usuarios/login.jsp\">Inicia sesión</a></p>";
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/auth-inicio.jspf" %>
                <form method="post" action="<%= ctx %>/registro-nuevo" class="space-y-5" data-validar>
                    <div class="grid gap-5 sm:grid-cols-2">
                        <ui:campo nombre="nombre" etiqueta="Nombres" valor='<%= form.get("nombre") %>' autocomplete="given-name" maxlength="100"
                                  error='<%= "nombre".equals(errorCampo) ? errorMsg : null %>'
                                  autofocus='<%= errorCampo == null ? "" : null %>'/>
                        <ui:campo nombre="apellidos" etiqueta="Apellidos" valor='<%= form.get("apellidos") %>' autocomplete="family-name" maxlength="100"
                                  error='<%= "apellidos".equals(errorCampo) ? errorMsg : null %>'/>
                    </div>
                    <ui:campo nombre="correo" etiqueta="Correo electrónico" tipo="email" icono="mail" valor='<%= form.get("correo") %>'
                              autocomplete="email" inputmode="email" placeholder="nombre@correo.com" maxlength="100"
                              ayuda="Lo usarás para iniciar sesión."
                              error='<%= "correo".equals(errorCampo) ? errorMsg : null %>'/>
                    <ui:campo nombre="contrasena" etiqueta="Contraseña" tipo="password" icono="lock" autocomplete="new-password"
                              minlength="8" pattern="(?=.*[A-Za-z])(?=.*[0-9]).{8,}" data-msg-formato="Incluye al menos una letra y un número."
                              error='<%= "contrasena".equals(errorCampo) ? errorMsg : null %>'/>
                    <ui:reglas para="contrasena"/>
                    <ui:campo nombre="confirmar" etiqueta="Repite la contraseña" tipo="password" icono="lock" autocomplete="new-password"
                              data-coincide-con="contrasena"
                              error='<%= "confirmar".equals(errorCampo) ? errorMsg : null %>'/>
                    <button type="submit" class="btn btn-primario btn-lg w-full" data-cargando="Creando tu cuenta…">
                        <ui:icono n="progress_activity" clase="btn-spinner"/><span class="btn-texto">Crear cuenta</span>
                    </button>
                </form>
<%@ include file="/WEB-INF/jspf/auth-fin.jspf" %>
</html>
