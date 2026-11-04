package util;

import java.io.File;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.MemoryUsage;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.LongAdder;

/** Metricas de la instancia; las metricas de hardware NO son exclusivas de cada tienda. */
public final class MonitorRendimiento {
    private MonitorRendimiento() {}
    private static final ConcurrentHashMap<String, Estadisticas> POR_TIENDA = new ConcurrentHashMap<>();
    private static final long INICIO = System.currentTimeMillis();
    private static final class Estadisticas {
        final LongAdder total = new LongAdder(), errores = new LongAdder(), latenciaMs = new LongAdder();
        final AtomicLong activos = new AtomicLong();
        final long[] minutos = new long[60];
        final long[] conteos = new long[60];
        synchronized void registrar(long momento, long duracion, boolean error) {
            long minuto = momento / 60000L;
            int i = (int) (minuto % minutos.length);
            if (minutos[i] != minuto) { minutos[i] = minuto; conteos[i] = 0; }
            conteos[i]++;
            total.increment(); latenciaMs.add(duracion);
            if (error) errores.increment();
        }
        synchronized long ultimosMinutos(int n) {
            long ahora = System.currentTimeMillis() / 60000L, resultado = 0;
            for (int i = 0; i < conteos.length; i++)
                if (minutos[i] > 0 && minutos[i] <= ahora && minutos[i] > ahora - n) resultado += conteos[i];
            return resultado;
        }
    }
    private static Estadisticas obtener(String tienda) {
        return POR_TIENDA.computeIfAbsent(tienda, k -> new Estadisticas());
    }
    public static void comenzar(String tienda) { obtener(tienda).activos.incrementAndGet(); }
    public static void terminar(String tienda, long duracionMs, boolean error) {
        Estadisticas e = obtener(tienda);
        e.activos.decrementAndGet();
        e.registrar(System.currentTimeMillis(), Math.max(0, duracionMs), error);
    }
    public static String json(String tienda) {
        Estadisticas e = obtener(tienda);
        Runtime r = Runtime.getRuntime();
        MemoryMXBean mem = ManagementFactory.getMemoryMXBean();
        MemoryUsage heap = mem.getHeapMemoryUsage();
        long limite = heap.getMax() > 0 ? heap.getMax() : r.maxMemory();
        File disco = new File(System.getProperty("catalina.base", "/"));
        long espacio = disco.getTotalSpace(), libre = disco.getUsableSpace();
        double cpu = cpuProceso();
        long total = e.total.sum();
        return "{\"tienda\":\"" + tienda + "\",\"timestamp\":" + System.currentTimeMillis()
            + ",\"inicio\":" + INICIO + ",\"solicitudes\":" + total
            + ",\"errores\":" + e.errores.sum()
            + ",\"activos\":" + e.activos.get()
            + ",\"ultimos5min\":" + e.ultimosMinutos(5)
            + ",\"promedioMs\":" + (total == 0 ? 0 : e.latenciaMs.sum() / total)
            + ",\"heapUsado\":" + heap.getUsed()
            + ",\"heapMaximo\":" + limite
            + ",\"cpuProceso\":" + cpu
            + ",\"discoTotal\":" + espacio
            + ",\"discoUsado\":" + Math.max(0, espacio - libre) + "}";
    }
    
private static double cpuProceso() {
    try {
        java.lang.management.OperatingSystemMXBean bean =
            java.lang.management.ManagementFactory
                .getOperatingSystemMXBean();

        Class<?> tipo = Class.forName(
            "com.sun.management.OperatingSystemMXBean"
        );

        if (tipo.isInstance(bean)) {
            java.lang.reflect.Method metodo =
                tipo.getMethod("getProcessCpuLoad");

            double valor = ((Number) metodo.invoke(bean))
                .doubleValue();

            if (valor >= 0 && Double.isFinite(valor)) {
                return Math.round(valor * 10000.0) / 100.0;
            }
        }

    } catch (ReflectiveOperationException |
             SecurityException e) {
        return -1;
    }

    return -1;
}

    public static String prometheus() {
        StringBuilder b = new StringBuilder();
        b.append("# HELP market_requests_total Total de solicitudes HTTP por tienda.\n# TYPE market_requests_total counter\n");
        for (String tienda : new String[]{"market", "juguetes", "cosmeticos"}) {
            Estadisticas e = obtener(tienda);
            String etiqueta = "{tienda=\"" + tienda + "\"}";
            b.append("market_requests_total").append(etiqueta).append(' ').append(e.total.sum()).append('\n');
            b.append("market_errors_total").append(etiqueta).append(' ').append(e.errores.sum()).append('\n');
            b.append("market_response_duration_ms_sum").append(etiqueta).append(' ').append(e.latenciaMs.sum()).append('\n');
            b.append("market_active_requests").append(etiqueta).append(' ').append(e.activos.get()).append('\n');
            b.append("market_requests_last_5m").append(etiqueta).append(' ').append(e.ultimosMinutos(5)).append('\n');
        }
        Runtime r = Runtime.getRuntime();
        MemoryUsage heap = ManagementFactory.getMemoryMXBean().getHeapMemoryUsage();
        File disco = new File(System.getProperty("catalina.base", "/"));
        b.append("market_jvm_heap_used_bytes ").append(heap.getUsed()).append('\n');
        b.append("market_jvm_heap_max_bytes ").append(heap.getMax() > 0 ? heap.getMax() : r.maxMemory()).append('\n');
        b.append("market_process_cpu_percent ").append(cpuProceso()).append('\n');
        b.append("market_shared_disk_total_bytes ").append(disco.getTotalSpace()).append('\n');
        b.append("market_shared_disk_used_bytes ").append(disco.getTotalSpace() - disco.getUsableSpace()).append('\n');
        b.append("market_up 1\n");
        return b.toString();
    }
}
