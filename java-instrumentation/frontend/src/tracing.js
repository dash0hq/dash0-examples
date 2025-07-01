import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-web';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { FetchInstrumentation } from '@opentelemetry/instrumentation-fetch';
import { XMLHttpRequestInstrumentation } from '@opentelemetry/instrumentation-xml-http-request';
import { trace } from '@opentelemetry/api';

// Create a tracer provider
const provider = new WebTracerProvider({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'todo-frontend',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
  }),
});

// Use environment variable or fallback to relative URL
const getTracingUrl = () => {
  // Use build-time environment variable if set, otherwise relative URL
  return process.env.REACT_APP_OTEL_EXPORTER_URL || `${window.location.origin}/v1/traces`;
};

// Create and configure the OTLP exporter
const exporter = new OTLPTraceExporter({
  url: getTracingUrl(),
});

// Add span processor
provider.addSpanProcessor(new BatchSpanProcessor(exporter));

// Register the provider
provider.register();

// Register instrumentations
registerInstrumentations({
  instrumentations: [
    new FetchInstrumentation({
      clearTimingResources: true,
    }),
    new XMLHttpRequestInstrumentation({
      clearTimingResources: true,
    }),
  ],
});

console.log('OpenTelemetry initialized for browser');

export default provider;