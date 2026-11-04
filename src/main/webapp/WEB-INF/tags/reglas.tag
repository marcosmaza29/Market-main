<%@ tag body-content="empty" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="para" required="true" %>
<%-- Requisitos de la contraseña; app.js los marca como cumplidos mientras se escribe --%>
<ul class="reglas -mt-2 grid gap-1 sm:grid-cols-3" data-reglas-de="<%= para %>" aria-label="Requisitos de la contraseña">
    <% String[][] reglas = {{"largo", "8 caracteres o más"}, {"letra", "Una letra"}, {"numero", "Un número"}};
       for (String[] r : reglas) { %>
    <li data-regla="<%= r[0] %>">
        <span data-estado="no"><ui:icono n="radio_button_unchecked"/></span>
        <span data-estado="si" class="hidden"><ui:icono n="check_circle"/><span class="sr-only">Cumplido:</span></span>
        <%= r[1] %>
    </li>
    <% } %>
</ul>
