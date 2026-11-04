package Controlador;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import util.MonitorRendimiento;
import util.Tienda;

@WebServlet(urlPatterns={"/monitor/estado", "/monitor/metrics"})
public class MonitorServlet extends HttpServlet {
    @Override protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setHeader("Cache-Control", "no-store");
        if (request.getServletPath().endsWith("/metrics")) {
            String secreto = System.getenv("METRICS_TOKEN");
            String recibido = request.getHeader("Authorization");
            if (secreto == null || secreto.length() < 24 || recibido == null || !MessageDigest.isEqual(
                    ("Bearer " + secreto).getBytes(StandardCharsets.UTF_8), recibido.getBytes(StandardCharsets.UTF_8))) {
                response.sendError(403); return;
            }
            response.setContentType("text/plain; version=0.0.4; charset=UTF-8");
            response.getWriter().write(MonitorRendimiento.prometheus());
            return;
        }
        HttpSession sesion = request.getSession(false);
        String tienda = sesion == null ? null : (String)sesion.getAttribute("adminTiendaId");
        if (sesion == null || !Boolean.TRUE.equals(sesion.getAttribute("adminLogueado")) || !Tienda.valida(tienda)
                || !tienda.equals(request.getParameter("tienda"))) { response.sendError(403); return; }
        response.setContentType("application/json; charset=UTF-8");
        response.getWriter().write(MonitorRendimiento.json(tienda));
    }
}
