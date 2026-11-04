package util;

import javax.servlet.http.HttpServletRequest;

/** Lectura y validación de los campos del formulario de producto (alta y edición). */
public final class ProductoForm {

    public String nombre, descripcion, unidad, categoria, imagen;
    public double precio, cantidad;
    public int stock;
    /** Campo con error y mensaje; null si todo es válido. */
    public String campoError, mensajeError;

    private ProductoForm() {
    }

    public static ProductoForm leer(HttpServletRequest req) {
        return leer(req, "market");
    }

    public static ProductoForm leer(HttpServletRequest req, String tienda) {
        ProductoForm f = new ProductoForm();
        f.nombre = texto(req, "nombre");
        f.descripcion = texto(req, "descripcion");
        f.unidad = texto(req, "unidad");
        f.categoria = texto(req, "categoria");
        f.imagen = texto(req, "imagen").replaceFirst("^/+", "");

        if (f.nombre.isEmpty()) {
            return f.error("nombre", "Escribe el nombre del producto.");
        }
        try {
            f.precio = Double.parseDouble(texto(req, "precio").replace(',', '.'));
            if (f.precio < 0.10) {
                return f.error("precio", "El precio debe ser al menos S/ 0.10.");
            }
        } catch (NumberFormatException e) {
            return f.error("precio", "Escribe el precio con números, por ejemplo 4.50.");
        }
        try {
            f.stock = Integer.parseInt(texto(req, "stock"));
            if (f.stock < 0) {
                return f.error("stock", "El stock no puede ser negativo.");
            }
        } catch (NumberFormatException e) {
            return f.error("stock", "Escribe el stock como un número entero.");
        }
        try {
            f.cantidad = Double.parseDouble(texto(req, "cantidad").replace(',', '.'));
            if (f.cantidad <= 0) {
                return f.error("cantidad", "El contenido debe ser mayor que 0.");
            }
        } catch (NumberFormatException e) {
            return f.error("cantidad", "Escribe el contenido con números, por ejemplo 1 o 500.");
        }
        if (!Catalogo.UNIDADES.contains(f.unidad)) {
            return f.error("unidad", "Elige una unidad de medida.");
        }
        if (!Catalogo.esCategoria(f.categoria, tienda)) {
            return f.error("categoria", "Elige una categoría.");
        }
        return f;
    }

    /** Valor guardado en productos.unidad, por ejemplo "500 Mililitros" o "1 Unidad". */
    public String unidadCompleta() {
        String c = cantidad == Math.rint(cantidad) ? String.valueOf((long) cantidad) : String.valueOf(cantidad);
        return c + " " + unidad;
    }

    private ProductoForm error(String campo, String mensaje) {
        campoError = campo;
        mensajeError = mensaje;
        return this;
    }

    private static String texto(HttpServletRequest req, String nombre) {
        String v = req.getParameter(nombre);
        return v == null ? "" : v.trim();
    }
}
