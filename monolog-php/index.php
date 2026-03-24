<?php

declare(strict_types=1);

require __DIR__ . '/vendor/autoload.php';

use Monolog\Logger;
use Monolog\Level;
use Monolog\Handler\StreamHandler;
use Monolog\Formatter\JsonFormatter;
use Monolog\Processor\ProcessIdProcessor;
use Monolog\Processor\HostnameProcessor;
use Monolog\Processor\MemoryUsageProcessor;
use Monolog\LogRecord;
use OpenTelemetry\API\Globals;
use OpenTelemetry\Contrib\Logs\Monolog\Handler
    as OTelHandler;

// ---------------------------------------------------
// Logger setup
// ---------------------------------------------------
$logger = new Logger('app');

// Console output (structured JSON)
$consoleHandler = new StreamHandler(
    'php://stdout',
    Level::Debug
);
$consoleHandler->setFormatter(new JsonFormatter());
$logger->pushHandler($consoleHandler);

// OTel export (active when the SDK is configured)
$loggerProvider = Globals::loggerProvider();
$otelHandler = new OTelHandler(
    $loggerProvider,
    Level::Info,
);
$logger->pushHandler($otelHandler);

// ---------------------------------------------------
// Processors
// ---------------------------------------------------
$logger->pushProcessor(new ProcessIdProcessor());
$logger->pushProcessor(new HostnameProcessor());
$logger->pushProcessor(new MemoryUsageProcessor());

$logger->pushProcessor(
    function (LogRecord $record): LogRecord {
        return $record->with(
            extra: array_merge(
                $record->extra,
                [
                    'app_version' => getenv('APP_VERSION')
                        ?: '0.1.0',
                    'environment' => getenv('APP_ENV')
                        ?: 'development',
                ]
            )
        );
    }
);

// ---------------------------------------------------
// Structured logging with context
// ---------------------------------------------------
$logger->info('Application started.');

$logger->info('Incoming request.', [
    'http.request.method' => 'POST',
    'http.route' => '/api/v2/orders',
    'server.address' => 'api.acme.io',
    'client.address' => '203.0.113.42',
    'user.id' => 'usr_8f3a2c91',
    'user.role' => 'customer',
    'tenant.id' => 'tenant_acme_corp',
]);

$logger->info('Order placed successfully.', [
    'order_id' => 'ord-48291',
    'customer_id' => 'cust-1024',
    'total' => 79.99,
]);

$logger->warning('Inventory running low.', [
    'product_id' => 'prod-7721',
    'stock_remaining' => 3,
]);

// ---------------------------------------------------
// Exception logging with chained causes
// ---------------------------------------------------
function connectToDatabase(): void
{
    try {
        throw new \PDOException(
            'Connection refused on port 5432'
        );
    } catch (\PDOException $inner) {
        throw new \RuntimeException(
            'Database unavailable',
            previous: $inner
        );
    }
}

try {
    connectToDatabase();
} catch (\RuntimeException $e) {
    $logger->alert(
        'Service degraded: database layer down.',
        ['exception' => $e]
    );
}

$logger->info('Application shutting down.');
