CREATE TABLE IF NOT EXISTS imagenes_producto (
 id UUID PRIMARY KEY,
 tienda_id VARCHAR(30) NOT NULL REFERENCES tiendas(id),
 tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('image/jpeg','image/png','image/gif')),
 imagen BYTEA NOT NULL CHECK (octet_length(imagen) <= 5242880)
);
ALTER TABLE imagenes_producto ENABLE ROW LEVEL SECURITY;
