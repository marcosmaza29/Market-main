package util;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.http.HttpSession;

/**
 * Mensajes de una sola lectura que sobreviven a una redirección (patrón Post/Redirect/Get).
 * También conserva lo que el usuario escribió y el campo con error, para no obligarle a
 * reescribir un formulario completo cuando falla una validación del servidor.
 */
public final class Flash {

    private static final String MENSAJES = "flash.mensajes";
    private static final String FORM = "flash.form";

    public static final class Mensaje implements Serializable {

        private static final long serialVersionUID = 1L;
        public final String tipo;
        public final String texto;
        public final String accionTexto;
        public final String accionUrl;

        Mensaje(String tipo, String texto, String accionTexto, String accionUrl) {
            this.tipo = tipo;
            this.texto = texto;
            this.accionTexto = accionTexto;
            this.accionUrl = accionUrl;
        }
    }

    private Flash() {
    }

    public static void exito(HttpSession s, String texto) {
        agregar(s, new Mensaje("exito", texto, null, null));
    }

    /** Éxito con una acción (por ejemplo "Deshacer") que apunta a una URL que acepta POST. */
    public static void exito(HttpSession s, String texto, String accionTexto, String accionUrl) {
        agregar(s, new Mensaje("exito", texto, accionTexto, accionUrl));
    }

    public static void error(HttpSession s, String texto) {
        agregar(s, new Mensaje("error", texto, null, null));
    }

    public static void info(HttpSession s, String texto) {
        agregar(s, new Mensaje("info", texto, null, null));
    }

    @SuppressWarnings("unchecked")
    private static void agregar(HttpSession s, Mensaje m) {
        List<Mensaje> lista = (List<Mensaje>) s.getAttribute(MENSAJES);
        if (lista == null) {
            lista = new ArrayList<>();
        }
        lista.add(m);
        s.setAttribute(MENSAJES, lista);
    }

    @SuppressWarnings("unchecked")
    public static List<Mensaje> consumir(HttpSession s) {
        if (s == null) {
            return Collections.emptyList();
        }
        List<Mensaje> lista = (List<Mensaje>) s.getAttribute(MENSAJES);
        s.removeAttribute(MENSAJES);
        return lista == null ? Collections.<Mensaje>emptyList() : lista;
    }

    public static void formulario(HttpSession s, Map<String, String[]> parametros, String campoConError) {
        formulario(s, parametros, campoConError, null);
    }

    /** Guarda los valores enviados y, opcionalmente, el campo con error y su mensaje. */
    public static void formulario(HttpSession s, Map<String, String[]> parametros, String campoConError, String mensaje) {
        HashMap<String, String> valores = new HashMap<>();
        for (Map.Entry<String, String[]> e : parametros.entrySet()) {
            String clave = e.getKey();
            if (clave.contains("contrasena") || clave.contains("clave") || clave.equals("nueva") || clave.equals("confirmar")) {
                continue; // nunca se reenvían contraseñas
            }
            if (e.getValue() != null && e.getValue().length > 0) {
                valores.put(clave, e.getValue()[0]);
            }
        }
        if (campoConError != null) {
            valores.put("__error", campoConError);
            valores.put("__mensaje", mensaje);
        }
        s.setAttribute(FORM, valores);
    }

    /** Lee (y borra) los valores guardados. Nunca devuelve null. */
    @SuppressWarnings("unchecked")
    public static Map<String, String> formulario(HttpSession s) {
        if (s == null) {
            return Collections.emptyMap();
        }
        Map<String, String> valores = (Map<String, String>) s.getAttribute(FORM);
        s.removeAttribute(FORM);
        return valores == null ? Collections.<String, String>emptyMap() : valores;
    }
}
