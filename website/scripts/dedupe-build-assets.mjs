#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const buildDir = path.join(root, "build");
const localeDirs = ["en", "ja", "es", "ko"];
const assetDirs = ["downloads", "video"];

function removeIfExists(targetPath) {
  if (!fs.existsSync(targetPath)) return;
  fs.rmSync(targetPath, { recursive: true, force: true });
}

function main() {
  if (!fs.existsSync(buildDir)) {
    console.error("build 目录不存在，请先执行 npm run build");
    process.exit(1);
  }

  for (const locale of localeDirs) {
    const localePath = path.join(buildDir, locale);
    if (!fs.existsSync(localePath)) continue;

    for (const assetName of assetDirs) {
      const src = path.join(buildDir, assetName);
      const dst = path.join(localePath, assetName);
      if (!fs.existsSync(src)) continue;

      removeIfExists(dst);

      const relativeTarget = path.relative(localePath, src);
      fs.symlinkSync(relativeTarget, dst, "junction");
      console.log(`linked ${path.join(locale, assetName)} -> ${relativeTarget}`);
    }
  }

  console.log("done: locale assets deduplicated with symlinks");
}

main();
