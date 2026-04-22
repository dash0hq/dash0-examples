package main

import (
	"context"
	"log/slog"
	"os"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/log/global"
	"go.opentelemetry.io/otel/sdk/resource"
	semconv "go.opentelemetry.io/otel/semconv/v1.40.0"

	"go.opentelemetry.io/contrib/bridges/otelslog"
)

func main() {
	ctx := context.Background()

	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceName("my-service"),
			semconv.ServiceVersion("0.1.0"),
		),
	)
	if err != nil {
		slog.Error("creating resource",
			slog.String("error", err.Error()),
		)
		os.Exit(1)
	}

	tp, err := newTracerProvider(ctx, res)
	if err != nil {
		slog.Error("creating tracer provider",
			slog.String("error", err.Error()),
		)
		os.Exit(1)
	}
	defer func() {
		if err := tp.Shutdown(ctx); err != nil {
			slog.Error("shutting down tracer provider",
				slog.String("error", err.Error()),
			)
		}
	}()
	otel.SetTracerProvider(tp)

	provider, err := newLoggerProvider(ctx, res)
	if err != nil {
		slog.Error("creating log provider",
			slog.String("error", err.Error()),
		)
		os.Exit(1)
	}
	defer func() {
		if err := provider.Shutdown(ctx); err != nil {
			slog.Error("shutting down log provider",
				slog.String("error", err.Error()),
			)
		}
	}()

	global.SetLoggerProvider(provider)

	// From here, the otelslog bridge (and any other
	// OTel log bridges) will pick up this provider.

	otelHandler := otelslog.NewHandler(
		"my-service",
		otelslog.WithLoggerProvider(provider),
		otelslog.WithSource(true),
	)

	jsonHandler := slog.NewJSONHandler(
		os.Stderr, &slog.HandlerOptions{
			AddSource: true,
			Level:     slog.LevelDebug,
		},
	)

	logger := slog.New(
		slog.NewMultiHandler(otelHandler, jsonHandler),
	)
	slog.SetDefault(logger)

	slog.Info("app started")

	handleOrder(ctx, "1234")
}

func handleOrder(ctx context.Context, orderID string) {
	tracer := otel.Tracer("my-service")
	ctx, span := tracer.Start(ctx, "handleOrder")
	defer span.End()

	// These log records will carry the span's trace ID
	// and span ID automatically.
	slog.InfoContext(ctx, "processing order",
		slog.String("otel.event.name", "order.processing"),
		slog.String("order_id", orderID),
	)

	slog.InfoContext(ctx, "order completed",
		slog.String("otel.event.name", "order.completed"),
		slog.String("order_id", orderID),
	)
}
