/* Tienda: selector de cantidad y "Agregar al carrito" sin recargar la página. */
(function () {
  'use strict';

  function limitar(input) {
    var min = parseInt(input.min, 10) || 1;
    var max = parseInt(input.max, 10) || 99;
    var v = parseInt(input.value, 10);
    if (isNaN(v) || v < min) { v = min; }
    if (v > max) { v = max; }
    input.value = v;
    var grupo = input.closest('[role="group"]');
    if (grupo) {
      grupo.querySelector('[data-paso="-1"]').disabled = input.disabled || v <= min;
      grupo.querySelector('[data-paso="1"]').disabled = input.disabled || v >= max;
    }
    return v;
  }

  function actualizarContador(total) {
    document.querySelectorAll('[data-contador-carrito]').forEach(function (c) {
      c.textContent = total;
      c.hidden = total <= 0;
      c.removeAttribute('data-pulso');
      void c.offsetWidth; // reinicia la animación
      c.setAttribute('data-pulso', '');
      var enlace = c.closest('a');
      if (enlace) { enlace.setAttribute('aria-label', 'Carrito, ' + total + (total === 1 ? ' producto' : ' productos')); }
    });
  }

  function estadoBoton(boton, estado, texto) {
    var etiqueta = boton.querySelector('.btn-texto');
    var normal = boton.querySelector('[data-icono="normal"]');
    var exito = boton.querySelector('[data-icono="exito"]');
    boton.removeAttribute('aria-busy');
    boton.removeAttribute('data-estado');
    normal.classList.remove('hidden');
    exito.classList.add('hidden');
    if (estado === 'cargando') {
      boton.setAttribute('aria-busy', 'true');
    } else if (estado === 'exito') {
      boton.setAttribute('data-estado', 'exito');
      normal.classList.add('hidden');
      exito.classList.remove('hidden');
    }
    etiqueta.textContent = texto;
  }

  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('form[data-agregar]').forEach(function (form) {
      var input = form.querySelector('input[name="cantidad"]');
      var boton = form.querySelector('button[type="submit"]');
      var mensaje = form.parentElement.querySelector('[data-mensaje]');
      var temporizador;

      form.querySelectorAll('[data-paso]').forEach(function (b) {
        b.addEventListener('click', function () {
          input.value = (parseInt(input.value, 10) || 1) + parseInt(b.dataset.paso, 10);
          limitar(input);
        });
      });
      input.addEventListener('change', function () { limitar(input); });
      limitar(input);

      form.addEventListener('submit', function (e) {
        e.preventDefault();
        if (boton.disabled || boton.getAttribute('aria-busy')) { return; }
        var cantidad = limitar(input);
        clearTimeout(temporizador);
        estadoBoton(boton, 'cargando', 'Agregando…');
        mensaje.textContent = '';
        mensaje.className = 'mt-2 min-h-4 text-xs';

        fetch(form.action, {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' },
          body: new URLSearchParams({ id: form.elements.id.value, cantidad: cantidad }).toString()
        })
          .then(function (r) { if (!r.ok) { throw new Error(r.status); } return r.json(); })
          .then(function (data) {
            if (data.ok) {
              estadoBoton(boton, 'exito', 'Agregado');
              mensaje.textContent = 'Tienes ' + data.enCarrito + ' en tu carrito.';
              mensaje.classList.add('text-green-800');
              input.value = 1;
              limitar(input);
              actualizarContador(data.totalItems);
              temporizador = setTimeout(function () { estadoBoton(boton, 'normal', 'Agregar'); }, 1800);
            } else {
              estadoBoton(boton, 'normal', 'Agregar');
              mensaje.textContent = data.mensaje;
              mensaje.classList.add('text-red-700');
            }
          })
          .catch(function () {
            estadoBoton(boton, 'normal', 'Agregar');
            window.Toast && window.Toast.mostrar('error', 'No pudimos agregar el producto. Revisa tu conexión e inténtalo de nuevo.');
          });
      });
    });
  });
})();
