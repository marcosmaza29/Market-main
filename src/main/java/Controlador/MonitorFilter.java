package Controlador;

import java.io.IOException;
import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.*;
import javax.servlet.http.HttpServletResponseWrapper;
import util.MonitorRendimiento;
import util.Tienda;

/** Registra solicitudes por tienda sin crear sesiones ni contabilizar el polling del monitor. */
@WebFilter("/*")
public class MonitorFilter implements Filter {
    @Override public void init(FilterConfig f) {}
    @Override public void destroy() {}
    @Override public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        String ruta = req.getRequestURI().substring(req.getContextPath().length());
        if (ruta.startsWith("/assets/") || ruta.startsWith("/WEB-INF/") || ruta.startsWith("/monitor/")
                || ruta.startsWith("/jsp-Admin/") || ruta.matches(".*\\.(css|js|svg|png|jpg|jpeg|webp|ico|woff2?)$")) {
            chain.doFilter(request, response); return;
        }
        String tienda = req.getParameter("tienda");
        if (!Tienda.valida(tienda)) {
            HttpSession sesion = req.getSession(false);
            if (sesion != null) {
                Object actual = sesion.getAttribute("tiendaActual");
                if (actual instanceof String && Tienda.valida((String)actual)) tienda = (String)actual;
            }
        }
        if (!Tienda.valida(tienda)) tienda = "market";
        final int[] status = {200};
        HttpServletResponseWrapper wrapper = new HttpServletResponseWrapper((HttpServletResponse) response) {
            @Override public void setStatus(int sc) { status[0] = sc; super.setStatus(sc); }
            @Override public void sendError(int sc) throws IOException { status[0] = sc; super.sendError(sc); }
            @Override public void sendError(int sc, String msg) throws IOException { status[0] = sc; super.sendError(sc,msg); }
            @Override public void sendRedirect(String location) throws IOException { status[0] = 302; super.sendRedirect(location); }
        };
        long inicio = System.nanoTime(); boolean fallo = false;
        MonitorRendimiento.comenzar(tienda);
        try { chain.doFilter(request, wrapper); }
        catch (IOException | ServletException | RuntimeException ex) { fallo = true; throw ex; }
        finally { MonitorRendimiento.terminar(tienda, (System.nanoTime()-inicio)/1000000L, fallo || status[0] >= 500); }
    }
}
