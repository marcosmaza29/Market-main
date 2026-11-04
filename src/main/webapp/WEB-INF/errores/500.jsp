<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page isErrorPage="true" %>
<%
    String titulo = "Algo salió mal";
    response.setStatus(500);
    if (exception != null) {
        application.log("Error no controlado en " + request.getAttribute("javax.servlet.error.request_uri"), exception);
    }
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<body class="grid min-h-dvh place-items-center px-4">
<main class="max-w-md text-center motion-safe:animate-aparecer">
    <span class="mx-auto grid size-14 place-items-center rounded-full bg-red-50 text-red-700"><ui:icono n="error" clase="size-7"/></span>
    <p class="mt-6 text-sm font-medium text-red-700">Error del servidor</p>
    <h1 class="mt-1 text-2xl font-semibold tracking-tight text-stone-900">Algo salió mal de nuestro lado</h1>
    <p class="mt-2 text-sm leading-relaxed text-stone-600">No es tu culpa y no se perdió nada de tu carrito. Vuelve a intentarlo en unos segundos; si se repite, regresa a la tienda.</p>
    <div class="mt-6 flex flex-col justify-center gap-2 sm:flex-row">
        <a href="javascript:location.reload()" class="btn btn-primario"><ui:icono n="restart_alt"/>Reintentar</a>
        <a href="<%= ctx %>/jsp-Interfaz/interfaz.jsp" class="btn btn-secundario"><ui:icono n="storefront"/>Ir a la tienda</a>
    </div>
</main>
</body>
</html>
