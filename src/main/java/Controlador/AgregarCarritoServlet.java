package Controlador;

import java.io.*;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import modelo.CarritoItem;

@WebServlet("/agregar-carrito")
public class AgregarCarritoServlet extends HttpServlet {

    private static final int MAXIMO_POR_PRODUCTO = 99;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int id;
        int cantidad;
        try {
            id = Integer.parseInt(request.getParameter("id"));
            String c = request.getParameter("cantidad");
            cantidad = (c == null || c.isEmpty()) ? 1 : Integer.parseInt(c);
        } catch (NumberFormatException e) {
            responder(request, response, false, "Datos inválidos.", 0);
            return;
        }
        cantidad = Math.max(1, Math.min(cantidad, MAXIMO_POR_PRODUCTO));

        HttpSession session = request.getSession();
        List<CarritoItem> carrito = (List<CarritoItem>) session.getAttribute("carrito");
        if (carrito == null) {
            carrito = new ArrayList<>();
        }

        CarritoItem existente = null;
        for (CarritoItem item : carrito) {
            if (item.getId() == id) {
                existente = item;
                break;
            }
        }
        int yaEnCarrito = existente == null ? 0 : existente.getCantidad();

        try (Connection conn = util.Conexion.getConnection();
                PreparedStatement ps = conn.prepareStatement(
                        "SELECT nombre, precio, unidad, stock FROM productos WHERE id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    responder(request, response, false, "El producto ya no existe.", yaEnCarrito);
                    return;
                }

                int stock = rs.getInt("stock");
                int disponible = stock - yaEnCarrito;
                if (disponible <= 0) {
                    String msg = stock <= 0 ? "Producto agotado."
                            : "Ya tienes en tu carrito todo el stock disponible (" + stock + ").";
                    responder(request, response, false, msg, yaEnCarrito);
                    return;
                }
                if (cantidad > disponible) {
                    responder(request, response, false,
                            "Solo puedes agregar " + disponible + " más.", yaEnCarrito);
                    return;
                }

                if (existente != null) {
                    existente.setCantidad(yaEnCarrito + cantidad);
                } else {
                    carrito.add(new CarritoItem(
                            id,
                            rs.getString("nombre"),
                            rs.getDouble("precio"),
                            cantidad,
                            rs.getString("unidad")
                    ));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            responder(request, response, false, "No se pudo agregar. Inténtalo de nuevo.", yaEnCarrito);
            return;
        }

        session.setAttribute("carrito", carrito);
        responder(request, response, true, "Agregado", yaEnCarrito + cantidad);
    }

    // Responde JSON a las peticiones AJAX; si no, vuelve a la página de origen con un aviso
    private void responder(HttpServletRequest request, HttpServletResponse response,
            boolean ok, String mensaje, int enCarrito) throws IOException {
        String accept = request.getHeader("Accept");
        if (accept != null && accept.contains("application/json")) {
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write("{\"ok\":" + ok
                    + ",\"enCarrito\":" + enCarrito
                    + ",\"totalItems\":" + totalItems(request.getSession())
                    + ",\"mensaje\":\"" + mensaje.replace("\\", "\\\\").replace("\"", "\\\"") + "\"}");
        } else {
            if (ok) {
                util.Flash.exito(request.getSession(), "Producto agregado. Tienes " + enCarrito + " en tu carrito.");
            } else {
                util.Flash.error(request.getSession(), mensaje);
            }
            response.sendRedirect(volver(request));
        }
    }

    private static int totalItems(HttpSession session) {
        List<CarritoItem> carrito = (List<CarritoItem>) session.getAttribute("carrito");
        int total = 0;
        if (carrito != null) {
            for (CarritoItem item : carrito) {
                total += item.getCantidad();
            }
        }
        return total;
    }

    /** Regresa a la página de la tienda desde la que se agregó (solo rutas propias). */
    private static String volver(HttpServletRequest request) {
        String ctx = request.getContextPath();
        String referer = request.getHeader("Referer");
        if (referer != null) {
            try {
                java.net.URI uri = new java.net.URI(referer);
                String host = request.getServerName();
                if (uri.getHost() == null || uri.getHost().equalsIgnoreCase(host)) {
                    String ruta = uri.getRawPath() + (uri.getRawQuery() != null ? "?" + uri.getRawQuery() : "");
                    if (ruta.startsWith(ctx + "/jsp-Interfaz/")) {
                        return ruta;
                    }
                }
            } catch (java.net.URISyntaxException ignorada) {
                // se usa la página de inicio
            }
        }
        return ctx + "/jsp-Interfaz/interfaz.jsp";
    }
}
