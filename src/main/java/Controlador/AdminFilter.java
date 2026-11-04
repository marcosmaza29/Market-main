package Controlador;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import util.Flash;

@WebFilter({
    "/jsp-Productos/*",
    "/jsp-Proveedores/*",
    "/jsp-Admin/*",
    "/jsp-Interfaz/configurar_tienda.jsp",
    "/jsp-Interfaz/guardar_configuracion.jsp"
})
public class AdminFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig)
            throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request,
                         ServletResponse response,
                         FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        req.setCharacterEncoding("UTF-8");

        String ruta = req.getRequestURI()
                .substring(req.getContextPath().length());

        // El login administrativo debe ser público.
        if ("/jsp-Admin/loginAdmin.jsp".equals(ruta)) {
            chain.doFilter(request, response);
            return;
        }

        HttpSession session = req.getSession(false);

        String tiendaSolicitada = util.Tienda.actual(req);
        boolean autorizado = session != null
                && util.Tienda.valida((String) session.getAttribute("adminTiendaId"))
                && tiendaSolicitada.equals(session.getAttribute("adminTiendaId"))
                && Boolean.TRUE.equals(
                        session.getAttribute("adminLogueado"));

        if (autorizado) {
            chain.doFilter(request, response);
            return;
        }

        // Crear una sesión únicamente si hace falta mostrar el mensaje
        // o guardar la ruta que el usuario solicitó.
        HttpSession nueva = req.getSession(true);

        // Guardar la página solicitada para regresar después del login.
        if ("GET".equalsIgnoreCase(req.getMethod())) {
            String pedida = ruta;
            String query = req.getQueryString();

            if (query != null && !query.isEmpty()) {
                pedida += "?" + query;
            }

            nueva.setAttribute("admin.volver", pedida);
        }

        Flash.info(
                nueva,
                "Inicia sesión como administrador para continuar.");

        res.sendRedirect(
                req.getContextPath()
                + "/jsp-Admin/loginAdmin.jsp?tienda=" + tiendaSolicitada);
    }

    @Override
    public void destroy() {
    }
}