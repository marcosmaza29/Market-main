package util;

/**
 * Las imágenes se sirven desde el bucket público "images" de Supabase Storage.
 * En la base se guarda la ruta relativa (p. ej. "bebidas/Pilsen.png").
 *
 * Variable de entorno opcional: IMAGES_BASE_URL
 */
public class Imagenes {

    private static final String BASE;
    private static String contexto = "";
    public static void contexto(String valor) { contexto = valor; }

    static {
        String base = System.getenv("IMAGES_BASE_URL");
        if (base == null || base.isEmpty()) {
            base = "https://gbovkpkveuuxtchvjhhh.supabase.co/storage/v1/object/public/images";
        }
        BASE = base.endsWith("/") ? base : base + "/";
    }

    /** URL base del bucket, terminada en "/". */
    public static String base() {
        return BASE;
    }

    public static String url(String ruta) {
        if (ruta == null || ruta.trim().isEmpty()) {
            return "";
        }
        ruta = ruta.trim();
        if (ruta.startsWith("local:")) {
            String[] partes = ruta.split(":",3);
            if (partes.length == 3 && Tienda.valida(partes[1]) && partes[2].matches("[a-f0-9-]{36}"))
                return contexto + "/producto-imagen?tienda=" + partes[1] + "&id=" + partes[2];
            return "";
        }
        if (ruta.startsWith("http://") || ruta.startsWith("https://")) {
            return ruta;
        }
        while (ruta.startsWith("/")) {
            ruta = ruta.substring(1);
        }
        return BASE + ruta;
    }
}
