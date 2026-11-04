package util;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class Conexion {

    private static final String JDBC_URL;
    private static final Properties PROPS = new Properties();

    static {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(
                    "No se encontró el driver de PostgreSQL.", e
            );
        }

        String databaseUrl = env("DATABASE_URL", "");

        if (!databaseUrl.isEmpty()) {
            try {
                URI uri = URI.create(databaseUrl);

                String scheme = uri.getScheme();
                if (scheme == null
                        || !(scheme.equals("postgres")
                        || scheme.equals("postgresql"))) {
                    throw new IllegalArgumentException(
                            "DATABASE_URL debe usar postgres:// "
                            + "o postgresql://"
                    );
                }

                String userInfo = uri.getRawUserInfo();
                if (userInfo == null || !userInfo.contains(":")) {
                    throw new IllegalArgumentException(
                            "DATABASE_URL no contiene credenciales válidas."
                    );
                }

                String[] credentials = userInfo.split(":", 2);

                String user = decode(credentials[0]);
                String password = decode(credentials[1]);

                if (uri.getHost() == null || uri.getRawPath() == null) {
                    throw new IllegalArgumentException(
                            "DATABASE_URL no contiene host o base de datos."
                    );
                }

                int port = uri.getPort() == -1
                        ? 5432 : uri.getPort();

                String path = uri.getRawPath();
                String query = uri.getRawQuery() == null
                        ? "" : "?" + uri.getRawQuery();

                JDBC_URL = "jdbc:postgresql://"
                        + uri.getHost() + ":" + port
                        + path + query;

                PROPS.setProperty("user", user);
                PROPS.setProperty("password", password);

            } catch (Exception e) {
                throw new RuntimeException(
                        "No se pudo interpretar DATABASE_URL. "
                        + "Revisa su formato y las variables configuradas.",
                        e
                );
            }

        } else {
            JDBC_URL = env("DB_URL", "");

            String user = env("DB_USER", "");
            String password = env("DB_PASSWORD", "");

            if (JDBC_URL.isEmpty() || user.isEmpty()) {
                throw new RuntimeException(
                        "Falta configurar DATABASE_URL o las variables "
                        + "DB_URL, DB_USER y DB_PASSWORD."
                );
            }

            PROPS.setProperty("user", user);
            PROPS.setProperty("password", password);
        }

        if (!JDBC_URL.contains("sslmode=")) {
            PROPS.setProperty(
                    "sslmode",
                    env("DB_SSLMODE", "require")
            );
        }

        // Compatible con conexiones PostgreSQL y Supavisor.
        PROPS.setProperty("prepareThreshold", "0");
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(JDBC_URL, PROPS);
    }

    private static String env(String name, String defaultValue) {
        String value = System.getenv(name);
        return value == null || value.trim().isEmpty()
                ? defaultValue : value.trim();
    }

    private static String decode(String value) {
        try { return URLDecoder.decode(
                value.replace("+", "%2B"),
                "UTF-8"
        ); } catch (java.io.UnsupportedEncodingException e) { throw new IllegalStateException(e); }
    }
}
