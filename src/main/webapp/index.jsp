<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Seleccionar Tienda - Sistema Multi-Tienda</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f7f6;
            margin: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }
        .container {
            text-align: center;
            max-width: 900px;
            padding: 20px;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
        }
        p {
            color: #666;
            margin-bottom: 40px;
        }
        .cards-grid {
            display: flex;
            justify-content: center;
            gap: 25px;
            flex-wrap: wrap;
        }
        .card {
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.08);
            width: 250px;
            padding: 30px 20px;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            text-decoration: none;
            color: inherit;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        .card:hover {
            transform: translateY(-8px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }
        .card h3 {
            margin-top: 15px;
            color: #2c3e50;
            font-size: 1.4rem;
        }
        .card p {
            font-size: 0.9rem;
            color: #7f8c8d;
            margin: 10px 0 20px 0;
        }
        .btn-tienda {
            padding: 10px 20px;
            border-radius: 6px;
            color: white;
            font-weight: bold;
            border: none;
            cursor: pointer;
            transition: background 0.2s;
        }
        .card.market .btn-tienda { background-color: #27ae60; }
        .card.market:hover .btn-tienda { background-color: #219653; }
        
        .card.juguetes .btn-tienda { background-color: #e67e22; }
        .card.juguetes:hover .btn-tienda { background-color: #d35400; }

        .card.cosmeticos .btn-tienda { background-color: #9b59b6; }
        .card.cosmeticos:hover .btn-tienda { background-color: #8e44ad; }
    </style>
</head>
<body>

    <div class="container">
        <h1>Bienvenido al Sistema Multi-Tienda</h1>
        <p>Selecciona la sucursal o tienda a la que deseas acceder:</p>

        <div class="cards-grid">
            <!-- Opción 1: Minimarket -> Te manda exactamente a la interfaz que ya tenías por defecto -->
            <a href="jsp-Interfaz/acceso_tienda.jsp?tienda=market" class="card market">
                <h3>Minimarket</h3>
                <p>Gestión de abarrotes, productos y caja general.</p>
                <span class="btn-tienda">Ingresar a Market</span>
            </a>

            <!-- Opción 2: Juguetería (puedes apuntar a su propia vista o servlet) -->
            <a href="jsp-Interfaz/acceso_tienda.jsp?tienda=juguetes" class="card juguetes">
                <h3>Juguetería</h3>
                <p>Control de juguetes, inventario y sección infantil.</p>
                <span class="btn-tienda">Ingresar a Juguetes</span>
            </a>

            <!-- Opción 3: Cosméticos -->
            <a href="jsp-Interfaz/acceso_tienda.jsp?tienda=cosmeticos" class="card cosmeticos">
                <h3>Cosméticos</h3>
                <p>Administración de productos de belleza y cuidado.</p>
                <span class="btn-tienda">Ingresar a Cosméticos</span>
            </a>
        </div>
    </div>

</body>
</html>