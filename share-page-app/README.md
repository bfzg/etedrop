# 分享页前端 (React SPA)

分享链接页面的独立 React 项目，打包产物由 Nest 以静态资源方式提供。

## 开发

```bash
npm install
npm run dev
```

- 启动后浏览器会打开 **http://localhost:5173/share**；若未自动打开，请手动访问该地址。
- 根路径或 `/share` 会显示说明页；真实分享页需访问 **http://localhost:5173/share/:deviceId/:shareCode**（例如 `/share/demo/000000`）。
- 样式由 `main.tsx` 引入的 `./output.css` 提供，需先生成：在**另开终端**执行 `npm run tailwind`，再刷新页面。

## 构建

```bash
npm run build
```

输出到 `fast_send_server/public/share/`（index.html + assets/）。服务端会将 `GET /share/:deviceId/:shareCode` 指向该 index.html，由前端路由解析参数。

## 结构说明

- `src/pages/SharePageView.tsx`：分享页主视图
- `src/hooks/useSharePage.ts`：WebSocket / WebRTC / DataChannel 逻辑
- `src/utils/format.ts`：文件大小、图标等工具
- 样式依赖服务端提供的 `/output.css`（Tailwind），与现有分享页一致

## 部署

在服务端项目根目录执行 `npm run build:share` 即可生成 `public/share/`，无需单独部署该前端。
