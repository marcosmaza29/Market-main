package util;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.servlet.ServletContext;

/**
 * Inserta en línea los SVG oficiales de Material Symbols guardados en /WEB-INF/iconos
 * (descargados con tools/descargar-iconos.sh). Solo reescribe la etiqueta <svg> para
 * heredar el color del texto, aplicar clases y exponer o no el icono a lectores de pantalla.
 */
public final class Icono {

    private static final Pattern VIEWBOX = Pattern.compile("viewBox=\"([^\"]+)\"");
    private static final Pattern CONTENIDO = Pattern.compile("<svg[^>]*>(.*)</svg>", Pattern.DOTALL);
    private static final Map<String, String[]> CACHE = new ConcurrentHashMap<>();

    private Icono() {
    }

    public static String svg(ServletContext ctx, String nombre, String clases, String etiqueta) {
        String[] partes = CACHE.computeIfAbsent(nombre, n -> cargar(ctx, n));
        if (partes == null) {
            return "";
        }
        StringBuilder sb = new StringBuilder(160 + partes[1].length());
        sb.append("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"").append(partes[0]).append('"')
                .append(" class=\"icono");
        if (clases != null && !clases.isEmpty()) {
            sb.append(' ').append(Html.esc(clases));
        }
        sb.append('"');
        if (etiqueta != null && !etiqueta.isEmpty()) {
            sb.append(" role=\"img\" aria-label=\"").append(Html.esc(etiqueta)).append('"');
        } else {
            sb.append(" aria-hidden=\"true\"");
        }
        sb.append(" focusable=\"false\">").append(partes[1]).append("</svg>");
        return sb.toString();
    }

    private static String[] cargar(ServletContext ctx, String nombre) {
        if (!nombre.matches("[a-z0-9_]+")) {
            return null;
        }
        try (InputStream in = ctx.getResourceAsStream("/WEB-INF/iconos/" + nombre + ".svg")) {
            if (in == null) {
                ctx.log("Icono no encontrado: " + nombre);
                return null;
            }
            ByteArrayOutputStream buffer = new ByteArrayOutputStream();
            byte[] bloque = new byte[1024];
            int leidos;
            while ((leidos = in.read(bloque)) != -1) {
                buffer.write(bloque, 0, leidos);
            }
            String svg = new String(buffer.toByteArray(), StandardCharsets.UTF_8);
            Matcher vb = VIEWBOX.matcher(svg);
            Matcher cont = CONTENIDO.matcher(svg);
            if (!vb.find() || !cont.find()) {
                return null;
            }
            return new String[]{vb.group(1), cont.group(1)};
        } catch (IOException e) {
            ctx.log("No se pudo leer el icono " + nombre, e);
            return null;
        }
    }
}
