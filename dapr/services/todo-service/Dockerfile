# Multi-stage build Dockerfile for Todo Service

# Stage 1: Build the application
FROM eclipse-temurin:17-jdk as builder

WORKDIR /app

# Copy Maven wrapper and pom.xml
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Download dependencies (for better layer caching)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src src

# Build the application
RUN ./mvnw clean package -DskipTests

# Stage 2: Create the runtime image
FROM eclipse-temurin:17-jre

WORKDIR /app

# Create a non-root user for security
RUN groupadd -r todouser && useradd -r -g todouser todouser

# Copy the built jar from the builder stage
COPY --from=builder /app/target/todo-service-*.jar app.jar

# Change ownership of the app directory to the todouser
RUN chown -R todouser:todouser /app

# Switch to the non-root user
USER todouser

# Expose the application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/todos/health || exit 1

# Set JVM options for containerized environments
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]