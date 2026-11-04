package Controlador;
import java.io.*;
import java.sql.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import util.*;
@WebServlet("/publicidad-imagen")
public class PublicidadImagenServlet extends HttpServlet {
    @Override protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
        String tienda = req.getParameter("tienda");
        long id;
        try { id = Long.parseLong(req.getParameter("id")); } catch (Exception e) { res.sendError(404); return; }
        if (!Tienda.valida(tienda)) { res.sendError(404); return; }
        try (Connection con = Conexion.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT tipo,imagen FROM carrusel_publicidad WHERE id=? AND tienda_id=?")) {
            ps.setLong(1, id); ps.setString(2, tienda);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) { res.sendError(404); return; }
                byte[] bytes = rs.getBytes(2);
                res.setContentType(rs.getString(1)); res.setContentLength(bytes.length);
                res.setHeader("X-Content-Type-Options", "nosniff");
                res.setHeader("Cache-Control", "public, max-age=300");
                res.getOutputStream().write(bytes);
            }
        } catch (SQLException e) { log("No se pudo leer la publicidad", e); res.sendError(500); }
    }
}
