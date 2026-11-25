package util;

import com.itextpdf.text.*;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfWriter;
import java.io.IOException;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;

/** Informe PDF de diagnostico, limitado a las metricas reales disponibles. */
public final class ReporteRendimiento {
    private ReporteRendimiento() {}
    private static final BaseColor AZUL = new BaseColor(24, 73, 112);
    private static final Font TITULO = new Font(Font.FontFamily.HELVETICA, 17, Font.BOLD, AZUL);
    private static final Font SUB = new Font(Font.FontFamily.HELVETICA, 11, Font.BOLD, AZUL);
    private static final Font TEXTO = new Font(Font.FontFamily.HELVETICA, 9);
    private static final Font PEQUENO = new Font(Font.FontFamily.HELVETICA, 8, Font.ITALIC, BaseColor.DARK_GRAY);

    public static final class Alerta {
        public final String nivel, detalle, recomendacion;
        public Alerta(String nivel, String detalle, String recomendacion) {
            this.nivel = nivel; this.detalle = detalle; this.recomendacion = recomendacion;
        }
    }

    public static List<Alerta> evaluar(MonitorRendimiento.Instantanea d) {
        List<Alerta> alertas = new ArrayList<>();
        double ram = porcentaje(d.heapUsado, d.heapMaximo);
        double disco = porcentaje(d.discoUsado, d.discoTotal);
        if (ram >= 85) alertas.add(new Alerta("ALTA", "Heap JVM al " + formato(ram) + "%.", "Revisar consumo de memoria, GC y posibles fugas."));
        if (d.cpuProceso >= 85) alertas.add(new Alerta("ALTA", "CPU del proceso al " + formato(d.cpuProceso) + "%.", "Revisar procesos y consultas costosas."));
        if (d.cpuProceso < 0) alertas.add(new Alerta("INFO", "CPU no disponible en esta JVM.", "Comprobar soporte de la metrica del proceso."));
        if (disco >= 90) alertas.add(new Alerta("ALTA", "Disco compartido al " + formato(disco) + "%.", "Revisar logs, archivos temporales y capacidad del contenedor."));
        if (d.promedioMs >= 1500 && d.solicitudes > 0) alertas.add(new Alerta("MEDIA", "Tiempo medio acumulado de " + d.promedioMs + " ms.", "Revisar consultas SQL y puntos de respuesta lentos."));
        if (d.errores > 0 && d.solicitudes > 0) {
            double tasa = 100.0 * d.errores / d.solicitudes;
            if (tasa >= 5) alertas.add(new Alerta("ALTA", "Errores HTTP 5xx desde el arranque: " + d.errores + " (" + formato(tasa) + "%).", "Inspeccionar logs de Tomcat e incidentes de esta tienda."));
            else alertas.add(new Alerta("MEDIA", "Se registraron " + d.errores + " errores HTTP 5xx desde el arranque.", "Revisar logs de Tomcat para identificar causas."));
        }
        if (d.solicitudes == 0) alertas.add(new Alerta("INFO", "No hay solicitudes registradas para esta tienda desde el arranque.", "Generar trafico de prueba y comprobar el filtro de monitoreo."));
        if (alertas.isEmpty()) alertas.add(new Alerta("OK", "Sin umbrales superados en las metricas disponibles.", "Mantener el seguimiento en Grafana y revisar logs regularmente."));
        return alertas;
    }
    private static double porcentaje(long valor, long total) { return total > 0 ? 100.0 * valor / total : 0; }
    private static String formato(double n) { return String.format(Locale.US, "%.1f", n); }
    private static String mib(long v) { return formato(v / 1048576.0) + " MiB"; }
    private static String fecha(long epoch) {
        SimpleDateFormat df = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss", new Locale("es", "PE"));
        df.setTimeZone(TimeZone.getTimeZone("America/Lima"));
        return df.format(new Date(epoch)) + " (Peru)";
    }
    private static void linea(PdfPTable tabla, String campo, String valor) {
        PdfPCell a = new PdfPCell(new Phrase(campo, TEXTO));
        PdfPCell b = new PdfPCell(new Phrase(valor, TEXTO));
        a.setPadding(6); b.setPadding(6);
        tabla.addCell(a); tabla.addCell(b);
    }
    public static void generar(MonitorRendimiento.Instantanea d, OutputStream salida) throws IOException {
        Document doc = new Document(PageSize.A4, 42, 42, 43, 42);
        try {
            PdfWriter.getInstance(doc, salida);
            doc.open();
            doc.add(new Paragraph("Informe de rendimiento - " + Tienda.nombre(d.tienda), TITULO));
            doc.add(new Paragraph("Generado: " + fecha(d.fecha), TEXTO));
            doc.add(new Paragraph("Inicio de la instancia Java: " + fecha(d.inicio), TEXTO));
            doc.add(Chunk.NEWLINE);
            doc.add(new Paragraph("Actividad de la tienda", SUB));
            PdfPTable a = new PdfPTable(new float[]{2.4f, 1.8f});
            a.setWidthPercentage(100); a.setSpacingBefore(8); a.setSpacingAfter(10);
            linea(a, "Solicitudes desde el arranque", String.valueOf(d.solicitudes));
            linea(a, "Solicitudes en los ultimos 5 minutos", String.valueOf(d.ultimos5min));
            linea(a, "Solicitudes activas", String.valueOf(d.activos));
            linea(a, "Errores HTTP 5xx desde el arranque", String.valueOf(d.errores));
            linea(a, "Tiempo medio acumulado", d.promedioMs + " ms");
            doc.add(a);
            doc.add(new Paragraph("Recursos compartidos del servidor", SUB));
            PdfPTable b = new PdfPTable(new float[]{2.4f, 1.8f});
            b.setWidthPercentage(100); b.setSpacingBefore(8); b.setSpacingAfter(10);
            linea(b, "Heap Java", mib(d.heapUsado) + " / " + mib(d.heapMaximo) + " (" + formato(porcentaje(d.heapUsado, d.heapMaximo)) + "%)");
            linea(b, "CPU del proceso Java", d.cpuProceso < 0 ? "No disponible" : formato(d.cpuProceso) + "%");
            linea(b, "Disco del contenedor", mib(d.discoUsado) + " / " + mib(d.discoTotal) + " (" + formato(porcentaje(d.discoUsado, d.discoTotal)) + "%)");
            doc.add(b);
            doc.add(new Paragraph("Posibles fallas y recomendaciones", SUB));
            for (Alerta alerta : evaluar(d)) {
                Paragraph p = new Paragraph("[" + alerta.nivel + "] " + alerta.detalle + " " + alerta.recomendacion, TEXTO);
                p.setSpacingBefore(7); doc.add(p);
            }
            doc.add(Chunk.NEWLINE);
            doc.add(new Paragraph("Criterios orientativos: RAM >= 85%; CPU >= 85%; disco >= 90%; media >= 1500 ms; "
                    + "errores 5xx acumulados. Las alertas orientan el diagnostico, no prueban una falla.", PEQUENO));
            doc.add(new Paragraph("Alcance: captura al momento de generar el PDF. Contadores acumulados desde el inicio "
                    + "del proceso (se reinician al reiniciar Market), no historial de 24 horas. "
                    + "El promedio de respuesta es acumulado. La CPU/RAM/disco pertenecen a la instancia compartida, "
                    + "no exclusivamente a esta tienda. No incluye logs, traces ni eventos de Supabase.", PEQUENO));
            doc.add(new Paragraph("Herramientas: Java/Tomcat; Prometheus y Grafana disponibles para historial y analisis de tendencias.", PEQUENO));
        } catch (DocumentException ex) {
            throw new IOException("No se pudo generar el informe PDF", ex);
        } finally {
            doc.close();
        }
    }
}
