# --- Estilos (Tailwind CSS) ---
FROM node:22-alpine AS css
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install --include=optional --no-audit --no-fund
COPY src ./src
RUN npm run build:css

# --- Build ---
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
COPY --from=css /app/src/main/webapp/assets/app.css src/main/webapp/assets/app.css
RUN mvn -q -B package -DskipTests

# --- Runtime (Tomcat 9, javax.servlet) ---
FROM tomcat:9.0-jdk17-temurin-noble
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /app/target/Market.war /usr/local/tomcat/webapps/ROOT.war
ENV PORT=8080
EXPOSE 8080
CMD ["sh", "-c", "sed -i \"s/port=\\\"8080\\\"/port=\\\"${PORT}\\\"/\" /usr/local/tomcat/conf/server.xml && catalina.sh run"]
