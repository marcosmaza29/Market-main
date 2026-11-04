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

@WebServlet("/editar-usuario")
public class EditarUsuarioServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();
        String correoOriginal = (String) session.getAttribute("correoCliente");
        if (correoOriginal == null) {
            response.sendRedirect(request.getContextPath() + "/jsp-Usuarios/login.jsp");
            return;
        }

        String nombre = texto(request, "nombre");
        String apellidos = texto(request, "apellidos");
        String nuevoCorreo = texto(request, "correo").toLowerCase();
        String contrasena = request.getParameter("contrasena") == null ? "" : request.getParameter("contrasena");
        String confirmar = request.getParameter("confirmar") == null ? "" : request.getParameter("confirmar");
        boolean cambiaContrasena = !contrasena.isEmpty();

        String campo = null, mensaje = null;
        if (nombre.isEmpty()) {
            campo = "nombre"; mensaje = "Escribe tu nombre.";
        } else if (apellidos.isEmpty()) {
            campo = "apellidos"; mensaje = "Escribe tus apellidos.";
        } else if (!nuevoCorreo.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            campo = "correo"; mensaje = "Escribe un correo válido, por ejemplo nombre@correo.com.";
        } else if (cambiaContrasena && (contrasena.length() < 8 || !contrasena.matches(".*[A-Za-z].*") || !contrasena.matches(".*[0-9].*"))) {
            campo = "contrasena"; mensaje = "La nueva contraseña necesita al menos 8 caracteres, una letra y un número.";
        } else if (cambiaContrasena && !contrasena.equals(confirmar)) {
            campo = "confirmar"; mensaje = "Las contraseñas no coinciden.";
        }
        if (campo != null) {
            volverConError(request, response, campo, mensaje);
            return;
        }

        try (Connection con = util.Conexion.getConnection()) {
            if (!nuevoCorreo.equalsIgnoreCase(correoOriginal)) {
                try (PreparedStatement ps = con.prepareStatement("SELECT 1 FROM usuarios WHERE lower(correo) = lower(?)")) {
                    ps.setString(1, nuevoCorreo);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            volverConError(request, response, "correo", "Ese correo ya pertenece a otra cuenta.");
                            return;
                        }
                    }
                }
            }
            // Si la contraseña se deja en blanco, se conserva la actual
            String sql = cambiaContrasena
                    ? "UPDATE usuarios SET nombre = ?, apellidos = ?, correo = ?, contrasena = ? WHERE lower(correo) = lower(?)"
                    : "UPDATE usuarios SET nombre = ?, apellidos = ?, correo = ? WHERE lower(correo) = lower(?)";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                int i = 1;
                ps.setString(i++, nombre);
                ps.setString(i++, apellidos);
                ps.setString(i++, nuevoCorreo);
                if (cambiaContrasena) {
                    ps.setString(i++, PasswordUtil.hashPassword(contrasena));
                }
                ps.setString(i, correoOriginal);
                if (ps.executeUpdate() == 0) {
                    volverConError(request, response, null, "No encontramos tu cuenta. Vuelve a iniciar sesión.");
                    return;
                }
            }
            session.setAttribute("usuarioNombre", nombre + " " + apellidos);
            session.setAttribute("correoCliente", nuevoCorreo);
            Flash.exito(session, cambiaContrasena ? "Guardamos tus datos y tu nueva contraseña." : "Guardamos tus datos.");
            response.sendRedirect(request.getContextPath() + "/jsp-Usuarios/editarUsuario.jsp");
        } catch (Exception e) {
            log("Error al editar usuario", e);
            volverConError(request, response, null, "No pudimos guardar los cambios por un problema de conexión. Inténtalo de nuevo.");
        }
    }

    private void volverConError(HttpServletRequest request, HttpServletResponse response, String campo, String mensaje)
            throws IOException {
        HttpSession session = request.getSession();
        if (campo == null) {
            Flash.error(session, mensaje); // error general: notificación
        }
        Flash.formulario(session, request.getParameterMap(), campo, mensaje); // error de campo: junto al campo
        response.sendRedirect(request.getContextPath() + "/jsp-Usuarios/editarUsuario.jsp");
    }

    private static String texto(HttpServletRequest request, String nombre) {
        String v = request.getParameter(nombre);
        return v == null ? "" : v.trim();
    }
}
