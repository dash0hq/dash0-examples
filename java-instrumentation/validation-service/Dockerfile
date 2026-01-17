FROM azul/zulu-openjdk:17-latest

WORKDIR /app

# Install curl for downloading OpenTelemetry agent
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Download OpenTelemetry Java agent
RUN curl -L -o opentelemetry-javaagent.jar https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar

# Copy gradle files
COPY build.gradle settings.gradle gradlew ./
COPY gradle gradle

# Download dependencies
RUN ./gradlew dependencies --no-daemon

# Copy source code
COPY src src

# Build the application
RUN ./gradlew build --no-daemon

# Run the application
EXPOSE 3001
CMD ["java", "-javaagent:opentelemetry-javaagent.jar", "-jar", "build/libs/validation-service-0.0.1-SNAPSHOT.jar"]