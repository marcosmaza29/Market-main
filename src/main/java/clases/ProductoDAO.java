package clases;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class ProductoDAO {

    public void agregarProducto(Producto producto, String tiendaId)
            throws SQLException {

        if (tiendaId == null ||
            !(tiendaId.equals("market")
              || tiendaId.equals("juguetes")
              || tiendaId.equals("cosmeticos"))) {
            throw new IllegalArgumentException("Tienda no válida.");
        }

        String sql = "INSERT INTO productos " +
                "(nombre, descripcion, precio, stock, unidad, tienda_id) " +
                "VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = util.Conexion.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, producto.getNombre());
            stmt.setString(2, producto.getDescripcion());
            stmt.setDouble(3, producto.getPrecio());
            stmt.setInt(4, producto.getStock());
            stmt.setString(5, producto.getUnidad());
            stmt.setString(6, tiendaId);

            stmt.executeUpdate();
        }
    }
}