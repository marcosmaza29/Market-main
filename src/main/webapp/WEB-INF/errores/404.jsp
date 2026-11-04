<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%@ page isErrorPage="true" %>
<%
    String titulo = "Página no encontrada";
    response.setStatus(404);
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<body class="grid min-h-dvh place-items-center px-4">
<main class="max-w-md text-center motion-safe:animate-aparecer">
    <span class="mx-auto grid size-14 place-items-center rounded-full bg-stone-100 text-stone-500"><ui:icono n="search_off" clase="size-7"/></span>
    <p class="mt-6 text-sm font-medium text-marca-800">Error 404</p>
    <h1 class="mt-1 text-2xl font-semibold tracking-tight text-stone-900">No encontramos esta página</h1>
    <p class="mt-2 text-sm leading-relaxed text-stone-600">Puede que el enlace esté mal escrito o que la página ya no exista.</p>
    <div class="mt-6 flex flex-col justify-center gap-2 sm:flex-row">
        <a href="<%= ctx %>/jsp-Interfaz/interfaz.jsp" class="btn btn-primario"><ui:icono n="storefront"/>Ir a la tienda</a>
        <a href="javascript:history.back()" class="btn btn-secundario"><ui:icono n="arrow_back"/>Volver atrás</a>
    </div>
</main>
</body>
</html>
