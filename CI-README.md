# Integracion continua (CI) de Market

## Flujo
Desarrollador -> `git push` / Pull Request -> GitHub -> GitHub Actions -> Node/Tailwind -> Maven (Java 17) -> pruebas JUnit -> analisis estatico PMD -> SonarQube (opcional, si esta configurado) -> artefacto `Market.war` -> construccion de imagen Docker -> GHCR (solo push a main).

El trabajo `docker` **solo comienza si** el trabajo `ci` ha terminado correctamente. Los Pull Requests construyen la imagen pero **no la publican**. El artefacto WAR se descarga en GitHub > Actions > ejecucion > Artifacts.

## Archivos
- `.github/workflows/imagen.yml`: pipeline completo (reemplaza el anterior, que publicaba una imagen sin pruebas previas).
- `pom.xml`: incorpora JUnit 5 y Maven Surefire.
- `src/test/java/util/PasswordUtilTest.java`: primera prueba unitaria. Es necesario ampliar la cobertura con tests de DAO, validacion de tiendas, incidentes y SLA.

## SonarQube
Crear en GitHub > Settings > Secrets and variables > Actions:
- Secret `SONAR_TOKEN`: token emitido por tu servidor SonarQube / SonarQube Cloud.
- Variable `SONAR_HOST_URL`: URL publica de SonarQube (por ejemplo, la de SonarQube Cloud o un servidor accesible desde GitHub Actions; no `localhost`).
- Variable `SONAR_PROJECT_KEY`: identificador del proyecto en SonarQube.

Si faltan esos valores, el paso SonarQube se omite; **PMD sigue produciendo un reporte estatico**. Este ejemplo no obliga a pasar un Quality Gate de SonarQube: para ello, configura tambien el Quality Gate y una verificacion bloqueante. El informe PMD es informativo, no un gate bloqueante.

## Render
Conecta tu repositorio a un Web Service de tipo Docker en Render; configura `DATABASE_URL`, `METRICS_TOKEN` y `PORT=8080` como variables del servicio, nunca en el repositorio. El despliegue de Render es **CD** y se configura por separado: este pipeline valida y publica un WAR y una imagen GHCR, **no crea ni actualiza automaticamente servicios de Render**.

## Seguridad
- No subas `.env` ni credenciales al repositorio.
- Verifica antes de `git push`: `git status`, `git diff --cached`, `git ls-files .env`.
- Si una contraseña estuvo en un commit anterior, cambia esa contraseña: agregar `.gitignore` no borra el historial.
- La migracion Supabase se aplica por separado; la CI no debe modificar la base de datos de produccion.

## Verificaciones locales
```
npm ci
npm run build:css
mvn clean verify
# opcion: docker build -t market:ci .
```

## Buenas practicas
Commits pequenos, ramas de trabajo y Pull Requests; proteccion de main; tests y analisis en cada PR; versiones con tags; revisar duracion de Actions; evitar que una compilacion fallida se despliegue.
