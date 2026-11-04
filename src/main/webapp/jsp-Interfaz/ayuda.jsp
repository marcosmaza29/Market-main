<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%
    String titulo = "Ayuda";
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<body class="min-h-dvh">
<%@ include file="/WEB-INF/jspf/tienda-header.jspf" %>

<main id="contenido" class="contenedor max-w-3xl pt-8">
    <h1 class="text-2xl font-semibold tracking-tight text-stone-900">Ayuda</h1>
    <p class="mt-1 text-sm text-stone-600">Respuestas rápidas sobre compras, tu boleta y tu cuenta.</p>

    <nav aria-label="Temas de ayuda" class="mt-6 flex flex-wrap gap-2">
        <a class="chip" href="#como-comprar"><ui:icono n="shopping_cart" clase="size-4"/>Cómo comprar</a>
        <a class="chip" href="#boleta"><ui:icono n="receipt_long" clase="size-4"/>Tu boleta</a>
        <a class="chip" href="#cuenta"><ui:icono n="person" clase="size-4"/>Cuenta y contraseña</a>
        <a class="chip" href="#stock"><ui:icono n="inventory_2" clase="size-4"/>Stock y agotados</a>
    </nav>

    <section id="como-comprar" class="tarjeta tarjeta-cuerpo mt-6 scroll-mt-24" aria-labelledby="h-comprar">
        <h2 id="h-comprar" class="text-lg font-semibold text-stone-900">Cómo comprar</h2>
        <ol class="mt-4 space-y-4">
            <% String[][] pasos = {
                   {"search", "Encuentra tus productos", "Usa el buscador (atajo: tecla /) o elige una categoría. Puedes ordenar por precio y ocultar los agotados."},
                   {"add_shopping_cart", "Agrégalos al carrito", "Elige la cantidad con − y + y pulsa «Agregar». El contador del carrito se actualiza al momento."},
                   {"shopping_cart", "Revisa tu carrito", "Cambia cantidades o quita productos. Si te equivocas, pulsa «Deshacer» en el aviso que aparece."},
                   {"shopping_bag", "Confirma la compra", "Necesitas iniciar sesión. Te pediremos confirmar el total antes de registrar la compra."}
               };
               for (int i = 0; i < pasos.length; i++) { %>
            <li class="flex gap-4">
                <span class="grid size-9 shrink-0 place-items-center rounded-full bg-marca-50 text-marca-800"><ui:icono n="<%= pasos[i][0] %>" clase="size-5"/></span>
                <div><p class="font-medium text-stone-900"><%= (i + 1) %>. <%= pasos[i][1] %></p><p class="mt-0.5 text-sm text-stone-600"><%= pasos[i][2] %></p></div>
            </li>
            <% } %>
        </ol>
    </section>

    <section id="boleta" class="mt-6 scroll-mt-24 space-y-2" aria-labelledby="h-boleta">
        <h2 id="h-boleta" class="text-lg font-semibold text-stone-900">Tu boleta</h2>
        <details class="group tarjeta">
            <summary class="flex cursor-pointer list-none items-center justify-between gap-4 p-4 font-medium text-stone-900 [&::-webkit-details-marker]:hidden">¿Dónde descargo la boleta?<ui:icono n="expand_more" clase="text-stone-500 transition-transform duration-200 group-open:rotate-180"/></summary>
            <p class="px-4 pb-4 text-sm text-stone-600">Al confirmar tu compra verás el botón «Descargar boleta (PDF)». El PDF se abre en una pestaña nueva para que lo guardes o imprimas.</p>
        </details>
        <details class="group tarjeta">
            <summary class="flex cursor-pointer list-none items-center justify-between gap-4 p-4 font-medium text-stone-900 [&::-webkit-details-marker]:hidden">¿Puedo ver compras anteriores?<ui:icono n="expand_more" clase="text-stone-500 transition-transform duration-200 group-open:rotate-180"/></summary>
            <p class="px-4 pb-4 text-sm text-stone-600">Sí. Abre el menú de tu cuenta y elige «Mis compras». Verás cada compra con su fecha, productos y total.</p>
        </details>
    </section>

    <section id="cuenta" class="mt-6 scroll-mt-24 space-y-2" aria-labelledby="h-cuenta">
        <h2 id="h-cuenta" class="text-lg font-semibold text-stone-900">Cuenta y contraseña</h2>
        <details class="group tarjeta">
            <summary class="flex cursor-pointer list-none items-center justify-between gap-4 p-4 font-medium text-stone-900 [&::-webkit-details-marker]:hidden">Olvidé mi contraseña<ui:icono n="expand_more" clase="text-stone-500 transition-transform duration-200 group-open:rotate-180"/></summary>
            <p class="px-4 pb-4 text-sm text-stone-600">En «Ingresar» pulsa <a class="font-medium text-marca-800 underline" href="<%= ctx %>/jsp-Usuarios/recuperar.jsp">¿Olvidaste tu contraseña?</a> y crea una nueva con tu correo registrado.</p>
        </details>
        <details class="group tarjeta">
            <summary class="flex cursor-pointer list-none items-center justify-between gap-4 p-4 font-medium text-stone-900 [&::-webkit-details-marker]:hidden">¿Qué requisitos tiene la contraseña?<ui:icono n="expand_more" clase="text-stone-500 transition-transform duration-200 group-open:rotate-180"/></summary>
            <p class="px-4 pb-4 text-sm text-stone-600">Al menos 8 caracteres, con una letra y un número. Mientras escribes verás qué requisitos ya cumples.</p>
        </details>
        <details class="group tarjeta">
            <summary class="flex cursor-pointer list-none items-center justify-between gap-4 p-4 font-medium text-stone-900 [&::-webkit-details-marker]:hidden">¿Cómo cambio mis datos?<ui:icono n="expand_more" clase="text-stone-500 transition-transform duration-200 group-open:rotate-180"/></summary>
            <p class="px-4 pb-4 text-sm text-stone-600">En el menú de tu cuenta elige «Mi cuenta». Puedes cambiar nombre, correo y, si quieres, la contraseña.</p>
        </details>
    </section>

    <section id="stock" class="mt-6 scroll-mt-24 space-y-2" aria-labelledby="h-stock">
        <h2 id="h-stock" class="text-lg font-semibold text-stone-900">Stock y agotados</h2>
        <details class="group tarjeta">
            <summary class="flex cursor-pointer list-none items-center justify-between gap-4 p-4 font-medium text-stone-900 [&::-webkit-details-marker]:hidden">¿Qué significa «Quedan N»?<ui:icono n="expand_more" clase="text-stone-500 transition-transform duration-200 group-open:rotate-180"/></summary>
            <p class="px-4 pb-4 text-sm text-stone-600">Que quedan pocas unidades. No puedes agregar más de las disponibles; si alguien compra antes que tú, te avisaremos en el carrito para que ajustes la cantidad.</p>
        </details>
    </section>
</main>

<%@ include file="/WEB-INF/jspf/tienda-footer.jspf" %>
<%@ include file="/WEB-INF/jspf/fin.jspf" %>
</body>
</html>
