package Controlador;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import modelo.CarritoItem;
import util.Flash;
import util.Conexion;

/**
 * Gestiona el carrito respetando la tienda seleccionada.
 */
@WebServlet("/carrito")
public class CarritoServlet extends HttpServlet {

    private static final String DESHACER = "carrito.deshacer";

    private boolean tiendaValida(String tienda) {
        return "market".equals(tienda)
                || "juguetes".equals(tienda)
                || "cosmeticos".equals(tienda);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession();
        String ctx = request.getContextPath();

        String tiendaId = request.getParameter("tienda");

        if (!tiendaValida(tiendaId)) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "La tienda seleccionada no es válida."
            );
            return;
        }

        List<CarritoItem> carrito =
                (List<CarritoItem>) session.getAttribute("carrito");

        if (carrito == null) {
            carrito = new ArrayList<>();
        }

        String tiendaSesion =
                (String) session.getAttribute("carritoTienda");

        // Evita mezclar carritos de distintas tiendas.
        if (!carrito.isEmpty()) {
            if (tiendaSesion != null && !tiendaSesion.equals(tiendaId)) {
                response.sendError(
                        HttpServletResponse.SC_CONFLICT,
                        "Tu carrito pertenece a otra tienda."
                );
                return;
            }

            // Verifica los productos existentes antes de modificar el carrito.
            for (CarritoItem item : carrito) {
                if (!productoPerteneceATienda(item.getId(), tiendaId)) {
                    response.sendError(
                            HttpServletResponse.SC_FORBIDDEN,
                            "El carrito contiene productos de otra tienda."
                    );
                    return;
                }
            }
        }

        session.setAttribute("carritoTienda", tiendaId);

        String accion = request.getParameter("accion");

        if (accion == null) {
            accion = "";
        }

        String urlCarrito = ctx
                + "/jsp-Interfaz/carrito.jsp?tienda=" + tiendaId;

        String urlDeshacer = ctx
                + "/carrito?accion=deshacer&tienda=" + tiendaId;

        switch (accion) {

            case "actualizar": {
                CarritoItem item = buscar(
                        carrito,
                        entero(request.getParameter("id"), -1)
                );

                String nueva = request.getParameter("nueva");

                int cantidad = entero(
                        nueva != null
                                ? nueva
                                : request.getParameter("cantidad"),
                        -1
                );

                if (item == null) {
                    Flash.error(
                            session,
                            "Ese producto ya no está en tu carrito."
                    );
                    break;
                }

                if (cantidad == -1) {
                    Flash.error(
                            session,
                            "La cantidad indicada no es válida."
                    );
                    break;
                }

                if (cantidad <= 0) {
                    quitar(session, carrito, item);

                    Flash.exito(
                            session,
                            "Quitaste «" + item.getNombre()
                                    + "» del carrito.",
                            "Deshacer",
                            urlDeshacer
                    );
                    break;
                }

                int stock = stock(item.getId(), tiendaId);

                if (stock == -1) {
                    Flash.error(
                            session,
                            "No se pudo verificar el stock. Inténtalo de nuevo."
                    );
                    break;
                }

                if (stock == 0) {
                    quitar(session, carrito, item);

                    Flash.error(
                            session,
                            "El producto ya no tiene stock y fue retirado "
                                    + "del carrito."
                    );
                    break;
                }

                if (cantidad > stock) {
                    item.setCantidad(stock);

                    Flash.error(
                            session,
                            "Solo hay " + stock + " unidades de «"
                                    + item.getNombre()
                                    + "». Ajustamos la cantidad."
                    );
                } else {
                    item.setCantidad(Math.min(cantidad, 99));
                }

                break;
            }

            case "eliminar": {
                CarritoItem item = buscar(
                        carrito,
                        entero(request.getParameter("id"), -1)
                );

                if (item != null) {
                    quitar(session, carrito, item);

                    Flash.exito(
                            session,
                            "Quitaste «" + item.getNombre()
                                    + "» del carrito.",
                            "Deshacer",
                            urlDeshacer
                    );
                }

                break;
            }

            case "vaciar": {
                if (!carrito.isEmpty()) {
                    session.setAttribute(
                            DESHACER,
                            new ArrayList<>(carrito)
                    );

                    carrito.clear();

                    Flash.exito(
                            session,
                            "Vaciaste tu carrito.",
                            "Deshacer",
                            urlDeshacer
                    );
                }

                break;
            }

            case "deshacer": {
                List<CarritoItem> anterior =
                        (List<CarritoItem>) session.getAttribute(DESHACER);

                session.removeAttribute(DESHACER);

                if (anterior != null) {
                    boolean valido = true;

                    for (CarritoItem item : anterior) {
                        if (!productoPerteneceATienda(
                                item.getId(), tiendaId)) {
                            valido = false;
                            break;
                        }
                    }

                    if (valido) {
                        carrito = anterior;

                        Flash.info(
                                session,
                                "Recuperamos tu carrito."
                        );
                    } else {
                        Flash.error(
                                session,
                                "No se pudo recuperar el carrito porque "
                                        + "contiene productos de otra tienda."
                        );
                    }
                }

                break;
            }

            default:
                Flash.error(session, "Acción no reconocida.");
                break;
        }

        session.setAttribute("carrito", carrito);
        session.setAttribute("carritoTienda", tiendaId);

        response.sendRedirect(urlCarrito);
    }

    private void quitar(
            HttpSession session,
            List<CarritoItem> carrito,
            CarritoItem item) {

        session.setAttribute(
                DESHACER,
                new ArrayList<>(carrito)
        );

        carrito.remove(item);
    }

    private static CarritoItem buscar(
            List<CarritoItem> carrito, int id) {

        for (CarritoItem item : carrito) {
            if (item.getId() == id) {
                return item;
            }
        }

        return null;
    }

    private static int entero(String valor, int porDefecto) {
        try {
            return Integer.parseInt(valor.trim());
        } catch (Exception e) {
            return porDefecto;
        }
    }

    /**
     * Comprueba que el producto exista en la tienda seleccionada.
     */
    private boolean productoPerteneceATienda(int id, String tiendaId) {
        String sql =
                "SELECT 1 FROM productos "
                + "WHERE id = ? AND tienda_id = ?";

        try (Connection con = Conexion.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.setString(2, tiendaId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }

        } catch (Exception e) {
            log("No se pudo validar la tienda del producto.", e);
            return false;
        }
    }

    /**
     * Devuelve el stock del producto en esa tienda.
     * Devuelve -1 si no se pudo consultar.
     */
    private int stock(int id, String tiendaId) {
        String sql =
                "SELECT stock FROM productos "
                + "WHERE id = ? AND tienda_id = ?";

        try (Connection con = Conexion.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.setString(2, tiendaId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("stock") : -1;
            }

        } catch (Exception e) {
            log("No se pudo consultar el stock.", e);
            return -1;
        }
    }
}
