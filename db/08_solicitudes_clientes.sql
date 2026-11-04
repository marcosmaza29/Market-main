-- Solicitudes de mejora y soporte por tienda.
CREATE TABLE IF NOT EXISTS solicitudes_clientes (
 id BIGSERIAL PRIMARY KEY,
 tienda_id VARCHAR(30) NOT NULL REFERENCES tiendas(id),
 correo_cliente VARCHAR(320) NOT NULL,
 nombre_cliente VARCHAR(180) NOT NULL,
 categoria VARCHAR(25) NOT NULL CHECK (categoria IN ('mejora','sugerencia','problema','otro')),
 asunto VARCHAR(150) NOT NULL,
 descripcion VARCHAR(2000) NOT NULL,
 estado VARCHAR(25) NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente','revision','proceso','resuelta','rechazada')),
 respuesta_admin VARCHAR(2000) NOT NULL DEFAULT '',
 fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_solicitudes_cliente_tienda_fecha ON solicitudes_clientes(tienda_id, fecha_creacion DESC);
CREATE INDEX IF NOT EXISTS idx_solicitudes_cliente_correo ON solicitudes_clientes(tienda_id, correo_cliente, fecha_creacion DESC);
ALTER TABLE solicitudes_clientes ENABLE ROW LEVEL SECURITY;
-- La aplicación se conecta mediante JDBC y controla permisos por sesión;
-- no se otorgan políticas públicas de acceso a esta tabla.
