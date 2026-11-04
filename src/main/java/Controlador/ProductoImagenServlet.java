package Controlador;
import java.io.*;
import java.sql.*;
import java.util.UUID;
import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;
import util.*;
@WebServlet("/producto-imagen")
@MultipartConfig(maxFileSize=5242880,maxRequestSize=6291456,fileSizeThreshold=1048576)
public class ProductoImagenServlet extends HttpServlet {
 @Override protected void doPost(HttpServletRequest req,HttpServletResponse res) throws IOException,ServletException {
  req.setCharacterEncoding("UTF-8");res.setContentType("text/plain;charset=UTF-8");
  HttpSession ses=req.getSession(false);
  String tienda=ses==null?null:(String)ses.getAttribute("adminTiendaId");
  if(ses==null || !Boolean.TRUE.equals(ses.getAttribute("adminLogueado")) || !Tienda.valida(tienda)) { res.sendError(403);return; }
  try {
   String token=req.getParameter("token");
   if(token==null || !token.equals(ses.getAttribute("imagenProductoToken"))) { res.sendError(403);return; }
   ArchivoImagen foto=ArchivoImagen.leer(req.getPart("foto"));
   UUID id=UUID.randomUUID();
   try(Connection con=Conexion.getConnection();PreparedStatement ps=con.prepareStatement("INSERT INTO imagenes_producto(id,tienda_id,tipo,imagen) VALUES (?,?,?,?)")) {
    ps.setObject(1,id);ps.setString(2,tienda);ps.setString(3,foto.tipo);ps.setBytes(4,foto.datos);ps.executeUpdate();
   }
   res.getWriter().write("local:"+tienda+":"+id);
  } catch(IllegalArgumentException|IllegalStateException e) {
   res.setStatus(400);res.getWriter().write("Usa una foto JPG, PNG o GIF válida, de hasta 5 MB.");
  } catch(Exception e) { log("Error al subir foto de producto",e);res.setStatus(500);res.getWriter().write("No se pudo guardar la foto. Revisa la conexión y la actualización de la base."); }
 }
 @Override protected void doGet(HttpServletRequest req,HttpServletResponse res) throws IOException {
  String tienda=req.getParameter("tienda");UUID id;
  try {id=UUID.fromString(req.getParameter("id"));}catch(Exception e){res.sendError(404);return;}
  if(!Tienda.valida(tienda)){res.sendError(404);return;}
  try(Connection con=Conexion.getConnection();PreparedStatement ps=con.prepareStatement("SELECT tipo,imagen FROM imagenes_producto WHERE id=? AND tienda_id=?")) {
   ps.setObject(1,id);ps.setString(2,tienda);
   try(ResultSet rs=ps.executeQuery()) {
    if(!rs.next()){res.sendError(404);return;}
    byte[] bytes=rs.getBytes(2);res.setContentType(rs.getString(1));res.setContentLength(bytes.length);
    res.setHeader("X-Content-Type-Options","nosniff");res.setHeader("Cache-Control","public, max-age=300");res.getOutputStream().write(bytes);
   }
  }catch(SQLException e){log("Error al leer foto de producto",e);res.sendError(500);}
 }
}
