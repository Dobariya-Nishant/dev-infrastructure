FROM amazoncorretto:21-alpine-jdk AS build

WORKDIR /app

COPY . .

RUN chmod +x gradlew && ./gradlew clean build 


FROM gcr.io/distroless/java21-debian12 AS production

WORKDIR /app

COPY --from=build /app/build/libs/demo-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
