# Fast Send 使用统计说明

服务端现已提供独立的设备使用统计与日志能力。

## 记录内容

- 设备上线事件（Flutter 客户端发送 `device-online`）
- 设备离线事件（连接关闭 / 超时）
- 浏览器连接事件（分享页连接到某设备）

数据会持久化到 `runtime/` 目录：

- `runtime/device-registry.json`：按设备聚合的统计数据（可作为安装量基线）
- `runtime/device-usage.log`：仅追加的 JSONL 事件日志

## API 接口

- `GET /api/system/health`
  - 返回信令运行状态，并附带使用统计摘要。
- `GET /api/system/usage/summary`
  - 返回安装设备总数、在线设备数、24 小时活跃设备数、累计事件计数。
- `GET /api/system/usage/devices?limit=200`
  - 返回已记录设备列表（按最近活跃时间排序）。
- `GET /api/system/usage/events?limit=200`
  - 返回最近内存事件（按时间倒序）。
- `GET /api/system/metrics`
  - 返回 Prometheus 文本格式指标，可供 Grafana/Prometheus 采集。

## Grafana 接入（推荐）

1. 使用 Prometheus 抓取：`http://<server-host>:3000/api/system/metrics`
2. 在 Grafana 中添加 Prometheus 数据源。
3. 使用以下指标创建面板：
   - `fast_send_online_devices`
   - `fast_send_installed_devices`
   - `fast_send_active_devices_24h`
   - `fast_send_device_online_events_total`
   - `fast_send_browser_connect_events_total`
