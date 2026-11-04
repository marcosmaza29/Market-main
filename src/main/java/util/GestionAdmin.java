package util;

import java.sql.*;
import java.util.*;
import javax.servlet.http.HttpServletRequest;

/** Módulos administrativos con columnas permitidas y consultas aisladas por tienda. */
public final class GestionAdmin {
 public static final class Campo {
  public final String columna, etiqueta, ayuda;
  public final boolean multilinea, obligatorio, numero;
  public final int maximo, minimo;
  Campo(String c,String e,String a,boolean multi,boolean requerido,boolean num,int min,int max) {
   columna=c;etiqueta=e;ayuda=a;multilinea=multi;obligatorio=requerido;numero=num;minimo=min;maximo=max;
  }
 }
 private static Campo texto(String c,String e,int max) { return new Campo(c,e,"",false,true,false,0,max); }
 private static Campo largo(String c,String e,String ayuda,boolean requerido) { return new Campo(c,e,ayuda,true,requerido,false,0,10000); }
 private static Campo numero(String c,String e,String ayuda,int min,int max) {return new Campo(c,e,ayuda,false,true,true,min,max);}
 public final String tabla,titulo,seccion,pagina,descripcion;
 public final List<Campo> campos;
 private GestionAdmin(String t,String titulo,String s,String p,String d,Campo... c) {
  tabla=t;this.titulo=titulo;seccion=s;pagina=p;descripcion=d;campos=Collections.unmodifiableList(Arrays.asList(c));
 }
 public static GestionAdmin modulo(String clave) {
  if ("solicitudes".equals(clave)) return new GestionAdmin("catalogo_solicitudes","Catálogo de solicitudes","solicitudes","catalogoSolicitudes.jsp",
   "Define las solicitudes, quién las atiende, el tiempo objetivo y cómo se aprueban y cierran.",
   texto("nombre","Nombre de solicitud",150),texto("tipo","Tipo de solicitud",80),texto("responsable","Responsable",120),
   numero("tiempo_objetivo_horas","Tiempo objetivo de atención (horas)","Entre 1 y 8760 horas.",1,8760),
   largo("flujo_aprobacion","Flujo de aprobación","Indica los pasos y quién aprueba cada uno.",true),
   largo("evidencia_cierre","Evidencia de cierre","Describe el comprobante de cierre o pega su enlace. Puedes completarlo cuando se cierre la solicitud.",false));
  if ("cambios".equals(clave)) return new GestionAdmin("gestion_cambios","Gestión de cambios","cambios","gestionCambios.jsp",
   "Documenta cómo se implementa, verifica y revierte cada cambio de esta tienda.",
   texto("nombre","Nombre del cambio",150),texto("tipo_cambio","Tipo de cambio",100),texto("responsable","Responsable",120),
   largo("riesgo","Riesgo","Describe el impacto y las medidas para reducirlo.",true),
   largo("implementacion","Implementación","Detalla el procedimiento y las condiciones de ejecución.",true),
   largo("plan_reversion","Plan de reversión","Explica cómo restaurar el estado anterior si el cambio falla.",true),
   largo("evidencias_esperadas","Evidencias esperadas","Indica resultados, comprobantes o enlaces que demostrarán que funcionó.",true));
  if ("pipeline".equals(clave)) return new GestionAdmin("pipelines_ci","Pipeline de CI","pipeline","pipelineCI.jsp",
   "Registra el repositorio y las reglas del pipeline de integración continua de esta tienda.",
   texto("nombre","Nombre del pipeline",150),texto("repositorio","Repositorio",1000),
   largo("eventos_disparadores","Eventos que disparan el pipeline","Por ejemplo: push, pull request, ejecución manual o programación.",true),
   largo("pruebas_automaticas","Pruebas automáticas","Describe las pruebas y los comandos de validación.",true),
   largo("herramientas_utilizadas","Herramientas utilizadas","Por ejemplo: GitHub Actions, Maven, JUnit o Docker.",true));
  if ("capacidad".equals(clave)) return new GestionAdmin("planes_capacidad","Plan de capacidad","capacidad","planCapacidad.jsp",
   "Planifica los recursos y el monitoreo necesarios para atender la demanda de esta tienda.",
   texto("nombre","Nombre del plan",150),
   numero("numero_usuarios","Número de usuarios","Indica cuántos usuarios contempla el plan.",0,Integer.MAX_VALUE),
   largo("recursos_infraestructura","Recursos de infraestructura","Detalla CPU, memoria, almacenamiento, base de datos y red.",true),
   largo("metricas_monitoreo","Métricas de monitoreo","Define métricas, umbrales y frecuencia de revisión.",true),
   largo("riesgo_saturacion","Riesgo de saturación","Identifica cuellos de botella y condiciones de saturación.",true),
   largo("estrategia_escalabilidad","Estrategia de escalabilidad","Describe cómo aumentar o reducir la capacidad.",true),
   largo("herramientas_monitoreo","Herramientas de monitoreo","Indica las herramientas y alertas que se utilizarán.",true));
  throw new IllegalArgumentException("Módulo no válido.");
 }
 public Map<String,String> leer(HttpServletRequest req) {
  Map<String,String> valores=new LinkedHashMap<>();
  for(Campo c:campos) {
   String v=req.getParameter(c.columna);valores.put(c.columna,v==null?"":v.trim());
  }
  return valores;
 }
 public void validar(Map<String,String> valores) {
  for(Campo c:campos) {
   String v=valores.get(c.columna);
   if(c.obligatorio && (v==null || v.isEmpty())) throw new IllegalArgumentException("Completa: "+c.etiqueta+".");
   if(c.numero) {
    try { long n=Long.parseLong(v);if(n<c.minimo || n>c.maximo) throw new NumberFormatException(); }
    catch(NumberFormatException e) {throw new IllegalArgumentException(c.etiqueta+": ingresa un entero entre "+c.minimo+" y "+c.maximo+".");}
   } else if(v!=null && v.length()>c.maximo) throw new IllegalArgumentException(c.etiqueta+": máximo "+c.maximo+" caracteres.");
  }
 }
 private void tiendaValida(String tienda) {if(!Tienda.valida(tienda))throw new IllegalArgumentException("Tienda no válida.");}
 public void guardar(Connection con,String tienda,Long id,Map<String,String> valores) throws SQLException {
  tiendaValida(tienda);validar(valores);
  StringJoiner cols=new StringJoiner(","),marcas=new StringJoiner(","),cambios=new StringJoiner(",");
  for(Campo c:campos){cols.add(c.columna);marcas.add("?");cambios.add(c.columna+"=?");}
  String sql=id==null ? "INSERT INTO "+tabla+" ("+cols+",tienda_id) VALUES ("+marcas+",?)"
   : "UPDATE "+tabla+" SET "+cambios+",fecha_actualizacion=CURRENT_TIMESTAMP WHERE tienda_id=? AND id=?";
  try(PreparedStatement ps=con.prepareStatement(sql)) {
   int n=1;for(Campo c:campos){if(c.numero)ps.setInt(n++,Integer.parseInt(valores.get(c.columna)));else ps.setString(n++,valores.get(c.columna));}
   ps.setString(n++,tienda);if(id!=null)ps.setLong(n,id);
   if(ps.executeUpdate()!=1)throw new IllegalArgumentException("No se encontró el registro en esta tienda.");
  }
 }
 public void eliminar(Connection con,String tienda,long id) throws SQLException {
  tiendaValida(tienda);
  try(PreparedStatement ps=con.prepareStatement("DELETE FROM "+tabla+" WHERE tienda_id=? AND id=?")) {
   ps.setString(1,tienda);ps.setLong(2,id);
   if(ps.executeUpdate()!=1)throw new IllegalArgumentException("No se encontró el registro en esta tienda.");
  }
 }
 private Map<String,String> fila(ResultSet rs) throws SQLException {
  Map<String,String> row=new LinkedHashMap<>();row.put("id",rs.getString("id"));
  for(Campo c:campos)row.put(c.columna,rs.getString(c.columna));return row;
 }
 public Map<String,String> obtener(Connection con,String tienda,long id) throws SQLException {
  tiendaValida(tienda);
  try(PreparedStatement ps=con.prepareStatement("SELECT * FROM "+tabla+" WHERE tienda_id=? AND id=?")) {
   ps.setString(1,tienda);ps.setLong(2,id);
   try(ResultSet rs=ps.executeQuery()){return rs.next()?fila(rs):null;}
  }
 }
 public List<Map<String,String>> listar(Connection con,String tienda,String buscar) throws SQLException {
  tiendaValida(tienda);String sql="SELECT * FROM "+tabla+" WHERE tienda_id=?";
  List<Campo> texto=new ArrayList<>();
  if(buscar!=null && !buscar.isEmpty()) {
   StringJoiner filtro=new StringJoiner(" OR ");for(Campo c:campos)if(!c.numero){texto.add(c);filtro.add(c.columna+" ILIKE ?");}
   sql+=" AND ("+filtro+")";
  }
  sql+=" ORDER BY fecha_actualizacion DESC,id DESC";
  List<Map<String,String>> rows=new ArrayList<>();
  try(PreparedStatement ps=con.prepareStatement(sql)) {
   ps.setString(1,tienda);
   String patron=buscar==null?"":"%"+buscar.replace("\\","\\\\").replace("%","\\%").replace("_","\\_")+"%";
   for(int i=0;i<texto.size();i++)ps.setString(i+2,patron);
   try(ResultSet rs=ps.executeQuery()){while(rs.next())rows.add(fila(rs));}
  }
  return rows;
 }
}
