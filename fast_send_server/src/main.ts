import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { nonLoopbackIpv4Addresses } from './utils/ip';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const port = Number(process.env.PORT) || 3000;
  const host = process.env.HOST ?? '0.0.0.0';
  await app.listen(port, host);

  const logger = new Logger('Bootstrap');
  const ips = nonLoopbackIpv4Addresses();
  logger.log(`Listening on ${host}:${port}`);
  if (ips.length) {
    for (const ip of ips) {
      logger.log(`  http://${ip}:${port}`);
      logger.log(`  Share WS: ws://${ip}:${port}/api/share`);
      logger.log(`  Signaling WS: ws://${ip}:${port}/api/connect`);
    }
  } else {
    logger.warn(
      'No LAN IPv4 detected (e.g. offline or container); other machines may need your host IP and port.',
    );
  }
  logger.log(`Local: http://127.0.0.1:${port}`);
}

bootstrap().catch((err) => {
  const logger = new Logger('Bootstrap');
  logger.error('Failed to start server', err);
  process.exit(1);
});
