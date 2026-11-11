-- Migración 09 - Gestión de incidentes por tienda (PostgreSQL/Supabase).
-- Ejecutar después de 04_multitienda.sql. No elimina tablas ni registros existentes.
CREATE TABLE IF NOT EXISTS public.incidentes (
  id BIGSERIAL PRIMARY KEY,
  tienda_id VARCHAR(30) NOT NULL REFERENCES public.tiendas(id),
  titulo VARCHAR(160) NOT NULL,
  descripcion TEXT NOT NULL,
  categoria VARCHAR(30) NOT NULL CHECK (categoria IN ('aplicacion','rendimiento','base_datos','seguridad','red','otros')),
  prioridad VARCHAR(2) NOT NULL CHECK (prioridad IN ('P1','P2','P3','P4')),
  estado VARCHAR(25) NOT NULL DEFAULT 'registrado'
    CHECK (estado IN ('registrado','asignado','en_proceso','escalado','resuelto','cerrado')),
  reportado_por VARCHAR(120) NOT NULL,
  responsable VARCHAR(120) NOT NULL DEFAULT '',
  nivel_escalamiento INTEGER NOT NULL DEFAULT 0 CHECK(nivel_escalamiento BETWEEN 0 AND 5),
  herramientas VARCHAR(300) NOT NULL DEFAULT 'Market, Prometheus, Grafana',
  respuesta_horas INTEGER NOT NULL CHECK(respuesta_horas > 0),
  solucion_horas INTEGER NOT NULL CHECK(solucion_horas > 0),
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  limite_respuesta TIMESTAMPTZ NOT NULL,
  limite_solucion TIMESTAMPTZ NOT NULL,
  primera_respuesta_en TIMESTAMPTZ,
  resuelto_en TIMESTAMPTZ,
  cerrado_en TIMESTAMPTZ,
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_incidentes_tienda_estado ON public.incidentes (tienda_id,estado,creado_en DESC);
CREATE INDEX IF NOT EXISTS idx_incidentes_tienda_sla ON public.incidentes (tienda_id,limite_solucion);
CREATE TABLE IF NOT EXISTS public.incidentes_historial (
  id BIGSERIAL PRIMARY KEY,
  incidente_id BIGINT NOT NULL REFERENCES public.incidentes(id),
  tienda_id VARCHAR(30) NOT NULL REFERENCES public.tiendas(id),
  accion VARCHAR(30) NOT NULL CHECK(accion IN ('registro','actualizacion','escalamiento')),
  actor VARCHAR(120) NOT NULL,
  estado_anterior VARCHAR(25),
  estado_nuevo VARCHAR(25) NOT NULL,
  responsable VARCHAR(120) NOT NULL DEFAULT '',
  comentario VARCHAR(2000) NOT NULL DEFAULT '',
  creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_incidentes_historial_incidente ON public.incidentes_historial (incidente_id,creado_en DESC);
ALTER TABLE public.incidentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidentes_historial ENABLE ROW LEVEL SECURITY;
-- La aplicación emplea JDBC con permisos del rol PostgreSQL y autorización por sesión.
-- RLS no reemplaza el filtrado por tienda; no se crean políticas públicas.
