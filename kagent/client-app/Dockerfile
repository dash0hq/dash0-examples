FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install OpenTelemetry instrumentation packages for detected libraries
RUN opentelemetry-bootstrap --action=install

COPY main.py .
COPY static/ ./static/

# Use OpenTelemetry auto-instrumentation
CMD ["opentelemetry-instrument", "python", "main.py"]
