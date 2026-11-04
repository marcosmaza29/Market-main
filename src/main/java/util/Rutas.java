package util;

import javax.servlet.http.HttpServletRequest;

/** Validación de destinos de redirección (evita redirecciones abiertas). */
public final class Rutas {

    private Rutas() {
    }

    /**
     * Devuelve la ruta interna indicada en el parámetro "volver" si es segura;
     * si no, la ruta por defecto. Ambas se devuelven con el contexto de la aplicación.
     */
    public static String volver(HttpServletRequest request, String porDefecto) {
        String v = request.getParameter("volver");
        String ctx = request.getContextPath();
        if (v != null && v.startsWith("/") && !v.startsWith("//") && !v.contains("\\")
                && (v.startsWith("/jsp-Interfaz/") || v.startsWith("/jsp-Usuarios/editarUsuario.jsp"))) {
            return ctx + v;
        }
        return ctx + porDefecto;
    }
}
