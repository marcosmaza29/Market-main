<%@ tag body-content="empty" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ attribute name="n" required="true" %>
<%@ attribute name="clase" %>
<%@ attribute name="etiqueta" %>
<%= util.Icono.svg(application, n, clase, etiqueta) %>
