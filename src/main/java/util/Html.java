package util;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/** Utilidades de presentación para las vistas JSP. */
public final class Html {

    private static final Locale PERU = new Locale("es", "PE");

    private Html() {
    }

    /** Escapa texto antes de pintarlo en HTML (contenido o atributos). */
    public static String esc(Object valor) {
        if (valor == null) {
            return "";
        }
        String s = valor.toString();
        StringBuilder sb = new StringBuilder(s.length() + 16);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '&': sb.append("&amp;"); break;
                case '<': sb.append("&lt;"); break;
                case '>': sb.append("&gt;"); break;
                case '"': sb.append("&quot;"); break;
                case '\'': sb.append("&#39;"); break;
                default: sb.append(c);
            }
        }
        return sb.toString();
    }

    /** Importe en soles con dos decimales: "S/ 12.50". */
    public static String soles(double importe) {
        return "S/ " + String.format(Locale.US, "%,.2f", importe);
    }

    public static String fecha(Date fecha) {
        return fecha == null ? "" : new SimpleDateFormat("dd/MM/yyyy", PERU).format(fecha);
    }

    public static String fechaHora(Date fecha) {
        return fecha == null ? "" : new SimpleDateFormat("dd/MM/yyyy HH:mm", PERU).format(fecha);
    }

    /** Fecha larga y legible: "lunes, 5 de octubre de 2026". */
    public static String fechaLarga(Date fecha) {
        return fecha == null ? "" : new SimpleDateFormat("EEEE, d 'de' MMMM 'de' yyyy", PERU).format(fecha);
    }

    public static String hora(Date fecha) {
        return fecha == null ? "" : new SimpleDateFormat("HH:mm", PERU).format(fecha);
    }

    /** Devuelve el parámetro recortado o null si viene vacío. */
    public static String param(javax.servlet.http.HttpServletRequest req, String nombre) {
        String v = req.getParameter(nombre);
        if (v == null) {
            return null;
        }
        v = v.trim();
        return v.isEmpty() ? null : v;
    }

    /** "1 producto" / "3 productos". */
    public static String plural(int n, String singular, String plural) {
        return n + " " + (n == 1 ? singular : plural);
    }
}
