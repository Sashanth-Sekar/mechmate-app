import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import appConfig from './config/app.config';
import databaseConfig from './config/database.config';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { VehiclesModule } from './modules/vehicles/vehicles.module';
import { WorkshopsModule } from './modules/workshops/workshops.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { MechanicsModule } from './modules/mechanics/mechanics.module';
import { ServicesModule } from './modules/services/services.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { ChatModule } from './modules/chat/chat.module';
import { AdminModule } from './modules/admin/admin.module';
import { RedisModule } from './modules/redis';
import { AppGateway } from './websocket/app.gateway';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig, databaseConfig],
      envFilePath: '.env',
    }),

    // Database - uses better-sqlite3 for development, PostgreSQL for production
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const dbType = config.get<string>('database.type', 'better-sqlite3');

        if (dbType === 'better-sqlite3') {
          return {
            type: 'better-sqlite3',
            database: config.get<string>('database.database', 'data/mechmate.db'),
            entities: [__dirname + '/database/entities/**/*.entity{.ts,.js}'],
            synchronize: config.get<boolean>('database.synchronize', true),
            autoLoadEntities: true,
          };
        }

        return {
          type: 'postgres',
          host: config.get<string>('database.host', 'localhost'),
          port: config.get<number>('database.port', 5432),
          username: config.get<string>('database.username', 'postgres'),
          password: config.get<string>('database.password', 'postgres'),
          database: config.get<string>('database.database', 'mechmate'),
          entities: [__dirname + '/database/entities/**/*.entity{.ts,.js}'],
          synchronize: config.get<boolean>('database.synchronize', false),
          autoLoadEntities: true,
          ssl: config.get<boolean>('database.ssl', false),
        };
      },
    }),

    // Rate limiting
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),

    // Global Redis cache
    RedisModule,

    // Feature modules
    AuthModule,
    UsersModule,
    VehiclesModule,
    WorkshopsModule,
    BookingsModule,
    MechanicsModule,
    ServicesModule,
    NotificationsModule,
    ChatModule,
    AdminModule,
  ],
  providers: [
    AppGateway,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
