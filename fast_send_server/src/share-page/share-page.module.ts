import { Module } from '@nestjs/common';

import { SharePageController } from './share-page.controller';

@Module({
  controllers: [SharePageController],
})
export class SharePageModule {}
