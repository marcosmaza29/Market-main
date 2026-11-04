<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%
    String titulo = "Ayuda del panel";
    String seccion = "ayuda";
    String[][] temas = {
        {"inventory_2", "Productos", "Agregar un producto",
         "En «Productos» pulsa «Nuevo producto». La imagen es la ruta del archivo en el bucket «images» de Supabase (por ejemplo bebidas/inka-kola-500.png); verás una vista previa al escribirla."},
        {"inventory_2", "Productos", "Dejar de vender un producto",
         "Edítalo y pon su stock en 0: se mostrará como «Agotado» y no se podrá comprar. Eliminar solo es posible si no tiene compras registradas, y no se puede deshacer."},
        {"warning", "Productos", "Revisar el stock bajo",
         "Las tarjetas de resumen filtran la tabla: «Con poco stock» muestra los productos con 1 a 5 unidades y «Agotados» los que están en 0."},
        {"add_business", "Compras", "Registrar mercadería recibida",
         "En «Registrar compra» elige proveedor, producto, cantidad y precio unitario. El stock se suma al guardar y la compra queda en el historial del proveedor."},
        {"local_shipping", "Proveedores", "Desactivar o reactivar un proveedor",
         "Desactivar oculta al proveedor al registrar compras, pero conserva su historial. Puedes deshacerlo desde el aviso o reactivarlo en la pestaña «Desactivados»."},
        {"point_of_sale", "Reportes", "Consultar y exportar ventas",
         "En «Ventas» elige el periodo (hoy, semana, mes o un rango de fechas) y, si quieres, busca un cliente. «Exportar CSV» descarga todas las filas para abrirlas en Excel."},
        {"history", "Reportes", "Saber quién cambió qué",
         "«Actividad» registra automáticamente cada alta, cambio y baja de productos con fecha y detalle de los campos modificados."},
    };
%>
<!DOCTYPE html>
<html lang="es">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %></head>
<%@ include file="/WEB-INF/jspf/admin-inicio.jspf" %>
    <h1 class="text-2xl font-semibold tracking-tight text-stone-900">Ayuda del panel</h1>
    <p class="mt-1 text-sm text-stone-600">Guía rápida de las tareas más comunes.</p>

    <div class="mt-6 grid gap-6 lg:grid-cols-[minmax(0,1fr)_18rem]">
        <div class="space-y-2">
            <% for (int i = 0; i < temas.length; i++) { %>
            <details class="group tarjeta" <%= i == 0 ? "open" : "" %>>
                <summary class="flex cursor-pointer list-none items-center gap-3 p-4 [&::-webkit-details-marker]:hidden">
                    <span class="grid size-9 shrink-0 place-items-center rounded-lg bg-stone-100 text-stone-600"><ui:icono n="<%= temas[i][0] %>" clase="size-4"/></span>
                    <span class="min-w-0 flex-1"><span class="block text-xs text-stone-500"><%= temas[i][1] %></span><span class="block font-medium text-stone-900"><%= temas[i][2] %></span></span>
                    <ui:icono n="expand_more" clase="text-stone-500 transition-transform duration-200 group-open:rotate-180"/>
                </summary>
                <p class="px-4 pb-4 pl-16 text-sm leading-relaxed text-stone-600"><%= temas[i][3] %></p>
            </details>
            <% } %>
        </div>
        <aside class="tarjeta tarjeta-cuerpo h-fit text-sm">
            <h2 class="font-semibold text-stone-900">Atajos</h2>
            <dl class="mt-3 space-y-2 text-stone-600">
                <div class="flex items-center justify-between gap-3"><dt>Ir al buscador de la página</dt><dd><kbd class="tecla">/</kbd></dd></div>
                <div class="flex items-center justify-between gap-3"><dt>Cerrar diálogos y menús</dt><dd><kbd class="tecla">Esc</kbd></dd></div>
            </dl>
            <h2 class="mt-6 font-semibold text-stone-900">Antes de confirmar</h2>
            <p class="mt-2 text-stone-600">Las acciones que no se pueden deshacer (eliminar un producto, desactivar un proveedor) siempre piden confirmación. Si cierras una página con cambios sin guardar, te avisaremos.</p>
        </aside>
    </div>
<%@ include file="/WEB-INF/jspf/admin-fin.jspf" %>
</html>
