import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// 打包产物输出到 Nest 的 public/share，base 与路由 /share/:deviceId/:shareCode 一致
export default defineConfig({
  plugins: [react()],
  base: "/share/",
  build: {
    outDir: "share",
    emptyOutDir: true,
  },
  publicDir: "public",
});
