package Controlador;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import util.Flash;
import util.PasswordUtil;

@WebServlet("/registro-nuevo")
public class RegistroServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();
        String nombre = texto(request, "nombre");
        String apellidos = texto(request, "apellidos");
        String correo = texto(request, "correo").toLowerCase();
        String contrasena = request.getParameter("contrasena") == null ? "" : request.getParameter("contrasena");
        String confirmar = request.getParameter("confirmar") == null ? "" : request.getParameter("confirmar");

        String campo = null, mensaje = null;
        if (nombre.isEmpty()) {
            campo = "nombre"; mensaje = "Escribe tu nombre.";
        } else if (apellidos.isEmpty()) {
            campo = "apellidos"; mensaje = "Escribe tus apellidos.";
        } else if (!correo.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            campo = "correo"; mensaje = "Escribe un correo válido, por ejemplo nombre@correo.com.";
        } else if (contrasena.length() < 8 || !contrasena.matches(".*[A-Za-z].*") || !contrasena.matches(".*[0-9].*")) {
            campo = "contrasena"; mensaje = "La contraseña necesita al menos 8 caracteres, una letra y un número.";
        } else if (!contrasena.equals(confirmar)) {
            campo = "confirmar"; mensaje = "Las contraseñas no coinciden.";
        }
        if (campo != null) {
            volverConError(request, response, campo, mensaje);
            return;
        }

        try (Connection con = util.Conexion.getConnection()) {
            try (PreparedStatement ps = con.prepareStatement("SELECT 1 FROM usuarios WHERE lower(correo) = lower(?)")) {
                ps.setString(1, correo);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        volverConError(request, response, "correo",
                                "Ya existe una cuenta con este correo. Inicia sesión o recupera tu contraseña.");
                        return;
                    }
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO usuarios (nombre, apellidos, correo, contrasena, tienda_id) VALUES (?, ?, ?, ?, ?)")) {
                ps.setString(1, nombre);
                ps.setString(2, apellidos);
                ps.setString(3, correo);
                ps.setString(4, PasswordUtil.hashPassword(contrasena));
                ps.setString(5, util.Tienda.actual(request));
                ps.executeUpdate();
            }
            Flash.exito(session, "Tu cuenta está lista. Inicia sesión con " + correo + ".");
            Flash.formulario(session, java.util.Collections.singletonMap("correo", new String[]{correo}), null);
            response.sendRedirect(request.getContextPath() + "/jsp-Usuarios/login.jsp");
        } catch (Exception e) {
            log("Error al registrar usuario", e);
            volverConError(request, response, null, "No pudimos crear tu cuenta por un problema de conexión. Inténtalo de nuevo.");
        }
    }

    private void volverConError(HttpServletRequest request, HttpServletResponse response, String campo, String mensaje)
            throws IOException {
        HttpSession session = request.getSession();
        if (campo == null) {
            Flash.error(session, mensaje); // error general: notificación
        }
        Flash.formulario(session, request.getParameterMap(), campo, mensaje); // error de campo: junto al campo
        response.sendRedirect(request.getContextPath() + "/jsp-Usuarios/registro.jsp");
    }

    private static String texto(HttpServletRequest request, String nombre) {
        String v = request.getParameter(nombre);
        return v == null ? "" : v.trim();
    }
}
