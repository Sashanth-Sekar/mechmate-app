import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { ResponseInterceptor } from './common/interceptors/response.interceptor';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  
  const app = await NestFactory.create(AppModule, {
    logger: ['log', 'error', 'warn', 'debug', 'verbose'],
  });

  const configService = app.get(ConfigService);

  // Global prefix
  app.setGlobalPrefix('api/v1');

  // Global pipes
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Global filters and interceptors
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalInterceptors(new ResponseInterceptor());

  // CORS
  app.enableCors({
    origin: configService.get<string>('app.corsOrigin', '*'),
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  });

  // Swagger documentation
  const swaggerConfig = new DocumentBuilder()
    .setTitle('MechMate API')
    .setDescription('MechMate - Premium Automobile Service Ecosystem API')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('auth', 'Authentication endpoints')
    .addTag('users', 'User management')
    .addTag('vehicles', 'Vehicle management')
    .addTag('workshops', 'Workshop management')
    .addTag('bookings', 'Booking management')
    .addTag('mechanics', 'Mechanic operations')
    .addTag('services', 'Service categories')
    .addTag('notifications', 'Push and in-app notifications')
    .addTag('chat', 'Real-time messaging')
    .addTag('admin', 'Admin panel')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document);

  // Start server
  const port = configService.get<number>('app.port', 3000);
  const host = configService.get<string>('app.host', '0.0.0.0');

  await app.listen(port, host);
  
  logger.log(`🚀 MechMate API is running on http://${host}:${port}`);
  logger.log(`📚 API Documentation available at http://${host}:${port}/api/docs`);
  logger.log(`🌍 Environment: ${configService.get<string>('app.nodeEnv', 'development')}`);
}

bootstrap().catch((err) => {
  console.error('Failed to start application:', err);
  process.exit(1);
});
