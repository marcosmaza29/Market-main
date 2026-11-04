<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*" %>
<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%
String tienda=request.getParameter("tienda");
if(tienda==null || !Arrays.asList("market","juguetes","cosmeticos").contains(tienda)) tienda="market";
boolean personalizada=false;
try(Connection c=util.Conexion.getConnection(); PreparedStatement p=c.prepareStatement("SELECT personalizacion_completa FROM tiendas WHERE id=?")) {
 p.setString(1,tienda); try(ResultSet r=p.executeQuery()){ if(r.next()) personalizada=r.getBoolean(1); }
} catch(Exception e){ log("No se pudo comprobar la personalización de "+tienda,e); response.sendError(500,"No se pudo comprobar la configuración de la tienda."); return; }
if(personalizada){ response.sendRedirect(ctx+"/jsp-Interfaz/interfaz.jsp?tienda="+tienda); return; }
response.sendRedirect(ctx+"/jsp-Interfaz/personalizar_inicio.jsp?tienda="+tienda);
%>
