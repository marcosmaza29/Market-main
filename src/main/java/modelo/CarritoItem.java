package modelo;

public class CarritoItem {

    private int id;
    private String nombre;
    private double precio;
    private int cantidad;
    private String unidad;

    public CarritoItem(int id, String nombre, double precio, int cantidad, String unidad) {
        this.id = id;
        this.nombre = nombre;
        this.precio = precio;
        this.cantidad = cantidad;
        this.unidad = unidad;
    }

    // Getters y Setters
    public int getId() {
        return id;
    }

    public String getNombre() {
        return nombre;
    }

    public double getPrecio() {
        return precio;
    }

    public int getCantidad() {
        return cantidad;
    }

    public String getUnidad() {
        return unidad;
    }

    public double getSubtotal() {
        return precio * cantidad;
    }

    public void setCantidad(int cantidad) {
        this.cantidad = cantidad;
    }
}
