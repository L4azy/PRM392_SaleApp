# Use Maven with Java 17 to build the project
FROM maven:3.9.6-eclipse-temurin-17 AS build

# Set the working directory
WORKDIR /app

# Copy project files
COPY pom.xml .
COPY src src

# Build the application without running tests
RUN mvn clean package -DskipTests

# Use a lightweight JDK 17 runtime image
FROM eclipse-temurin:17-jdk-jammy

# Set working directory
WORKDIR /app

# Copy the built JAR from the build stage
COPY --from=build /app/target/SalesApp-0.0.1-SNAPSHOT.jar app.jar

# Optional: copy additional resources if needed
#COPY --from=build /app/uploads/lab /app/uploads/lab
#COPY --from=build /app/ArialUnicodeMSBold.ttf /app/

# Expose the port the app runs on
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]