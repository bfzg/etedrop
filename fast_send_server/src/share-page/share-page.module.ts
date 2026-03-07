import { Module } from '@nestjs/common';

import { SharePageController } from './share-page.controller';
import { SharePageService } from './share-page.service';

@Module({
  controllers: [SharePageController],
  providers: [SharePageService],
})
export class SharePageModule {}
