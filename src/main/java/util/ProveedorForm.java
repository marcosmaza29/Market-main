package util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.http.HttpServletRequest;

/** Lectura y validación del formulario de proveedor (alta y edición). */
public final class ProveedorForm {

    public String nombre, ruc, contacto, telefono, direccion, tipo;
    public String campoError, mensajeError;

    private ProveedorForm() {
    }

    public static ProveedorForm leer(HttpServletRequest req) {
        ProveedorForm f = new ProveedorForm();
        f.nombre = texto(req, "nombre");
        f.ruc = texto(req, "ruc").replaceAll("\\s", "");
        f.contacto = texto(req, "contacto");
        f.telefono = texto(req, "telefono");
        f.direccion = texto(req, "direccion");
        f.tipo = texto(req, "tipo");

        if (f.nombre.isEmpty()) {
            return f.error("nombre", "Escribe la razón social o el nombre comercial.");
        }
        if (!f.ruc.matches("\\d{11}")) {
            return f.error("ruc", "El RUC tiene 11 dígitos (sin espacios ni guiones).");
        }
        if (f.contacto.isEmpty()) {
            return f.error("contacto", "Escribe el nombre de la persona de contacto.");
        }
        if (!f.telefono.isEmpty() && !f.telefono.matches("[+0-9 ()-]{6,20}")) {
            return f.error("telefono", "Usa solo números, espacios y +, por ejemplo +51 987 654 321.");
        }
        if (!Catalogo.tiposProveedor((String) req.getSession().getAttribute("adminTiendaId")).contains(f.tipo)) {
            return f.error("tipo", "Elige qué tipo de productos ofrece.");
        }
        return f;
    }

    /** Registra una acción sobre proveedores en el historial del panel. */
    public static void registrar(Connection con, String admin, String tienda, String accion, int id, String detalles) throws java.sql.SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO historial_admin (usuario_admin, accion, tabla_afectada, id_afectado, detalles, tienda_id) VALUES (?, ?, 'proveedores', ?, ?, ?)")) {
            ps.setString(1, admin == null ? "Administrador" : admin);
            ps.setString(2, accion);
            ps.setInt(3, id);
            ps.setString(4, detalles);
            ps.setString(5, tienda);
            ps.executeUpdate();
        }
    }

    private ProveedorForm error(String campo, String mensaje) {
        campoError = campo;
        mensajeError = mensaje;
        return this;
    }

    private static String texto(HttpServletRequest req, String nombre) {
        String v = req.getParameter(nombre);
        return v == null ? "" : v.trim();
    }
}
