<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,java.net.URI,java.nio.charset.StandardCharsets,java.security.MessageDigest" %>
<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%
if(!"POST".equalsIgnoreCase(request.getMethod())){response.sendError(405);return;}
request.setCharacterEncoding("UTF-8");
String tienda=request.getParameter("tienda"), token=request.getParameter("token"), esperado=(String)session.getAttribute("personalizacionInicialToken");
if(tienda==null || !Arrays.asList("market","juguetes","cosmeticos").contains(tienda) || esperado==null || token==null || !MessageDigest.isEqual(esperado.getBytes(StandardCharsets.UTF_8),token.getBytes(StandardCharsets.UTF_8))){response.sendError(403,"Solicitud no válida o caducada.");return;}
String nombre=request.getParameter("nombre"), fuente=request.getParameter("fuente"), p=request.getParameter("primario"), s=request.getParameter("secundario"), f=request.getParameter("fondo"), logo=request.getParameter("logo"), banner=request.getParameter("banner");
if(nombre==null)nombre=""; nombre=nombre.trim(); if(logo==null)logo="";if(banner==null)banner="";logo=logo.trim();banner=banner.trim();
List<String> fuentes=Arrays.asList("Inter","'Segoe UI', sans-serif","Georgia, serif","'Comic Sans MS', cursive");
boolean urls=logo.length()<=1000&&banner.length()<=1000;
try{if(!logo.isEmpty()){URI u=new URI(logo);urls=urls&&"https".equalsIgnoreCase(u.getScheme())&&u.getHost()!=null;}if(!banner.isEmpty()){URI u=new URI(banner);urls=urls&&"https".equalsIgnoreCase(u.getScheme())&&u.getHost()!=null;}}catch(Exception e){urls=false;}
if(nombre.isEmpty()||nombre.length()>100||!fuentes.contains(fuente)||p==null||!p.matches("#[0-9a-fA-F]{6}")||s==null||!s.matches("#[0-9a-fA-F]{6}")||f==null||!f.matches("#[0-9a-fA-F]{6}")||!urls){response.sendError(400,"Revisa los datos de personalización.");return;}
try(Connection c=util.Conexion.getConnection();PreparedStatement q=c.prepareStatement("UPDATE tiendas SET nombre=?,tipo_fuente=?,color_primario=?,color_secundario=?,color_fondo=?,logo_url=?,banner_url=?,personalizacion_completa=TRUE WHERE id=? AND personalizacion_completa=FALSE")){
q.setString(1,nombre);q.setString(2,fuente);q.setString(3,p);q.setString(4,s);q.setString(5,f);q.setString(6,logo.isEmpty()?null:logo);q.setString(7,banner.isEmpty()?null:banner);q.setString(8,tienda);
if(q.executeUpdate()!=1){response.sendError(409,"La tienda ya fue configurada. Ingresa y modifica el diseño desde el panel administrador.");return;}
session.removeAttribute("personalizacionInicialToken");response.sendRedirect(ctx+"/jsp-Interfaz/interfaz.jsp?tienda="+tienda);
}catch(Exception e){log("Error al guardar personalización inicial de "+tienda,e);response.sendError(500,"No se pudo guardar la personalización. Revisa la conexión a la base de datos.");}
%>
