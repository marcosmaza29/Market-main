<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*,java.util.*,java.util.UUID,util.Html" %>
<%
 String titulo="Solicitudes y mejoras";
 String correo=(String)session.getAttribute("correoCliente");
 String nombre=(String)session.getAttribute("usuarioNombre");
 String tienda=contextoTienda;
 if (correo==null || correo.trim().isEmpty()) {
   String volver=java.net.URLEncoder.encode("/jsp-Interfaz/solicitudes.jsp?tienda="+tienda,"UTF-8");
   response.sendRedirect(ctx+"/jsp-Usuarios/login.jsp?volver="+volver); return;
 }
 String csrf=(String)session.getAttribute("csrfSolicitudesCliente");
 if(csrf==null){csrf=UUID.randomUUID().toString();session.setAttribute("csrfSolicitudesCliente",csrf);}
 String aviso=null, error=null;
 if("POST".equalsIgnoreCase(request.getMethod())) {
   String tipo=Html.param(request,"categoria"), asunto=Html.param(request,"asunto"), descripcion=Html.param(request,"descripcion");
   if(!csrf.equals(request.getParameter("csrf"))) {response.sendError(403);return;}
   if(!Arrays.asList("mejora","sugerencia","problema","otro").contains(tipo)
      || asunto==null || asunto.length()<5 || asunto.length()>150
      || descripcion==null || descripcion.length()<10 || descripcion.length()>2000) {
     error="Completa los campos: asunto (5 a 150 caracteres), descripción (10 a 2000 caracteres) y categoría válida.";
   } else {
     try(Connection con=util.Conexion.getConnection(); PreparedStatement ps=con.prepareStatement(
         "INSERT INTO solicitudes_clientes(tienda_id,correo_cliente,nombre_cliente,categoria,asunto,descripcion) VALUES(?,?,?,?,?,?)")) {
       ps.setString(1,tienda);ps.setString(2,correo);ps.setString(3,nombre==null?"Cliente":nombre);
       ps.setString(4,tipo);ps.setString(5,asunto);ps.setString(6,descripcion);ps.executeUpdate();
       response.sendRedirect(ctx+"/jsp-Interfaz/solicitudes.jsp?tienda="+tienda+"&enviada=1");return;
     } catch(Exception e){log("Error guardando solicitud de cliente",e);error="No se pudo registrar la solicitud. Comprueba que la migración 08 esté aplicada.";}
   }
 }
 if("1".equals(request.getParameter("enviada"))) aviso="Tu solicitud fue enviada a la administración de esta tienda.";
 List<Map<String,String>> filas=new ArrayList<>();
 try(Connection con=util.Conexion.getConnection();PreparedStatement ps=con.prepareStatement(
     "SELECT id,categoria,asunto,descripcion,estado,respuesta_admin,fecha_creacion FROM solicitudes_clientes WHERE tienda_id=? AND correo_cliente=? ORDER BY fecha_creacion DESC LIMIT 100")) {
   ps.setString(1,tienda);ps.setString(2,correo);
   try(ResultSet rs=ps.executeQuery()){while(rs.next()){
     Map<String,String> f=new HashMap<>();
     for(String k:new String[]{"id","categoria","asunto","descripcion","estado","respuesta_admin","fecha_creacion"}) f.put(k,rs.getString(k));filas.add(f);
   }}
 }catch(Exception e){log("Error leyendo solicitudes del cliente",e);if(error==null)error="No se pudo consultar el historial. Revisa la base de datos.";}
%>
<!DOCTYPE html><html lang="es"><head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<body class="min-h-dvh"><%@ include file="/WEB-INF/jspf/tienda-header.jspf" %>
<main id="contenido" class="contenedor max-w-4xl pt-8">
 <div class="flex flex-wrap items-center justify-between gap-3"><div><h1 class="text-2xl font-semibold text-stone-900">Solicitudes y mejoras</h1><p class="mt-2 text-sm text-stone-600">Envía una idea, solicita una mejora o reporta un problema a <%= Html.esc(util.Tienda.nombre(tienda)) %>.</p></div><span class="etiqueta"><%= Html.esc(util.Tienda.nombre(tienda)) %></span></div>
 <% if(aviso!=null){ %><div role="status" class="tarjeta mt-5 border-emerald-300 bg-emerald-50 p-4 text-sm text-emerald-900"><%= Html.esc(aviso) %></div><% } %>
 <% if(error!=null){ %><div role="alert" class="tarjeta mt-5 border-red-300 bg-red-50 p-4 text-sm text-red-900"><%= Html.esc(error) %></div><% } %>
 <section class="tarjeta mt-6 p-5" aria-labelledby="nueva"><h2 id="nueva" class="text-lg font-semibold">Nueva solicitud</h2><p class="mt-1 text-sm text-stone-600">La solicitud llegará solo al administrador de esta tienda.</p>
 <form method="post" action="<%= ctx %>/jsp-Interfaz/solicitudes.jsp?tienda=<%= Html.esc(tienda) %>" class="mt-5 grid gap-4">
  <input type="hidden" name="csrf" value="<%= Html.esc(csrf) %>">
  <div><label class="mb-1 block text-sm font-medium" for="categoria">Tipo de solicitud</label><select id="categoria" name="categoria" class="entrada" required><option value="mejora">Solicitud de mejora</option><option value="sugerencia">Sugerencia</option><option value="problema">Reportar un problema</option><option value="otro">Otro</option></select></div>
  <div><label class="mb-1 block text-sm font-medium" for="asunto">Asunto</label><input id="asunto" name="asunto" class="entrada" maxlength="150" minlength="5" required placeholder="Ej. Mejorar el buscador de productos" value="<%= Html.esc(request.getParameter("asunto")==null?"":request.getParameter("asunto")) %>"></div>
  <div><label class="mb-1 block text-sm font-medium" for="descripcion">Descripción</label><textarea id="descripcion" name="descripcion" rows="5" class="entrada" minlength="10" maxlength="2000" required placeholder="Describe tu idea o el problema con el mayor detalle posible"><%= Html.esc(request.getParameter("descripcion")==null?"":request.getParameter("descripcion")) %></textarea><p class="mt-1 text-xs text-stone-500">Entre 10 y 2000 caracteres.</p></div>
  <div><button class="btn btn-primario" type="submit"><ui:icono n="mail"/>Enviar solicitud</button></div>
 </form></section>
 <section class="mt-8" aria-labelledby="historial"><h2 id="historial" class="text-lg font-semibold">Mis solicitudes (<%= filas.size() %>)</h2><p class="mt-1 text-sm text-stone-600">Aquí podrás ver el estado y las respuestas de la administración.</p>
 <% if(filas.isEmpty()){ %><div class="tarjeta mt-4 p-6 text-sm text-stone-600">Todavía no has enviado solicitudes a esta tienda.</div><% } %>
 <div class="mt-4 space-y-3"><% for(Map<String,String> f:filas){String estado=f.get("estado");String estadoTexto="revision".equals(estado)?"En revisión":"proceso".equals(estado)?"En proceso":"resuelta".equals(estado)?"Resuelta":"rechazada".equals(estado)?"Rechazada":"Pendiente"; %>
  <article class="tarjeta p-5"><div class="flex flex-wrap items-start justify-between gap-3"><div><h3 class="font-semibold text-stone-900"><%= Html.esc(f.get("asunto")) %></h3><p class="mt-1 text-xs text-stone-500"><%= Html.esc(f.get("fecha_creacion")) %> · <%= Html.esc(f.get("categoria")) %> · #<%= Html.esc(f.get("id")) %></p></div><span class="etiqueta"><%= estadoTexto %></span></div><p class="mt-3 whitespace-pre-wrap break-words text-sm text-stone-700"><%= Html.esc(f.get("descripcion")) %></p><% if(f.get("respuesta_admin")!=null&&!f.get("respuesta_admin").isEmpty()){ %><div class="mt-4 rounded-lg bg-stone-100 p-3"><p class="text-sm font-semibold">Respuesta del administrador</p><p class="mt-1 whitespace-pre-wrap break-words text-sm"><%= Html.esc(f.get("respuesta_admin")) %></p></div><% } %></article>
 <% } %></div></section>
</main><%@ include file="/WEB-INF/jspf/tienda-footer.jspf" %><%@ include file="/WEB-INF/jspf/fin.jspf" %></body></html>
