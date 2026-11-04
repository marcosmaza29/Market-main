<%@ tag body-content="empty" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" dynamic-attributes="extra" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="nombre" required="true" %>
<%@ attribute name="etiqueta" required="true" %>
<%@ attribute name="tipo" %>
<%@ attribute name="valor" %>
<%@ attribute name="icono" %>
<%@ attribute name="ayuda" %>
<%@ attribute name="error" %>
<%@ attribute name="opcional" type="java.lang.Boolean" %>
<%@ attribute name="clase" %>
<%@ attribute name="id" %>
<%-- Campo de formulario consistente: etiqueta, icono, ayuda, error y accesibilidad --%>
<%
    String tipoReal = tipo == null ? "text" : tipo;
    String idReal = id == null ? nombre : id;
    boolean esOpcional = Boolean.TRUE.equals(opcional);
    boolean conError = error != null && !error.isEmpty();
    StringBuilder describe = new StringBuilder();
    if (ayuda != null) describe.append(idReal).append("-ayuda ");
    if (conError) describe.append(idReal).append("-error");
    StringBuilder atributos = new StringBuilder();
    java.util.Map<String, Object> extraMap = (java.util.Map<String, Object>) jspContext.getAttribute("extra");
    if (extraMap != null) {
        for (java.util.Map.Entry<String, Object> e : extraMap.entrySet()) {
            if (e.getValue() == null) continue; // null = atributo ausente; "" = atributo booleano
            atributos.append(' ').append(e.getKey());
            if (e.getValue() != null && !"".equals(e.getValue())) {
                atributos.append("=\"").append(util.Html.esc(e.getValue())).append('"');
            }
        }
    }
    if (!esOpcional) atributos.append(" required");
    boolean conIcono = icono != null || "password".equals(tipoReal);
%>
<div class="campo<%= clase != null ? " " + clase : "" %>">
    <label for="<%= idReal %>" class="etiqueta"><%= util.Html.esc(etiqueta) %><% if (esOpcional) { %> <span class="opcional">(opcional)</span><% } %></label>
    <div class="<%= conIcono ? "entrada-icono" : "" %>">
        <% if (icono != null) { %><ui:icono n="<%= icono %>"/><% } %>
        <input id="<%= idReal %>" name="<%= nombre %>" type="<%= tipoReal %>" class="entrada"
               <% if (valor != null) { %>value="<%= util.Html.esc(valor) %>"<% } %>
               <% if (describe.length() > 0) { %>aria-describedby="<%= describe.toString().trim() %>"<% } %>
               <% if (conError) { %>aria-invalid="true" autofocus<% } %><%= atributos %>>
        <% if ("password".equals(tipoReal)) { %>
        <button type="button" class="entrada-accion btn btn-fantasma btn-sm btn-solo-icono text-stone-500" data-ver-contrasena="<%= idReal %>" aria-pressed="false" aria-label="Mostrar contraseña" hidden>
            <span data-icono="ver"><ui:icono n="visibility"/></span>
            <span data-icono="ocultar" class="hidden"><ui:icono n="visibility_off"/></span>
        </button>
        <% } %>
    </div>
    <% if (ayuda != null) { %><p id="<%= idReal %>-ayuda" class="ayuda"><%= ayuda %></p><% } %>
    <% if (conError) { %><p id="<%= idReal %>-error" class="error-campo"><ui:icono n="error"/><span class="error-campo-texto"><%= util.Html.esc(error) %></span></p><% } %>
</div>
