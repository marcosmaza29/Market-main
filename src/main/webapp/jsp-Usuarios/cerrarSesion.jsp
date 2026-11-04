<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%-- Ruta antigua: se delega en /cerrar-sesion para que el comportamiento sea el mismo --%>
<% response.sendRedirect(request.getContextPath() + "/cerrar-sesion"); %>
