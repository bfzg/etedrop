# 构建阶段：后端 + 分享页前端
# 需在仓库根目录构建，使上下文同时包含 fast_send_server 与 share-page-app：
#   docker build -f fast_send_server/Dockerfile -t fast-send-server .
FROM node:20-alpine AS builder

WORKDIR /app

# 后端依赖与源码（fast_send_server 内）
COPY fast_send_server/package.json fast_send_server/package-lock.json ./
RUN npm ci

COPY fast_send_server/ ./
RUN npm run build

# 分享页前端（与 fast_send_server 同级）
COPY share-page-app/ ./share-page-app/
RUN cd share-page-app && npm ci && cd .. && npm run build:share && cp -r share-page-app/share public/

# 运行阶段：仅生产依赖 + 构建产物
FROM node:20-alpine

WORKDIR /app

COPY fast_send_server/package.json fast_send_server/package-lock.json ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public

ENV PORT=3000
EXPOSE 3000

CMD ["node", "dist/main.js"]
