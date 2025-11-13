FROM gradle:jdk21 AS build

WORKDIR /app

COPY . .

RUN gradle clean build -x test


FROM gcr.io/distroless/java21-debian12 AS production

WORKDIR /app

COPY --from=build /app/build/libs/kea-api-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
