<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page import="util.Html,util.Tienda" %>
<%
 String tiendaId = (String) session.getAttribute("adminTiendaId");
 if(!Boolean.TRUE.equals(session.getAttribute("adminLogueado")) || !Tienda.valida(tiendaId)
    || !tiendaId.equals(contextoTienda)) { response.sendError(403); return; }
 String titulo = "Gestor de rendimiento";
 String seccion = "capacidad";
%>
<!DOCTYPE html><html lang="es"><head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
<div class="flex flex-wrap items-center justify-between gap-3">
 <div><h1 class="text-2xl font-semibold">Gestor de rendimiento</h1><p class="mt-2 text-sm text-stone-600">Monitoreo automático de solicitudes, errores y recursos de la aplicación.</p></div>
 <span class="etiqueta"><%= Html.esc(Tienda.nombre(tiendaId)) %></span>
</div>
<div class="tarjeta mt-5 p-4 text-sm"><strong id="estado-monitor" role="status">Conectando al monitor...</strong><p class="mt-2 text-stone-600">Actualización cada 5 segundos. Las solicitudes pertenecen a esta tienda; RAM, CPU y disco pertenecen al servidor compartido por todas las tiendas.</p></div>
<section class="mt-6" aria-label="Actividad de esta tienda">
 <h2 class="text-lg font-semibold">Actividad de <%= Html.esc(Tienda.nombre(tiendaId)) %></h2>
 <div class="mt-3 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
  <div class="tarjeta p-5"><p class="text-sm text-stone-600">Solicitudes registradas</p><p id="m-total" class="mt-2 text-2xl font-semibold">—</p></div>
  <div class="tarjeta p-5"><p class="text-sm text-stone-600">Últimos 5 minutos</p><p id="m-cinco" class="mt-2 text-2xl font-semibold">—</p></div>
  <div class="tarjeta p-5"><p class="text-sm text-stone-600">Tiempo medio de respuesta</p><p id="m-latencia" class="mt-2 text-2xl font-semibold">—</p></div>
  <div class="tarjeta p-5"><p class="text-sm text-stone-600">Errores del servidor (HTTP 5xx)</p><p id="m-errores" class="mt-2 text-2xl font-semibold">—</p></div>
 </div>
 <div class="tarjeta mt-4 p-5"><div class="flex items-center justify-between"><h3 class="font-semibold">Solicitudes en los últimos 5 minutos</h3><span class="text-xs text-stone-600">Evolución de esta sesión de monitoreo</span></div>
 <canvas id="trafico" height="145" style="width:100%;height:145px" role="img" aria-label="Gráfico de solicitudes por minuto"></canvas></div>
</section>
<section class="mt-7" aria-label="Recursos del servidor compartido">
 <h2 class="text-lg font-semibold">Recursos del servidor (compartidos)</h2>
 <div class="mt-3 grid gap-4 md:grid-cols-3">
  <div class="tarjeta p-5"><h3 class="font-semibold">Memoria RAM de Java (heap)</h3><p id="m-ram" class="mt-2 text-xl font-semibold">—</p><div class="mt-3 h-3 overflow-hidden rounded-full bg-stone-200"><div id="bar-ram" class="h-full bg-emerald-600" style="width:0%"></div></div><p class="mt-2 text-xs text-stone-600">Memoria heap usada / máximo asignable a la JVM; no es toda la RAM física.</p></div>
  <div class="tarjeta p-5"><h3 class="font-semibold">CPU del proceso Java</h3><p id="m-cpu" class="mt-2 text-xl font-semibold">—</p><div class="mt-3 h-3 overflow-hidden rounded-full bg-stone-200"><div id="bar-cpu" class="h-full bg-blue-600" style="width:0%"></div></div><p class="mt-2 text-xs text-stone-600">Carga aproximada del proceso JVM, no de una tienda individual.</p></div>
  <div class="tarjeta p-5"><h3 class="font-semibold">Disco del contenedor</h3><p id="m-disco" class="mt-2 text-xl font-semibold">—</p><div class="mt-3 h-3 overflow-hidden rounded-full bg-stone-200"><div id="bar-disco" class="h-full bg-amber-600" style="width:0%"></div></div><p class="mt-2 text-xs text-stone-600">Espacio del sistema de archivos de Tomcat, compartido; no mide la base Supabase.</p></div>
 </div>
</section>
<div class="tarjeta mt-7 p-5"><h2 class="font-semibold">Historial y Grafana</h2><p class="mt-2 text-sm text-stone-600">Este panel muestra valores en vivo. Para conservar históricos, consultar tendencias y configurar alertas, inicia los servicios opcionales Prometheus y Grafana del proyecto. El dashboard de Grafana permite filtrar por tienda.</p></div>
<script>
(function(){
 const tienda=<%= "\"" + tiendaId + "\"" %>;
 const endpoint=<%= "\"" + ctx + "/monitor/estado?tienda=" + tiendaId + "\"" %>;
 const $=id=>document.getElementById(id);
 const num=v=>new Intl.NumberFormat('es-PE').format(v);
 const bytes=v=>(v/1048576).toFixed(1)+' MiB';
 const pct=(v,max)=>max>0?Math.min(100,Math.max(0,100*v/max)):0;
 const hist=[];
 function dibujar(){const c=$('trafico'),dpr=window.devicePixelRatio||1,w=c.clientWidth||600,h=145;c.width=w*dpr;c.height=h*dpr;const x=c.getContext('2d');x.scale(dpr,dpr);x.clearRect(0,0,w,h);x.strokeStyle='#d6d3d1';x.beginPath();x.moveTo(10,h-22);x.lineTo(w-10,h-22);x.stroke();if(!hist.length)return;const max=Math.max(1,...hist.map(a=>a.v));x.strokeStyle='#047857';x.lineWidth=2.5;x.beginPath();hist.forEach((a,i)=>{const px=12+i*(w-24)/Math.max(1,hist.length-1),py=10+(h-42)*(1-a.v/max);i?x.lineTo(px,py):x.moveTo(px,py)});x.stroke();x.fillStyle='#57534e';x.font='11px sans-serif';x.fillText('Máx. '+max+' solicitudes/5 min',12,12);}
 async function actualizar(){try{const r=await fetch(endpoint,{credentials:'same-origin',cache:'no-store'});if(!r.ok)throw Error('HTTP '+r.status);const d=await r.json();$('estado-monitor').textContent='● Monitor activo · Actualizado '+new Date(d.timestamp).toLocaleTimeString('es-PE');$('m-total').textContent=num(d.solicitudes);$('m-cinco').textContent=num(d.ultimos5min);$('m-latencia').textContent=num(d.promedioMs)+' ms';$('m-errores').textContent=num(d.errores);$('m-ram').textContent=bytes(d.heapUsado)+' / '+bytes(d.heapMaximo);$('bar-ram').style.width=pct(d.heapUsado,d.heapMaximo)+'%';$('m-cpu').textContent=d.cpuProceso>=0?d.cpuProceso.toFixed(1)+' %':'No disponible';$('bar-cpu').style.width=(d.cpuProceso>=0?Math.min(100,d.cpuProceso):0)+'%';$('m-disco').textContent=bytes(d.discoUsado)+' / '+bytes(d.discoTotal);$('bar-disco').style.width=pct(d.discoUsado,d.discoTotal)+'%';const t=Math.floor(d.timestamp/60000);if(!hist.length||hist[hist.length-1].t!==t)hist.push({t,v:0});hist[hist.length-1].v=d.ultimos5min;while(hist.length>30)hist.shift();dibujar();}catch(e){$('estado-monitor').textContent='No se pudieron obtener métricas. Comprueba tu sesión o el servidor.';}}
 actualizar();setInterval(()=>{if(!document.hidden)actualizar()},5000);window.addEventListener('resize',dibujar);
})();
</script>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %></html>
