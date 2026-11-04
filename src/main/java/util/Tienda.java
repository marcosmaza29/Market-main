package util;
import javax.servlet.http.HttpServletRequest;
/** Contexto de navegación; los permisos administrativos proceden siempre de la sesión. */
public final class Tienda {
    private Tienda() {}
    public static boolean valida(String id) {
        return "market".equals(id) || "juguetes".equals(id) || "cosmeticos".equals(id);
    }
    public static String actual(HttpServletRequest req) {
        String id = req.getParameter("tienda");
        if (valida(id)) return id;
        Object admin = req.getSession().getAttribute("adminTiendaId");
        if (Boolean.TRUE.equals(req.getSession().getAttribute("adminLogueado")) && valida((String) admin)) return (String) admin;
        String anterior = (String) req.getSession().getAttribute("tiendaActual");
        return valida(anterior) ? anterior : "market";
    }
    public static String nombre(String id) {
        return "juguetes".equals(id) ? "Juguetería" : "cosmeticos".equals(id) ? "Belleza y Cosméticos" : "Minimarket Anais";
    }
}
