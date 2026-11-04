<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%
    String titulo = "Ubicación";
    String destino = "Minimarket %26 Licoreria Anais";
    String coordenadas = "-13.8333986,-76.2476843";
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<body class="min-h-dvh">
<%@ include file="/WEB-INF/jspf/tienda-header.jspf" %>

<main id="contenido" class="contenedor max-w-5xl pt-8">
    <nav aria-label="Ruta de navegación" class="text-sm text-stone-600">
        <ol class="flex items-center gap-1.5">
            <li><a href="<%= ctx %>/jsp-Interfaz/interfaz.jsp" class="hover:text-stone-900 hover:underline">Inicio</a></li>
            <li aria-hidden="true"><ui:icono n="chevron_right" clase="size-4 text-stone-400"/></li>
            <li aria-current="page" class="font-medium text-stone-900">Ubicación</li>
        </ol>
    </nav>

    <div class="mt-4 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
            <h1 class="text-2xl font-semibold tracking-tight text-stone-900">Cómo llegar</h1>
            <p class="mt-1 text-sm text-stone-600">Minimarket &amp; Licorería Anais</p>
        </div>
        <div class="flex flex-wrap gap-2">
            <a class="btn btn-primario" href="https://www.google.com/maps/dir/?api=1&amp;destination=<%= coordenadas %>" target="_blank" rel="noopener">
                <ui:icono n="directions"/>Obtener indicaciones<span class="sr-only"> (Google Maps, se abre en otra pestaña)</span>
            </a>
            <a class="btn btn-secundario" href="https://www.google.com/maps/search/?api=1&amp;query=<%= destino %>" target="_blank" rel="noopener">
                <ui:icono n="open_in_new"/>Abrir en Google Maps<span class="sr-only"> (se abre en otra pestaña)</span>
            </a>
        </div>
    </div>

    <div class="tarjeta relative mt-6 overflow-hidden">
        <div class="absolute inset-0 grid animate-pulse place-items-center bg-stone-100 text-stone-400" aria-hidden="true"><ui:icono n="map" clase="size-10"/></div>
        <iframe class="relative block h-[60vh] min-h-80 w-full border-0"
                title="Mapa con la ubicación de Minimarket & Licorería Anais"
                src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3929.1519319655324!2d-76.2476843!3d-13.8333986!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x911063c05b97c905%3A0x51b09d4a0f70d9a8!2sMinimarket%20%26%20Licoreria%20Anais!5e0!3m2!1ses!2spe!4v1710800000000"
                allowfullscreen loading="lazy" referrerpolicy="no-referrer-when-downgrade"></iframe>
    </div>
    <p class="mt-3 flex items-center gap-1.5 text-xs text-stone-500"><ui:icono n="info" clase="size-4"/>El mapa lo ofrece Google Maps. Si no carga, usa «Abrir en Google Maps».</p>
</main>

<%@ include file="/WEB-INF/jspf/tienda-footer.jspf" %>
<%@ include file="/WEB-INF/jspf/fin.jspf" %>
</body>
</html>
