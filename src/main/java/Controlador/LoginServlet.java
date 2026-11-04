package Controlador;

import java.io.IOException;
import java.net.URLEncoder;
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
import util.Rutas;

@WebServlet("/login-usuario")
public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession();

        String ctx = request.getContextPath();

        String correo = request.getParameter("correo") == null
                ? ""
                : request.getParameter("correo").trim();

        String contrasena = request.getParameter("contrasena") == null
                ? ""
                : request.getParameter("contrasena");

        String volver = request.getParameter("volver");

        String volverQuery = volver == null
                ? ""
                : "?volver=" + URLEncoder.encode(volver, "UTF-8");

        try (Connection con = util.Conexion.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT id, nombre, apellidos, correo, contrasena, "
                   + "rol, tienda_id "
                   + "FROM usuarios "
                   + "WHERE LOWER(correo) = LOWER(?)")) {

            ps.setString(1, correo);

            try (ResultSet rs = ps.executeQuery()) {

                boolean valido = false;

                if (rs.next()) {
                    try {
                        valido = PasswordUtil.checkPassword(
                                contrasena,
                                rs.getString("contrasena"));
                    } catch (IllegalArgumentException hashInvalido) {
                        valido = false;
                    }
                }

                if (!valido) {
                    Flash.formulario(
                            session,
                            request.getParameterMap(),
                            "contrasena",
                            "El correo o la contraseña no son correctos. "
                          + "Revisa que no tengas activadas las mayúsculas.");

                    response.sendRedirect(
                            ctx + "/jsp-Usuarios/login.jsp" + volverQuery);
                    return;
                }

                // Leer los datos antes de renovar la sesión.
                int usuarioId = rs.getInt("id");
                String nombre = rs.getString("nombre");
                String apellidos = rs.getString("apellidos");

                String correoRegistrado =
                        rs.getString("correo").toLowerCase(Locale.ROOT);

                String rol = rs.getString("rol");
                String tiendaId = rs.getString("tienda_id");

                if (rol == null) {
                    rol = "cliente";
                }

                rol = rol.trim().toLowerCase(Locale.ROOT);

                // Solo se admiten clientes y trabajadores en este login.
                if (!"cliente".equals(rol)
                        && !"trabajador".equals(rol)) {

                    Flash.error(
                            session,
                            "Esta cuenta no tiene un rol de acceso válido.");

                    response.sendRedirect(
                            ctx + "/jsp-Usuarios/login.jsp" + volverQuery);
                    return;
                }

                // Todo trabajador debe estar asociado a una tienda.
                if ("trabajador".equals(rol)
                        && (tiendaId == null
                        || tiendaId.trim().isEmpty())) {

                    Flash.error(
                            session,
                            "Tu cuenta de trabajador no tiene una tienda "
                          + "asignada. Contacta al administrador.");

                    response.sendRedirect(
                            ctx + "/jsp-Usuarios/login.jsp" + volverQuery);
                    return;
                }

                // Conservar el carrito al renovar la sesión.
                Object carrito = session.getAttribute("carrito");
                String tiendaNavegacion = util.Tienda.actual(request);

                session.invalidate();
                session = request.getSession(true);
                session.setAttribute("tiendaActual", tiendaNavegacion);

                if (carrito != null) {
                    session.setAttribute("carrito", carrito);
                }

                // Datos de identidad y permisos de la cuenta.
                session.setAttribute(
                        "usuarioNombre",
                        nombre + " " + apellidos);

                session.setAttribute(
                        "correoCliente",
                        correoRegistrado);

                session.setAttribute("usuarioId", usuarioId);
                session.setAttribute("usuarioRol", rol);
                session.setAttribute("tiendaId", tiendaId);

                if ("trabajador".equals(rol)) {
                    Flash.exito(
                            session,
                            "Bienvenido, " + nombre
                          + ". Has iniciado sesión como trabajador.");
                } else {
                    Flash.exito(
                            session,
                            "Hola, " + nombre + ". Iniciaste sesión.");
                }

                // Se conserva la redirección que ya utilizaba tu proyecto.
                response.sendRedirect(
                        Rutas.volver(
                                request,
                                "/jsp-Interfaz/interfaz.jsp"));
            }
        } catch (Exception e) {
            log("Error al iniciar sesión", e);

            Flash.error(
                    session,
                    "No pudimos conectarnos para iniciar tu sesión. "
                  + "Inténtalo de nuevo en unos segundos.");

            Flash.formulario(
                    session,
                    request.getParameterMap(),
                    null);

            response.sendRedirect(
                    ctx + "/jsp-Usuarios/login.jsp" + volverQuery);
        }
    }
}
