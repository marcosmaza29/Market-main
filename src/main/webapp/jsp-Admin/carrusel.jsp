<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="java.sql.*, java.util.*, util.Html" %>
<%
    String tiendaId = (String) session.getAttribute("adminTiendaId");
    String titulo = "Carrusel de publicidad";
    String seccion = "carrusel";
    String tokenPublicidad = (String) session.getAttribute("publicidadToken");
    if (tokenPublicidad == null) {
        tokenPublicidad = UUID.randomUUID().toString();
        session.setAttribute("publicidadToken", tokenPublicidad);
    }
    List<String[]> fotos = new ArrayList<>();
    boolean falloCarrusel = false;
    try (Connection con = util.Conexion.getConnection();
         PreparedStatement ps = con.prepareStatement("SELECT id,texto_alternativo,orden FROM carrusel_publicidad WHERE tienda_id=? ORDER BY orden,id")) {
        ps.setString(1, tiendaId);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) fotos.add(new String[]{rs.getString(1),rs.getString(2),rs.getString(3)});
        }
    } catch (Exception e) { log("Error al cargar publicidad", e); falloCarrusel = true; }
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
<h1 class="text-2xl font-semibold">Carrusel de publicidad · <%= Html.esc(util.Tienda.nombre(tiendaId)) %></h1>
<p class="mt-2 text-stone-600">Sube las promociones de esta tienda. Las fotos aparecen en el inicio, de menor a mayor orden. Para reemplazar una foto, elimina la anterior y sube la nueva.</p>
<% if (falloCarrusel) { %><p role="alert">No se pudo cargar el carrusel. Ejecuta la migración 05_carrusel.sql y vuelve a intentar.</p><% } %>
<form method="post" enctype="multipart/form-data" action="<%= ctx %>/publicidad" class="tarjeta mt-6 space-y-4 p-4">
<input type="hidden" name="token" value="<%= tokenPublicidad %>">
<div><label class="etiqueta" for="foto">Foto (JPG, PNG o GIF, máximo 5 MB)</label><input class="entrada" id="foto" name="foto" type="file" accept="image/jpeg,image/png,image/gif" required></div>
<div><label class="etiqueta" for="descripcion">Descripción de la promoción</label><input class="entrada" id="descripcion" name="descripcion" maxlength="160" required></div>
<div><label class="etiqueta" for="orden">Orden</label><input class="entrada" id="orden" name="orden" type="number" value="0" required></div>
<button class="btn btn-primario" type="submit">Subir foto al carrusel</button>
</form>
<div class="mt-6 grid gap-4 sm:grid-cols-2">
<% for (String[] foto : fotos) { %>
<article class="tarjeta space-y-3 p-4">
<img src="<%= ctx %>/publicidad-imagen?id=<%= foto[0] %>&amp;tienda=<%= tiendaId %>" alt="<%= Html.esc(foto[1]) %>" style="width:100%;height:180px;object-fit:contain">
<p><%= Html.esc(foto[1]) %> · Orden <%= foto[2] %></p>
<form method="post" action="<%= ctx %>/publicidad">
<input type="hidden" name="token" value="<%= tokenPublicidad %>">
<input type="hidden" name="accion" value="eliminar"><input type="hidden" name="id" value="<%= foto[0] %>">
<button class="btn btn-secundario" type="submit">Eliminar foto</button>
</form>
</article>
<% } %>
</div>
<% if (fotos.isEmpty() && !falloCarrusel) { %><p class="mt-6">Todavía no hay fotos cargadas para esta tienda.</p><% } %>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
