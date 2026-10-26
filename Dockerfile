FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

RUN groupadd --system --gid 10001 app && \
    useradd --system --uid 10001 --gid 10001 --no-create-home --home-dir /app app

COPY --chown=10001:10001 target/capstone01-app.jar /app/app.jar

USER 10001:10001
EXPOSE 8080

ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "/app/app.jar"]
