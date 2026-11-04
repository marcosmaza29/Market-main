<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*,java.util.*,java.util.UUID,util.Html" %>
<%
 String tiendaId=(String)session.getAttribute("adminTiendaId");
 if(!Boolean.TRUE.equals(session.getAttribute("adminLogueado")) || !util.Tienda.valida(tiendaId) || !tiendaId.equals(contextoTienda)){response.sendError(403);return;}
 String titulo="Solicitudes del cliente";String seccion="clientes";
 String csrf=(String)session.getAttribute("csrfSolicitudesAdmin");
 if(csrf==null){csrf=UUID.randomUUID().toString();session.setAttribute("csrfSolicitudesAdmin",csrf);}
 String error=null;
 if("POST".equalsIgnoreCase(request.getMethod())){
   if(!csrf.equals(request.getParameter("csrf"))){response.sendError(403);return;}
   String nuevo=Html.param(request,"estado"), respuesta=Html.param(request,"respuesta");
   String id=Html.param(request,"id");
   if(!Arrays.asList("pendiente","revision","proceso","resuelta","rechazada").contains(nuevo) || respuesta!=null&&respuesta.length()>2000 || id==null || !id.matches("[0-9]{1,18}")){
     error="Revisa el estado, el número de solicitud y la respuesta (máximo 2000 caracteres).";
   }else{
     try(Connection con=util.Conexion.getConnection();PreparedStatement ps=con.prepareStatement(
       "UPDATE solicitudes_clientes SET estado=?,respuesta_admin=?,fecha_actualizacion=CURRENT_TIMESTAMP WHERE id=? AND tienda_id=?")){
       ps.setString(1,nuevo);ps.setString(2,respuesta==null?"":respuesta);ps.setLong(3,Long.parseLong(id));ps.setString(4,tiendaId);
       if(ps.executeUpdate()!=1){error="La solicitud no existe en esta tienda.";}
       else{response.sendRedirect(ctx+"/jsp-Admin/solicitudesClientes.jsp?tienda="+tiendaId+"&actualizada=1");return;}
     }catch(Exception e){log("Error actualizando solicitud",e);error="No se pudo actualizar la solicitud. Comprueba la base de datos.";}
   }
 }
 String filtro=Html.param(request,"estadoFiltro");
 if(filtro!=null&&!Arrays.asList("pendiente","revision","proceso","resuelta","rechazada").contains(filtro))filtro=null;
 List<Map<String,String>> filas=new ArrayList<>();int pendientes=0;
 try(Connection con=util.Conexion.getConnection()){
   try(PreparedStatement ps=con.prepareStatement("SELECT COUNT(*) FROM solicitudes_clientes WHERE tienda_id=? AND estado='pendiente'")){
     ps.setString(1,tiendaId);try(ResultSet rs=ps.executeQuery()){if(rs.next())pendientes=rs.getInt(1);}
   }
   String sql="SELECT id,nombre_cliente,correo_cliente,categoria,asunto,descripcion,estado,respuesta_admin,fecha_creacion FROM solicitudes_clientes WHERE tienda_id=?"+(filtro!=null?" AND estado=?":"")+" ORDER BY CASE WHEN estado='pendiente' THEN 0 WHEN estado='revision' THEN 1 WHEN estado='proceso' THEN 2 ELSE 3 END,fecha_creacion DESC LIMIT 200";
   try(PreparedStatement ps=con.prepareStatement(sql)){
     ps.setString(1,tiendaId);if(filtro!=null)ps.setString(2,filtro);
     try(ResultSet rs=ps.executeQuery()){while(rs.next()){
       Map<String,String> f=new HashMap<>();for(String k:new String[]{"id","nombre_cliente","correo_cliente","categoria","asunto","descripcion","estado","respuesta_admin","fecha_creacion"})f.put(k,rs.getString(k));filas.add(f);
     }}
   }
 }catch(Exception e){log("Error consultando solicitudes clientes",e);error="No se pudo consultar las solicitudes. Comprueba que la migración 08 esté aplicada.";}
%>
<!DOCTYPE html><html lang="es"><head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
<div class="flex flex-wrap items-center justify-between gap-4"><div><h1 class="text-2xl font-semibold">Solicitudes del cliente</h1><p class="mt-2 text-sm text-stone-600">Ideas, mejoras y problemas reportados por los clientes de <%= Html.esc(util.Tienda.nombre(tiendaId)) %>.</p></div><span class="etiqueta"><%= pendientes %> pendientes</span></div>
<% if("1".equals(request.getParameter("actualizada"))){ %><div role="status" class="tarjeta mt-4 border-emerald-300 bg-emerald-50 p-4 text-sm">Solicitud actualizada correctamente.</div><% } %>
<% if(error!=null){ %><div role="alert" class="tarjeta mt-4 border-red-300 bg-red-50 p-4 text-sm"><%= Html.esc(error) %></div><% } %>
<form method="get" class="mt-5 flex flex-wrap items-end gap-3"><input type="hidden" name="tienda" value="<%= Html.esc(tiendaId) %>"><div><label for="estadoFiltro" class="mb-1 block text-sm font-medium">Filtrar estado</label><select name="estadoFiltro" id="estadoFiltro" class="entrada"><option value="">Todas</option><% for(String[] o:new String[][]{{"pendiente","Pendientes"},{"revision","En revisión"},{"proceso","En proceso"},{"resuelta","Resueltas"},{"rechazada","Rechazadas"}}){ %><option value="<%= o[0] %>" <%= o[0].equals(filtro)?"selected":"" %>><%= o[1] %></option><% } %></select></div><button class="btn btn-secundario" type="submit">Filtrar</button></form>
<p class="mt-4 text-sm text-stone-500">Mostrando <%= filas.size() %> solicitudes (máximo 200).</p>
<% if(filas.isEmpty()){ %><div class="tarjeta mt-4 p-6 text-sm text-stone-600">No hay solicitudes con este filtro.</div><% } %>
<div class="mt-4 space-y-4"><% for(Map<String,String> f:filas){ %>
<article class="tarjeta p-5"><div class="flex flex-wrap items-start justify-between gap-3"><div><p class="text-xs text-stone-500">#<%= Html.esc(f.get("id")) %> · <%= Html.esc(f.get("fecha_creacion")) %> · <%= Html.esc(f.get("categoria")) %></p><h2 class="mt-1 text-lg font-semibold"><%= Html.esc(f.get("asunto")) %></h2><p class="mt-1 text-sm text-stone-600"><%= Html.esc(f.get("nombre_cliente")) %> · <%= Html.esc(f.get("correo_cliente")) %></p></div><span class="etiqueta"><%= Html.esc(f.get("estado")) %></span></div>
<p class="mt-4 whitespace-pre-wrap break-words text-sm text-stone-700"><%= Html.esc(f.get("descripcion")) %></p>
<form method="post" action="<%= ctx %>/jsp-Admin/solicitudesClientes.jsp?tienda=<%= Html.esc(tiendaId) %>" class="mt-5 grid gap-3 border-t border-stone-200 pt-4"><input type="hidden" name="csrf" value="<%= Html.esc(csrf) %>"><input type="hidden" name="id" value="<%= Html.esc(f.get("id")) %>"><div><label for="estado-<%= f.get("id") %>" class="mb-1 block text-sm font-medium">Estado</label><select id="estado-<%= f.get("id") %>" class="entrada" name="estado"><% for(String[] o:new String[][]{{"pendiente","Pendiente"},{"revision","En revisión"},{"proceso","En proceso"},{"resuelta","Resuelta"},{"rechazada","Rechazada"}}){ %><option value="<%= o[0] %>" <%= o[0].equals(f.get("estado"))?"selected":"" %>><%= o[1] %></option><% } %></select></div><div><label for="respuesta-<%= f.get("id") %>" class="mb-1 block text-sm font-medium">Respuesta al cliente</label><textarea id="respuesta-<%= f.get("id") %>" name="respuesta" class="entrada" rows="3" maxlength="2000" placeholder="Explica el avance o la resolución..."><%= Html.esc(f.get("respuesta_admin")) %></textarea></div><div><button class="btn btn-primario" type="submit"><ui:icono n="check"/>Guardar cambios</button></div></form>
</article><% } %></div>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %></html>
