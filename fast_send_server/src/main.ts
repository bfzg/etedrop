import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  const logger = new Logger('Bootstrap');
  logger.log(`Server is running on http://localhost:${port}`);
  logger.log(`Share WS endpoint: ws://localhost:${port}/api/share`);
  logger.log(`Signaling WS endpoint: ws://localhost:${port}/api/connect`);
}

bootstrap().catch((err) => {
  const logger = new Logger('Bootstrap');
  logger.error('Failed to start server', err);
  process.exit(1);
});
