import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ShareModule } from './share/share.module';
import { SignalingModule } from './signaling/signaling.module';

@Module({
  imports: [ShareModule, SignalingModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
