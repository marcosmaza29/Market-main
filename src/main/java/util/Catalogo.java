package util;

import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Listas de valores compartidas por la tienda y el panel (una sola fuente de verdad). */
public final class Catalogo {

    /** Categoría de producto → icono de Material Symbols. */
    public static final Map<String, String> CATEGORIAS;

    static {
        LinkedHashMap<String, String> m = new LinkedHashMap<>();
        m.put("Frutas", "nutrition");
        m.put("Verduras", "eco");
        m.put("Abarrotes", "grocery");
        m.put("Bebidas", "local_drink");
        m.put("Limpieza", "cleaning_services");
        m.put("Cuidado Personal", "soap");
        m.put("Mascotas", "pets");
        CATEGORIAS = Collections.unmodifiableMap(m);
    }

    /** Categorías aisladas por tienda: comparten la infraestructura, no el catálogo. */
    public static Map<String, String> categorias(String tienda) {
        LinkedHashMap<String, String> m = new LinkedHashMap<>();
        if ("juguetes".equals(tienda)) {
            m.put("Muñecas", "toys");
            m.put("Muñecos", "person");
            m.put("Carros", "directions_car");
            m.put("Figuras de acción", "person");
            m.put("Rompecabezas", "category");
            m.put("Juguetes al aire libre", "eco");
            m.put("Vehículos", "directions_car");
            m.put("Juegos de mesa", "extension");
            m.put("Peluches", "pets");
            m.put("Construcción", "construction");
            m.put("Educativos", "school");
            m.put("Bebés", "child_care");
        } else if ("cosmeticos".equals(tienda)) {
            m.put("Maquillaje", "palette");
            m.put("Cuidado facial", "face");
            m.put("Cuidado capilar", "content_cut");
            m.put("Perfumes", "spa");
            m.put("Cuidado corporal", "soap");
            m.put("Uñas", "brush");
            m.put("Accesorios", "shopping_bag");
        } else {
            m.putAll(CATEGORIAS);
        }
        return Collections.unmodifiableMap(m);
    }

    public static boolean esCategoria(String categoria, String tienda) {
        return categoria != null && categorias(tienda).containsKey(categoria);
    }

    public static String iconoCategoria(String categoria, String tienda) {
        String icono = categorias(tienda).get(categoria);
        return icono == null ? "category" : icono;
    }

    public static final List<String> UNIDADES = Collections.unmodifiableList(Arrays.asList(
            "Unidad", "Paquete", "Caja", "Kilogramos", "Gramos", "Litros", "Mililitros"));

    /** Valores permitidos por la restricción CHECK de proveedores.tipo. */
    public static final List<String> TIPOS_PROVEEDOR = Collections.unmodifiableList(Arrays.asList(
            "Abarrotes", "Bebidas", "Licores", "Limpieza", "Frutas/Verduras", "Otros"));

    public static List<String> tiposProveedor(String tienda) {
        if ("juguetes".equals(tienda)) return Arrays.asList("Juguetes", "Educativos", "Bebés", "Otros");
        if ("cosmeticos".equals(tienda)) return Arrays.asList("Maquillaje", "Cuidado personal", "Perfumes", "Accesorios", "Otros");
        return TIPOS_PROVEEDOR;
    }

    /** Cache-busting de /assets: cambia en cada despliegue. */
    public static final String VERSION = Long.toString(System.currentTimeMillis(), 36);

    private Catalogo() {
    }

    public static boolean esCategoria(String c) {
        return c != null && CATEGORIAS.containsKey(c);
    }

    public static String iconoCategoria(String c) {
        String icono = c == null ? null : CATEGORIAS.get(c);
        return icono == null ? "category" : icono;
    }
}
