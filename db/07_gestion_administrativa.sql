-- Extensiones del panel para Market, Juguetería y Cosméticos.
-- Requiere las migraciones 04–06; no elimina registros existentes.
ALTER TABLE catalogo_solicitudes ADD COLUMN IF NOT EXISTS evidencia_cierre TEXT NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS gestion_cambios (
 id BIGSERIAL PRIMARY KEY,
 tienda_id VARCHAR(30) NOT NULL REFERENCES tiendas(id),
 nombre VARCHAR(150) NOT NULL,
 tipo_cambio VARCHAR(100) NOT NULL,
 responsable VARCHAR(120) NOT NULL,
 riesgo TEXT NOT NULL,
 implementacion TEXT NOT NULL,
 plan_reversion TEXT NOT NULL,
 evidencias_esperadas TEXT NOT NULL,
 fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS pipelines_ci (
 id BIGSERIAL PRIMARY KEY,
 tienda_id VARCHAR(30) NOT NULL REFERENCES tiendas(id),
 nombre VARCHAR(150) NOT NULL,
 repositorio VARCHAR(1000) NOT NULL,
 eventos_disparadores TEXT NOT NULL,
 pruebas_automaticas TEXT NOT NULL,
 herramientas_utilizadas TEXT NOT NULL,
 fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS planes_capacidad (
 id BIGSERIAL PRIMARY KEY,
 tienda_id VARCHAR(30) NOT NULL REFERENCES tiendas(id),
 nombre VARCHAR(150) NOT NULL,
 numero_usuarios INTEGER NOT NULL CHECK (numero_usuarios >= 0),
 recursos_infraestructura TEXT NOT NULL,
 metricas_monitoreo TEXT NOT NULL,
 riesgo_saturacion TEXT NOT NULL,
 estrategia_escalabilidad TEXT NOT NULL,
 herramientas_monitoreo TEXT NOT NULL,
 fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_cambios_tienda_fecha ON gestion_cambios(tienda_id,fecha_actualizacion DESC);
CREATE INDEX IF NOT EXISTS idx_pipelines_tienda_fecha ON pipelines_ci(tienda_id,fecha_actualizacion DESC);
CREATE INDEX IF NOT EXISTS idx_capacidad_tienda_fecha ON planes_capacidad(tienda_id,fecha_actualizacion DESC);
ALTER TABLE gestion_cambios ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipelines_ci ENABLE ROW LEVEL SECURITY;
ALTER TABLE planes_capacidad ENABLE ROW LEVEL SECURITY;
