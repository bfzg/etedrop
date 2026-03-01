import {
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Post,
  Query,
} from '@nestjs/common';

import { CreateShareDto } from './dto/create-share.dto';
import { GetShareDto } from './dto/get-share.dto';
import { ShareService } from './share.service';

@Controller('api/share')
export class ShareController {
  constructor(private readonly shareService: ShareService) {}

  @Post()
  create(@Body() dto: CreateShareDto) {
    return this.shareService.createShare(dto);
  }

  @Get()
  list() {
    return this.shareService.listShares();
  }

  @Get(':code')
  getByCode(@Param('code') code: string, @Query() query: GetShareDto) {
    const share = this.shareService.getShare(code, query.password);
    if (!share) {
      throw new NotFoundException('分享不存在或已过期');
    }
    return share;
  }

  @Delete(':code')
  deleteByCode(@Param('code') code: string) {
    return {
      success: this.shareService.deleteShare(code),
    };
  }
}
