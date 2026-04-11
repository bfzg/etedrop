---
slug: mac-install-damaged
---

# Mac 安装教程（提示「文件已损坏」）

因应用未使用 Apple **Developer ID** 签名与公证，从浏览器下载后首次打开时，系统可能提示应用已损坏。可按下面步骤处理。

## 1. 出现的提示

双击应用时若看到类似提示（并说明由 Chrome / Safari 等下载）：

![应用已损坏提示](/img/mac-install-damaged-dialog.png)

## 2. 在终端移除隔离属性

在「终端」中执行（将路径换成你机器上 **EteDrop.app** 的实际位置；默认安装在「应用程序」时如下）：

```bash
xattr -cr "/Applications/EteDrop.app"
```

若不方便输入路径，可先输入 `xattr -cr `（注意末尾保留一个空格），再把 **Finder 里的应用图标** 拖进终端窗口，系统会自动填入路径，然后回车执行：

![将应用拖入终端以补全路径](/img/mac-install-xattr-drag-to-terminal.png)

执行完成后，再回到 Finder 中双击打开应用。

---

:::tip

若应用不在「应用程序」中，请对 **实际 .app 所在路径** 执行上述命令（例如从 DMG 拖到桌面的副本，路径可能是 `/Applications/EteDrop.app`）。

:::
