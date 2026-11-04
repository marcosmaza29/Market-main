package Controlador;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import util.Flash;
import util.PasswordUtil;

@WebServlet("/recuperar-password")
public class RecuperarPasswordServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession();
        String correo = request.getParameter("correo") == null ? "" : request.getParameter("correo").trim().toLowerCase();
        String nueva = request.getParameter("nueva") == null ? "" : request.getParameter("nueva");
        String confirmar = request.getParameter("confirmar") == null ? "" : request.getParameter("confirmar");

        if (correo.isEmpty()) {
            volverConError(request, response, "correo", "Escribe el correo con el que te registraste.");
            return;
        }
        if (nueva.length() < 8 || !nueva.matches(".*[A-Za-z].*") || !nueva.matches(".*[0-9].*")) {
            volverConError(request, response, "nueva", "La contraseña necesita al menos 8 caracteres, una letra y un número.");
            return;
        }
        if (!nueva.equals(confirmar)) {
            volverConError(request, response, "confirmar", "Las contraseñas no coinciden.");
            return;
        }

        try (Connection con = util.Conexion.getConnection();
             PreparedStatement ps = con.prepareStatement("UPDATE usuarios SET contrasena = ? WHERE lower(correo) = lower(?)")) {
            ps.setString(1, PasswordUtil.hashPassword(nueva));
            ps.setString(2, correo);
            if (ps.executeUpdate() == 0) {
                volverConError(request, response, "correo",
                        "No encontramos una cuenta con ese correo. Revisa cómo lo escribiste o crea una cuenta nueva.");
                return;
            }
            Flash.exito(session, "Actualizamos tu contraseña. Ya puedes iniciar sesión.");
            Flash.formulario(session, java.util.Collections.singletonMap("correo", new String[]{correo}), null);
            response.sendRedirect(request.getContextPath() + "/jsp-Usuarios/login.jsp");
        } catch (Exception e) {
            log("Error al recuperar contraseña", e);
            volverConError(request, response, null, "No pudimos actualizar la contraseña por un problema de conexión. Inténtalo de nuevo.");
        }
    }

    private void volverConError(HttpServletRequest request, HttpServletResponse response, String campo, String mensaje)
            throws IOException {
        HttpSession session = request.getSession();
        if (campo == null) {
            Flash.error(session, mensaje); // error general: notificación
        }
        Flash.formulario(session, request.getParameterMap(), campo, mensaje); // error de campo: junto al campo
        response.sendRedirect(request.getContextPath() + "/jsp-Usuarios/recuperar.jsp");
    }
}
