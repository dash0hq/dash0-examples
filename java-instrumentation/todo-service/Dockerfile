# Use an official OpenJDK image
FROM eclipse-temurin:17-jdk

# Set the working directory inside the container
WORKDIR /app

# Download OpenTelemetry Java agent
RUN curl -L -o opentelemetry-javaagent.jar https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar

# Copy the Gradle wrapper and project files
COPY gradlew gradlew
COPY gradle gradle
COPY build.gradle settings.gradle ./
COPY src src

# Give execution permissions to the Gradle wrapper
RUN chmod +x gradlew

# Build the application
RUN ./gradlew clean build -x test

EXPOSE 3000

# Run the application with OpenTelemetry agent
CMD ["java", "-javaagent:opentelemetry-javaagent.jar", "-jar", "build/libs/todo-java-0.0.1-SNAPSHOT.jar"]