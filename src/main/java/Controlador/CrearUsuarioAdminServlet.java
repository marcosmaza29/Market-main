package Controlador;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Locale;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import util.Flash;
import util.PasswordUtil;

@WebServlet("/admin/crear-usuario")
public class CrearUsuarioAdminServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        String ctx = request.getContextPath();
        String destino = ctx + "/jsp-Admin/usuariosAdmin.jsp";

        // Verificar que haya iniciado sesión un administrador
        if (session == null
                || !Boolean.TRUE.equals(
                        session.getAttribute("adminLogueado"))) {
            response.sendRedirect(ctx + "/jsp-Admin/loginAdmin.jsp");
            return;
        }

        // Validar el token de seguridad del formulario
        String csrfSesion =
                (String) session.getAttribute("csrf.admin.usuarios");
        String csrfFormulario = request.getParameter("csrf");

        if (csrfSesion == null || csrfFormulario == null
                || !csrfSesion.equals(csrfFormulario)) {
            Flash.error(session,
                    "Actualiza la página e inténtalo nuevamente.");
            response.sendRedirect(destino);
            return;
        }

        String nombre = texto(request, "nombre");
        String apellidos = texto(request, "apellidos");
        String correo = texto(request, "correo")
                .toLowerCase(Locale.ROOT);
        String contrasena = request.getParameter("contrasena");
        String confirmar = request.getParameter("confirmar");

        if (contrasena == null) contrasena = "";
        if (confirmar == null) confirmar = "";

        String campo = null;
        String mensaje = null;

        if (nombre.isEmpty()) {
            campo = "nombre";
            mensaje = "Escribe el nombre.";
        } else if (apellidos.isEmpty()) {
            campo = "apellidos";
            mensaje = "Escribe los apellidos.";
        } else if (!correo.matches(
                "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            campo = "correo";
            mensaje = "Escribe un correo válido.";
        } else if (contrasena.length() < 8
                || !contrasena.matches(".*[A-Za-z].*")
                || !contrasena.matches(".*[0-9].*")) {
            campo = "contrasena";
            mensaje = "Usa al menos 8 caracteres, una letra y un número.";
        } else if (!contrasena.equals(confirmar)) {
            campo = "confirmar";
            mensaje = "Las contraseñas no coinciden.";
        }

        if (campo != null) {
            Flash.formulario(session, request.getParameterMap(),
                    campo, mensaje);
            response.sendRedirect(destino);
            return;
        }

        try (Connection con = util.Conexion.getConnection()) {

            String tiendaId = (String) session.getAttribute("adminTiendaId");
        if (tiendaId == null || !(tiendaId.equals("market") || tiendaId.equals("juguetes") || tiendaId.equals("cosmeticos"))) {
            Flash.error(session, "La tienda de la sesión no es válida.");
            response.sendRedirect(destino);
            return;
        }

        // Comprobar que el correo no esté registrado
            String consulta =
                    "SELECT 1 FROM usuarios WHERE LOWER(correo) = LOWER(?)";

            try (PreparedStatement ps = con.prepareStatement(consulta)) {
                ps.setString(1, correo);

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        Flash.formulario(session,
                                request.getParameterMap(),
                                "correo",
                                "Ya existe una cuenta con ese correo.");
                        response.sendRedirect(destino);
                        return;
                    }
                }
            }

            // Guardar la contraseña cifrada, nunca en texto plano
            String sql = "INSERT INTO usuarios "
                    + "(nombre, apellidos, correo, contrasena, rol, tienda_id) "
                    + "VALUES (?, ?, ?, ?, 'cliente', ?)";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, nombre);
                ps.setString(2, apellidos);
                ps.setString(3, correo);
                ps.setString(4,
                        PasswordUtil.hashPassword(contrasena));
                ps.setString(5, tiendaId);
                ps.executeUpdate();
            }

            Flash.exito(session,
                    "Se creó la cuenta de " + nombre + ".");

        } catch (Exception e) {
            log("Error al crear un usuario desde administración", e);
            Flash.error(session,
                    "No se pudo crear el usuario. Revisa la conexión.");
        }

        response.sendRedirect(destino);
    }

    private static String texto(HttpServletRequest request,
            String campo) {
        String valor = request.getParameter(campo);
        return valor == null ? "" : valor.trim();
    }
}