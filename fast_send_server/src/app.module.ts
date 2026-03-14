import { join } from 'node:path';

import { Module } from '@nestjs/common';
import { ServeStaticModule } from '@nestjs/serve-static';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SharePageModule } from './share-page/share-page.module';
import { SignalingModule } from './signaling/signaling.module';

@Module({
  imports: [
    // 全局静态目录：output.css、share-page 的 index.html 与 assets 等
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', 'public'),
    }),
    SharePageModule,
    SignalingModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
