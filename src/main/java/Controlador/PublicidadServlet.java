package Controlador;

import java.io.*;
import java.sql.*;
import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;
import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;
import util.*;

@WebServlet("/publicidad")
@MultipartConfig(maxFileSize=5242880, maxRequestSize=6291456, fileSizeThreshold=1048576)
public class PublicidadServlet extends HttpServlet {
    @Override protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException, ServletException {
        req.setCharacterEncoding("UTF-8");
        HttpSession ses = req.getSession(false);
        String tienda = ses == null ? null : (String) ses.getAttribute("adminTiendaId");
        if (ses == null || !Boolean.TRUE.equals(ses.getAttribute("adminLogueado")) || !Tienda.valida(tienda)) {
            res.sendError(403); return;
        }
        try {
            String token = req.getParameter("token");
            if (token == null || !token.equals(ses.getAttribute("publicidadToken"))) { res.sendError(403); return; }
            try (Connection con = Conexion.getConnection()) {
                if ("eliminar".equals(req.getParameter("accion"))) {
                    try (PreparedStatement ps = con.prepareStatement("DELETE FROM carrusel_publicidad WHERE id=? AND tienda_id=?")) {
                        ps.setLong(1, Long.parseLong(req.getParameter("id"))); ps.setString(2, tienda);
                        if (ps.executeUpdate() != 1) throw new IllegalArgumentException("La imagen no pertenece a esta tienda.");
                    }
                } else {
                    String alt = req.getParameter("descripcion");
                    if (alt == null || alt.trim().isEmpty() || alt.length() > 160) throw new IllegalArgumentException("Escribe una descripción de hasta 160 caracteres.");
                    int orden = Integer.parseInt(req.getParameter("orden"));
                    Part foto = req.getPart("foto");
                    if (foto == null || foto.getSize() == 0 || foto.getSize() > 5242880) throw new IllegalArgumentException("Selecciona una imagen de hasta 5 MB.");
                    ArchivoImagen archivo = ArchivoImagen.leer(foto);
                    byte[] datos = archivo.datos; String tipo = archivo.tipo;
                    try (PreparedStatement ps = con.prepareStatement("INSERT INTO carrusel_publicidad (tienda_id,texto_alternativo,orden,tipo,imagen) VALUES (?,?,?,?,?)")) {
                        ps.setString(1, tienda); ps.setString(2, alt.trim()); ps.setInt(3, orden); ps.setString(4, tipo); ps.setBytes(5, datos); ps.executeUpdate();
                    }
                }
            }
            Flash.exito(ses, "Carrusel actualizado.");
        } catch (IllegalArgumentException | IllegalStateException e) {
            Flash.error(ses, "Revisa la imagen (JPG, PNG o GIF, máximo 5 MB), la descripción y el orden.");
        } catch (Exception e) {
            log("No se pudo guardar la publicidad de " + tienda, e);
            Flash.error(ses, "No se pudo guardar la publicidad. Comprueba la migración 05_carrusel.sql.");
        }
        res.sendRedirect(req.getContextPath() + "/jsp-Admin/carrusel.jsp?tienda=" + tienda);
    }
}
