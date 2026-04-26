```bash
npm run build
tar -chzf build.tar.gz build
```

解压

```bash
tar -xzf build.tar.gz
```

国际站（默认英文根路径）

```bash
npm run build
```

国内站（默认中文根路径 + `DOMESTIC_SITE`）

```bash
npm run build:domestic
```

提交代码前（若跑过国内 dev/build，恢复国际站布局）

```bash
npm run prepare:i18n-layout
```

Windows（国内构建）

```powershell
cd website
npm ci
$env:DOMESTIC_SITE = "1"
npm run build:domestic
```

（`build:domestic` 脚本里已带 `DOMESTIC_SITE=1`，上例仅在你需要单独再设环境变量时使用。）
