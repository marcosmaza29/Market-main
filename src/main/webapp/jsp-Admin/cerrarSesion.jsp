<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String tiendaSalida = util.Tienda.actual(request);
    session.invalidate();
    util.Flash.info(request.getSession(true), "Cerraste la sesión del panel.");
    response.sendRedirect(request.getContextPath() + "/jsp-Admin/loginAdmin.jsp?tienda=" + tiendaSalida);
%>
