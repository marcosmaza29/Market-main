/*
 * Comportamiento compartido de la interfaz (mejora progresiva: todo funciona sin JS,
 * esto añade estados, validación en línea, confirmaciones y atajos).
 */
(function () {
  'use strict';

  var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function $(sel, ctx) { return (ctx || document).querySelector(sel); }
  function $$(sel, ctx) { return Array.prototype.slice.call((ctx || document).querySelectorAll(sel)); }
  function plantilla(id) {
    var t = document.getElementById(id);
    return t ? t.content.firstElementChild.cloneNode(true) : null;
  }

  /* ------------------------------------------------------------------
   * Notificaciones (toasts)
   * ------------------------------------------------------------------ */
  var Toast = {
    contenedor: null,

    init: function () {
      this.contenedor = document.getElementById('toasts');
      if (!this.contenedor) { return; }
      $$('.toast', this.contenedor).forEach(this.activar, this);
    },

    mostrar: function (tipo, texto, opciones) {
      if (!this.contenedor) { return; }
      var t = plantilla('tpl-toast-' + tipo) || plantilla('tpl-toast-info');
      if (!t) { return; }
      $('.toast-texto', t).textContent = texto;
      if (opciones && opciones.accion) {
        var b = document.createElement('button');
        b.type = 'button';
        b.className = 'toast-accion';
        b.textContent = opciones.accion.texto;
        b.addEventListener('click', function () { opciones.accion.alHacer(); Toast.cerrar(t); });
        $('.toast-texto', t).after(b);
      }
      this.contenedor.appendChild(t);
      this.activar(t);
    },

    activar: function (t) {
      var self = this;
      var cerrar = $('.toast-cerrar', t);
      if (cerrar) { cerrar.addEventListener('click', function () { self.cerrar(t); }); }
      // Los errores se quedan hasta que el usuario los cierra: hay que poder leerlos.
      if (t.classList.contains('toast-error')) { return; }
      var restante = 6000, inicio, temporizador;
      function correr() { inicio = Date.now(); temporizador = setTimeout(function () { self.cerrar(t); }, restante); }
      function pausar() { clearTimeout(temporizador); restante -= Date.now() - inicio; }
      t.addEventListener('mouseenter', pausar);
      t.addEventListener('focusin', pausar);
      t.addEventListener('mouseleave', correr);
      t.addEventListener('focusout', correr);
      correr();
    },

    cerrar: function (t) {
      if (t.hasAttribute('data-saliendo')) { return; }
      t.setAttribute('data-saliendo', '');
      var quitar = function () { t.remove(); };
      if (reduceMotion) { quitar(); } else { t.addEventListener('transitionend', quitar, { once: true }); setTimeout(quitar, 400); }
    }
  };
  window.Toast = Toast;

  /* ------------------------------------------------------------------
   * Confirmación de acciones destructivas o irreversibles
   *   <form data-confirmar="Texto" data-confirmar-titulo="..." data-confirmar-boton="Eliminar" data-confirmar-tono="peligro">
   * ------------------------------------------------------------------ */
  function initConfirmaciones() {
    var dlg = document.getElementById('dlg-confirmar');
    if (!dlg || typeof dlg.showModal !== 'function') {
      // Navegadores sin <dialog>: confirm() nativo
      document.addEventListener('submit', function (e) {
        var f = e.target;
        if (f.matches('form[data-confirmar]') && !window.confirm(f.dataset.confirmar)) { e.preventDefault(); e.stopImmediatePropagation(); }
      });
      return;
    }

    var formPendiente = null, submitterPendiente = null;
    var titulo = $('[data-dlg-titulo]', dlg), texto = $('[data-dlg-texto]', dlg), ok = $('[data-dlg-ok]', dlg);

    document.addEventListener('submit', function (e) {
      var f = e.target;
      if (!f.matches('form[data-confirmar]') || f.dataset.confirmado === '1') { return; }
      e.preventDefault();
      e.stopImmediatePropagation();
      formPendiente = f;
      submitterPendiente = e.submitter || null;
      titulo.textContent = f.dataset.confirmarTitulo || '¿Confirmas esta acción?';
      texto.textContent = f.dataset.confirmar;
      $('[data-dlg-ok-texto]', ok).textContent = f.dataset.confirmarBoton || 'Confirmar';
      ok.className = 'btn ' + (f.dataset.confirmarTono === 'peligro' ? 'btn-peligro' : 'btn-primario');
      dlg.showModal();
      // El foco va a "Cancelar": la opción segura es la predeterminada.
      $('[data-dlg-cancelar]', dlg).focus();
    });

    dlg.addEventListener('close', function () {
      if (dlg.returnValue === 'ok' && formPendiente) {
        formPendiente.dataset.confirmado = '1';
        if (formPendiente.requestSubmit) { formPendiente.requestSubmit(submitterPendiente || undefined); }
        else { formPendiente.submit(); }
      }
      formPendiente = null;
      dlg.returnValue = '';
    });
    // Clic en el fondo = cancelar
    dlg.addEventListener('click', function (e) { if (e.target === dlg) { dlg.close('cancelar'); } });
  }

  /* ------------------------------------------------------------------
   * Estado de carga en botones de envío (evita dobles envíos)
   * ------------------------------------------------------------------ */
  function initEnvios() {
    document.addEventListener('submit', function (e) {
      if (e.defaultPrevented) { return; }
      var f = e.target;
      var b = e.submitter || $('button[type=submit]', f);
      if (!b || b.hasAttribute('data-sin-carga')) { return; }
      // El botón deshabilitado no viaja en el formulario: se copia su name/value.
      if (b.name) {
        var oculto = document.createElement('input');
        oculto.type = 'hidden'; oculto.name = b.name; oculto.value = b.value;
        f.appendChild(oculto);
      }
      b.setAttribute('aria-busy', 'true');
      var etiqueta = $('.btn-texto', b);
      if (etiqueta && b.dataset.cargando) { etiqueta.dataset.original = etiqueta.textContent; etiqueta.textContent = b.dataset.cargando; }
      setTimeout(function () { b.disabled = true; }, 0);
    });
    // Al volver con el botón "Atrás" (bfcache) los botones deben quedar utilizables.
    window.addEventListener('pageshow', function (e) {
      if (!e.persisted) { return; }
      $$('button[aria-busy="true"]').forEach(function (b) {
        b.removeAttribute('aria-busy'); b.disabled = false;
        var etiqueta = $('.btn-texto', b);
        if (etiqueta && etiqueta.dataset.original) { etiqueta.textContent = etiqueta.dataset.original; }
      });
      $$('form[data-confirmado]').forEach(function (f) { delete f.dataset.confirmado; });
    });
  }

  /* ------------------------------------------------------------------
   * Validación en línea con mensajes claros en español
   * ------------------------------------------------------------------ */
  function mensajeDe(input) {
    var v = input.validity, d = input.dataset;
    if (v.valueMissing) { return d.msgRequerido || 'Este campo es obligatorio.'; }
    if (v.typeMismatch && input.type === 'email') { return d.msgFormato || 'Escribe un correo válido, por ejemplo nombre@correo.com.'; }
    if (v.patternMismatch) { return d.msgFormato || 'El formato no es válido.'; }
    if (v.tooShort) { return 'Debe tener al menos ' + input.minLength + ' caracteres (tiene ' + input.value.length + ').'; }
    if (v.rangeUnderflow) { return d.msgMinimo || 'El valor mínimo es ' + input.min + '.'; }
    if (v.rangeOverflow) { return d.msgMaximo || 'El valor máximo es ' + input.max + '.'; }
    if (v.stepMismatch) { return 'Usa como máximo dos decimales.'; }
    if (v.badInput) { return 'Escribe un número válido.'; }
    if (v.customError) { return input.validationMessage; }
    return '';
  }

  function pintarError(input, mensaje) {
    var campo = input.closest('.campo');
    var id = input.id + '-error';
    var nodo = document.getElementById(id);
    if (mensaje) {
      input.setAttribute('aria-invalid', 'true');
      if (!nodo && campo) {
        nodo = plantilla('tpl-error-campo');
        if (!nodo) { return; }
        nodo.id = id;
        campo.appendChild(nodo);
      }
      if (nodo) { $('.error-campo-texto', nodo).textContent = mensaje; }
      var desc = (input.getAttribute('aria-describedby') || '').split(' ').filter(Boolean);
      if (desc.indexOf(id) === -1) { desc.push(id); input.setAttribute('aria-describedby', desc.join(' ')); }
    } else {
      input.removeAttribute('aria-invalid');
      if (nodo) { nodo.remove(); }
    }
  }

  function validarCampo(input) {
    if (input.dataset.coincideCon) {
      var otro = document.getElementById(input.dataset.coincideCon);
      input.setCustomValidity(otro && input.value && otro.value !== input.value ? 'Las contraseñas no coinciden.' : '');
    }
    var msg = input.checkValidity() ? '' : mensajeDe(input);
    pintarError(input, msg);
    return !msg;
  }

  function initValidacion() {
    $$('form[data-validar]').forEach(function (f) {
      f.noValidate = true;
      var campos = $$('input, select, textarea', f).filter(function (i) { return i.willValidate; });
      campos.forEach(function (i) {
        // No se marca como error mientras se escribe por primera vez: solo al salir del campo.
        i.addEventListener('blur', function () { if (i.value || i.dataset.tocado) { i.dataset.tocado = '1'; validarCampo(i); } });
        i.addEventListener('input', function () { if (i.dataset.tocado || i.getAttribute('aria-invalid')) { validarCampo(i); } });
      });
      f.addEventListener('submit', function (e) {
        var primero = null;
        campos.forEach(function (i) { i.dataset.tocado = '1'; if (!validarCampo(i) && !primero) { primero = i; } });
        if (primero) {
          e.preventDefault();
          e.stopImmediatePropagation();
          primero.focus();
          var campo = primero.closest('.campo');
          if (campo && !reduceMotion) {
            campo.setAttribute('data-sacudir', '');
            setTimeout(function () { campo.removeAttribute('data-sacudir'); }, 350);
          }
        }
      }, true);
    });
  }

  /* ------------------------------------------------------------------
   * Requisitos de contraseña visibles mientras se escribe
   * ------------------------------------------------------------------ */
  function initReglasContrasena() {
    $$('[data-reglas-de]').forEach(function (lista) {
      var input = document.getElementById(lista.dataset.reglasDe);
      if (!input) { return; }
      var reglas = {
        largo: function (v) { return v.length >= 8; },
        letra: function (v) { return /[A-Za-z]/.test(v); },
        numero: function (v) { return /[0-9]/.test(v); }
      };
      function actualizar() {
        $$('[data-regla]', lista).forEach(function (li) {
          var ok = reglas[li.dataset.regla](input.value);
          li.toggleAttribute('data-cumple', ok);
          $$('[data-estado]', li).forEach(function (ic) { ic.classList.toggle('hidden', ic.dataset.estado !== (ok ? 'si' : 'no')); });
        });
      }
      input.addEventListener('input', actualizar);
      actualizar();
    });
  }

  /* ------------------------------------------------------------------
   * Mostrar / ocultar contraseña
   * ------------------------------------------------------------------ */
  function initVerContrasena() {
    $$('[data-ver-contrasena]').forEach(function (b) {
      var input = document.getElementById(b.dataset.verContrasena);
      if (!input) { return; }
      b.hidden = false;
      b.addEventListener('click', function () {
        var visible = input.type === 'password';
        input.type = visible ? 'text' : 'password';
        b.setAttribute('aria-pressed', String(visible));
        b.setAttribute('aria-label', visible ? 'Ocultar contraseña' : 'Mostrar contraseña');
        $('[data-icono="ver"]', b).classList.toggle('hidden', visible);
        $('[data-icono="ocultar"]', b).classList.toggle('hidden', !visible);
      });
    });
  }

  /* ------------------------------------------------------------------
   * Menús desplegables accesibles
   * ------------------------------------------------------------------ */
  function initMenus() {
    $$('[data-menu]').forEach(function (b) {
      var menu = document.getElementById(b.getAttribute('aria-controls'));
      if (!menu) { return; }
      var items = function () { return $$('[role="menuitem"]', menu); };
      function abrir(enfocar) {
        menu.setAttribute('data-abierto', '');
        b.setAttribute('aria-expanded', 'true');
        if (enfocar) { var i = items()[0]; if (i) { i.focus(); } }
      }
      function cerrar(devolverFoco) {
        menu.removeAttribute('data-abierto');
        b.setAttribute('aria-expanded', 'false');
        if (devolverFoco) { b.focus(); }
      }
      b.addEventListener('click', function () { if (menu.hasAttribute('data-abierto')) { cerrar(); } else { abrir(false); } });
      b.addEventListener('keydown', function (e) { if (e.key === 'ArrowDown') { e.preventDefault(); abrir(true); } });
      menu.addEventListener('keydown', function (e) {
        var lista = items(), idx = lista.indexOf(document.activeElement);
        if (e.key === 'Escape') { e.preventDefault(); cerrar(true); }
        else if (e.key === 'ArrowDown') { e.preventDefault(); lista[(idx + 1) % lista.length].focus(); }
        else if (e.key === 'ArrowUp') { e.preventDefault(); lista[(idx - 1 + lista.length) % lista.length].focus(); }
        else if (e.key === 'Tab') { cerrar(); }
      });
      document.addEventListener('click', function (e) { if (!menu.contains(e.target) && !b.contains(e.target)) { cerrar(); } });
    });
  }

  /* ------------------------------------------------------------------
   * Cajones laterales (menú móvil) con <dialog>
   * ------------------------------------------------------------------ */
  function initCajones() {
    $$('[data-abrir-cajon]').forEach(function (b) {
      var dlg = document.getElementById(b.dataset.abrirCajon);
      if (!dlg || typeof dlg.showModal !== 'function') { return; }
      b.addEventListener('click', function () { dlg.showModal(); b.setAttribute('aria-expanded', 'true'); });
      dlg.addEventListener('close', function () { b.setAttribute('aria-expanded', 'false'); });
      dlg.addEventListener('click', function (e) { if (e.target === dlg) { dlg.close(); } });
    });
    $$('[data-cerrar-dialogo]').forEach(function (b) {
      b.addEventListener('click', function () { var d = b.closest('dialog'); if (d) { d.close(); } });
    });
    $$('[data-abrir-dialogo]').forEach(function (b) {
      var dlg = document.getElementById(b.dataset.abrirDialogo);
      if (!dlg || typeof dlg.showModal !== 'function') { return; }
      b.addEventListener('click', function (e) { e.preventDefault(); dlg.showModal(); });
      dlg.addEventListener('click', function (e) { if (e.target === dlg) { dlg.close(); } });
    });
    // Un diálogo marcado como abierto desde el servidor (p. ej. tras un error) se abre al cargar.
    $$('dialog[data-abrir-al-cargar]').forEach(function (d) { if (d.showModal) { d.showModal(); } });
  }

  /* ------------------------------------------------------------------
   * Atajo "/" para buscar
   * ------------------------------------------------------------------ */
  function initAtajos() {
    document.addEventListener('keydown', function (e) {
      if (e.key !== '/' || e.ctrlKey || e.metaKey || e.altKey) { return; }
      var t = e.target;
      if (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName)) { return; }
      var buscador = $('[data-atajo-buscar]');
      if (buscador && buscador.offsetParent !== null) { e.preventDefault(); buscador.focus(); buscador.select(); }
    });
  }

  /* ------------------------------------------------------------------
   * Imágenes: aparición suave y alternativa si fallan
   * ------------------------------------------------------------------ */
  function initImagenes() {
    $$('img.img-progresiva').forEach(function (img) {
      var marco = img.closest('.marco-img');
      function listo() { img.setAttribute('data-cargada', ''); if (marco) { marco.removeAttribute('data-cargando'); } }
      function fallo() {
        if (marco) {
          marco.removeAttribute('data-cargando');
          var alt = plantilla('tpl-sin-imagen');
          if (alt) { img.replaceWith(alt); }
        }
      }
      if (img.complete && img.naturalWidth) { listo(); }
      else if (img.complete) { fallo(); }
      else { img.addEventListener('load', listo, { once: true }); img.addEventListener('error', fallo, { once: true }); }
    });
  }

  /* ------------------------------------------------------------------
   * Carrusel (scroll-snap) con controles, indicadores y pausa
   * ------------------------------------------------------------------ */
  function initCarruseles() {
    $$('[data-carrusel]').forEach(function (c) {
      var pista = $('.carrusel-pista', c);
      var diapositivas = $$('.carrusel-pista > *', c);
      var puntos = $$('[data-ir-a]', c);
      var pausa = $('[data-pausa]', c);
      var actual = 0, timer = null, pausado = reduceMotion;

      function alFinal() { return pista.scrollLeft + pista.clientWidth >= pista.scrollWidth - 4; }
      function ir(i) {
        // Al llegar al final (varias promociones visibles a la vez) se vuelve a la primera
        if (i >= diapositivas.length || (i > actual && alFinal())) { i = 0; }
        actual = (i + diapositivas.length) % diapositivas.length;
        pista.scrollTo({ left: diapositivas[actual].offsetLeft - diapositivas[0].offsetLeft, behavior: reduceMotion ? 'auto' : 'smooth' });
        marcar(actual);
      }
      function marcar(i) {
        actual = i;
        puntos.forEach(function (p, j) { p.setAttribute('aria-current', String(j === i)); });
      }
      function programar() { clearInterval(timer); if (!pausado) { timer = setInterval(function () { ir(actual + 1); }, 6000); } }

      // Al deslizar con el dedo, el indicador sigue a la primera promoción visible
      var tScroll;
      pista.addEventListener('scroll', function () {
        clearTimeout(tScroll);
        tScroll = setTimeout(function () {
          var x = pista.scrollLeft + diapositivas[0].offsetLeft, mejor = 0;
          diapositivas.forEach(function (d, j) { if (Math.abs(d.offsetLeft - x) < Math.abs(diapositivas[mejor].offsetLeft - x)) { mejor = j; } });
          marcar(mejor);
        }, 80);
      }, { passive: true });
      $$('[data-anterior]', c).forEach(function (b) { b.addEventListener('click', function () { ir(actual - 1); programar(); }); });
      $$('[data-siguiente]', c).forEach(function (b) { b.addEventListener('click', function () { ir(actual + 1); programar(); }); });
      puntos.forEach(function (p) { p.addEventListener('click', function () { ir(parseInt(p.dataset.irA, 10)); programar(); }); });
      function actualizarPausa() {
        if (!pausa) { return; }
        pausa.setAttribute('aria-pressed', String(pausado));
        pausa.setAttribute('aria-label', pausado ? 'Reanudar el pase automático' : 'Pausar el pase automático');
        $('[data-icono="pausa"]', pausa).classList.toggle('hidden', pausado);
        $('[data-icono="play"]', pausa).classList.toggle('hidden', !pausado);
      }
      if (pausa) { pausa.addEventListener('click', function () { pausado = !pausado; actualizarPausa(); programar(); }); }
      // Pausa mientras el usuario interactúa (WCAG 2.2.2)
      c.addEventListener('mouseenter', function () { clearInterval(timer); });
      c.addEventListener('mouseleave', programar);
      c.addEventListener('focusin', function () { clearInterval(timer); });
      c.addEventListener('focusout', programar);
      marcar(0); actualizarPausa(); programar();
    });
  }

  /* ------------------------------------------------------------------
   * Envío automático de filtros (selects y fechas)
   * ------------------------------------------------------------------ */
  function initAutoEnvio() {
    $$('[data-auto-enviar]').forEach(function (el) {
      el.addEventListener('change', function () {
        var f = el.form;
        if (f) { if (f.requestSubmit) { f.requestSubmit(); } else { f.submit(); } }
      });
    });
  }

  /* ------------------------------------------------------------------
   * Aviso de cambios sin guardar
   * ------------------------------------------------------------------ */
  function initCambiosSinGuardar() {
    $$('form[data-avisar-cambios]').forEach(function (f) {
      var inicial = new URLSearchParams(new FormData(f)).toString();
      var enviando = false;
      var indicador = $('[data-indicador-cambios]', f);
      function sucio() { return !enviando && new URLSearchParams(new FormData(f)).toString() !== inicial; }
      f.addEventListener('input', function () { if (indicador) { indicador.hidden = !sucio(); } });
      f.addEventListener('submit', function () { enviando = true; });
      window.addEventListener('beforeunload', function (e) { if (sucio()) { e.preventDefault(); e.returnValue = ''; } });
    });
  }

  /* ------------------------------------------------------------------
   * Vista previa de imagen a partir de una ruta del bucket
   * ------------------------------------------------------------------ */
  function initVistaPrevia() {
    $$('input[data-vista-previa]').forEach(function (input) {
      var img = document.getElementById(input.dataset.vistaPrevia);
      if (!img) { return; }
      var aviso = img.parentElement.querySelector('[data-sin-vista]');
      var t;
      function mostrar(ok, texto) {
        img.classList.toggle('hidden', !ok);
        if (aviso) { aviso.classList.toggle('hidden', ok); aviso.textContent = texto; }
      }
      img.addEventListener('load', function () { mostrar(true, ''); });
      img.addEventListener('error', function () { if (input.value.trim()) { mostrar(false, 'No encontramos esa imagen'); } });
      input.addEventListener('input', function () {
        clearTimeout(t);
        t = setTimeout(function () {
          var v = input.value.trim().replace(/^\/+/, '');
          if (!v) { img.removeAttribute('src'); mostrar(false, 'Sin vista previa'); return; }
          img.src = /^https?:\/\//.test(v) ? v : input.dataset.base + v;
        }, 350);
      });
    });
  }

  /* ------------------------------------------------------------------
   * Navegación en curso: barra superior y resultados atenuados.
   * Así ningún clic en filtros, categorías u orden "parece no hacer nada".
   * ------------------------------------------------------------------ */
  function initNavegacion() {
    var html = document.documentElement;
    function marcar() { html.setAttribute('data-navegando', ''); }
    document.addEventListener('click', function (e) {
      var a = e.target.closest('a[href]');
      if (!a || e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) { return; }
      if (a.target === '_blank' || a.hasAttribute('download')) { return; }
      var url = new URL(a.href, location.href);
      if (url.origin !== location.origin || url.protocol.indexOf('http') !== 0) { return; }
      if (url.pathname === location.pathname && url.search === location.search && url.hash) { return; }
      if (/\/generar-boleta|formato=csv/.test(url.href)) { return; }
      marcar();
    });
    document.addEventListener('submit', function (e) {
      if (!e.defaultPrevented && e.target.method !== 'dialog') { marcar(); }
    });
    window.addEventListener('pageshow', function () { html.removeAttribute('data-navegando'); });
  }

  document.addEventListener('DOMContentLoaded', function () {
    Toast.init();
    initNavegacion();
    initCambiosSinGuardar();
    initVistaPrevia();
    initConfirmaciones();
    initValidacion();
    initEnvios();
    initReglasContrasena();
    initVerContrasena();
    initMenus();
    initCajones();
    initAtajos();
    initImagenes();
    initCarruseles();
    initAutoEnvio();
  });
})();

// Carga de fotos antes de guardar el formulario de producto.
document.querySelectorAll('[data-foto-producto]').forEach(function(input) {
 var form=input.closest('form'), estado=form.querySelector('[data-foto-estado]');
 var campo=form.querySelector('[name="imagen"]'), pendiente=false, error=false;
 form.addEventListener('submit',function(e) {
  if(pendiente || error) { e.preventDefault(); e.stopImmediatePropagation(); estado.textContent=pendiente?'Espera a que termine de subir la foto.':'La foto no se pudo subir. Selecciona otra o limpia el selector antes de guardar.'; }
 },true);
 input.addEventListener('change',async function() {
  if(pendiente) return;
  error=false;var foto=input.files[0];if(!foto) {estado.textContent='Puedes guardar sin cambiar la foto actual.';return;}
  if(foto.size>5242880){error=true;estado.textContent='La foto supera los 5 MB.';return;}
  pendiente=true;input.disabled=true;estado.textContent='Subiendo foto…';
  var botones=Array.from(form.querySelectorAll('button[type="submit"]'));botones.forEach(function(b){b.disabled=true;});
  try {
   var datos=new FormData();datos.append('token',input.dataset.token);datos.append('foto',foto);
   var respuesta=await fetch(input.dataset.url,{method:'POST',body:datos,credentials:'same-origin'});
   var texto=await respuesta.text();if(!respuesta.ok)throw new Error(respuesta.status===400?texto:'No se pudo guardar la foto. Inténtalo otra vez.');
   if(!/^local:(market|juguetes|cosmeticos):[a-f0-9-]{36}$/.test(texto))throw new Error('La sesión ha caducado. Vuelve a iniciar sesión.');
   campo.value=texto;var partes=texto.split(':'),img=form.querySelector('#vista-imagen');
   if(img){img.src=input.dataset.url+'?tienda='+partes[1]+'&id='+partes[2];img.classList.remove('hidden');}
   var vacio=form.querySelector('[data-sin-vista]');if(vacio)vacio.classList.add('hidden');
   estado.textContent='Foto subida. Guarda el producto para aplicar el cambio.';
  }catch(e){error=true;estado.textContent=e.message;}
  finally{pendiente=false;input.disabled=false;botones.forEach(function(b){b.disabled=false;});}
 });
});
