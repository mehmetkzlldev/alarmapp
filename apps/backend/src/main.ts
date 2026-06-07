import 'reflect-metadata';
import {
  Logger,
  ValidationPipe,
  VersioningType,
} from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { json, urlencoded } from 'express';
import { AppModule } from './app.module';
import { AppConfigService } from './config';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, {
    // Buffer logs until our logger is ready; structured logs come from interceptors.
    bufferLogs: true,
    // Disable the default body parser so we can raise the JSON size limit below
    // (mission photos are POSTed as base64 to /object-detection/verify-image).
    bodyParser: false,
  });

  const config = app.get(AppConfigService);
  const logger = new Logger('Bootstrap');

  // --- Body parsing with a raised limit for base64 mission images ---
  app.use(json({ limit: '15mb' }));
  app.use(urlencoded({ extended: true, limit: '15mb' }));

  // --- Security headers ---
  app.use(helmet());

  // --- CORS allowlist (no wildcard with credentials) ---
  const allowlist = config.corsOrigins;
  app.enableCors({
    origin: (origin, callback) => {
      // Allow non-browser clients (mobile app, curl) that send no Origin header.
      if (!origin || allowlist.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error(`Origin ${origin} not allowed by CORS`), false);
    },
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
    maxAge: 86400,
  });

  // --- API versioning + global prefix => /api/v1/* ---
  app.setGlobalPrefix('api');
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // --- Global validation: whitelist + transform, reject unknown props ---
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
      // Don't echo target objects back in error payloads.
      validationError: { target: false, value: false },
    }),
  );

  // Filters and interceptors are registered globally via APP_* providers in
  // AppModule (so they can use DI); nothing extra needed here.

  // --- Swagger (disabled in production) ---
  if (!config.isProduction) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('WakeUp AI API')
      .setDescription('AI alarm clock backend API')
      .setVersion('1.0')
      .addBearerAuth(
        {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          name: 'Authorization',
          in: 'header',
        },
        'access-token',
      )
      .addServer('/api/v1')
      .build();
    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('docs', app, document, {
      swaggerOptions: { persistAuthorization: true },
    });
  }

  // Graceful shutdown so Redis/DB/BullMQ connections close cleanly.
  app.enableShutdownHooks();

  await app.listen(config.port, '0.0.0.0');
  logger.log(`WakeUp AI backend listening on :${config.port} (env=${config.env})`);
  logger.log(`API base path: /api/v1`);
  if (!config.isProduction) {
    logger.log(`Swagger docs: /docs`);
  }
}

bootstrap().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('Fatal bootstrap error', err);
  process.exit(1);
});
