package Controlador;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.WebListener;
@WebListener
public class ActualizarEsquema implements ServletContextListener {
 public void contextInitialized(ServletContextEvent event) {
  util.Imagenes.contexto(event.getServletContext().getContextPath());
  try (Connection con = util.Conexion.getConnection()) {
   con.setAutoCommit(false);
   try {
    try (Statement st = con.createStatement()) {
     st.execute("SELECT pg_advisory_xact_lock(731932852)");
     st.execute("CREATE TABLE IF NOT EXISTS market_migraciones (nombre VARCHAR(100) PRIMARY KEY, aplicado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
    }
    for (String nombre : new String[]{"04_multi_tienda.sql", "05_carrusel.sql", "06_imagenes_producto.sql", "07_gestion_administrativa.sql", "08_solicitudes_clientes.sql", "09_incidentes.sql"}) {
     boolean aplicada;
     try (PreparedStatement ps = con.prepareStatement("SELECT 1 FROM market_migraciones WHERE nombre=?")) {
      ps.setString(1,nombre); try (ResultSet rs=ps.executeQuery()) { aplicada=rs.next(); }
     }
     if (aplicada) continue;
     try (InputStream in=getClass().getResourceAsStream("/db/"+nombre)) {
      if (in==null) throw new IOException("Falta migración " + nombre);
      ByteArrayOutputStream bytes=new ByteArrayOutputStream(); byte[] b=new byte[8192]; int n;
      while((n=in.read(b))!=-1) bytes.write(b,0,n);
      try(Statement st=con.createStatement()) { st.execute(new String(bytes.toByteArray(),StandardCharsets.UTF_8)); }
     }
     try (PreparedStatement ps=con.prepareStatement("INSERT INTO market_migraciones(nombre) VALUES (?)")) { ps.setString(1,nombre);ps.executeUpdate(); }
    }
    con.commit();
   } catch(Exception e) { con.rollback(); throw e; }
  } catch(Exception e) {
   event.getServletContext().log("No se pudo actualizar el esquema. Revisar permisos de la base y ejecutar migraciones 04–09.",e);
  }
 }
 public void contextDestroyed(ServletContextEvent event) {}
}
