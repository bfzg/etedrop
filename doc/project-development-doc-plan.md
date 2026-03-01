# FastSend 项目计划开发文档清单

> 版本：v1
> 
> 目标：将 Flutter 客户端 + NestJS 服务端（信令/分享/设备）开发过程中的核心文档一次性规划清楚，便于按阶段落地。

## 1. 已有文档

- [x] `doc/electron-to-flutter-migration.md`：迁移后技术方案总览
- [x] `doc/webrtc-cloud-storage-solution.md`：WebRTC 网盘传输方案分析

---

## 2. 计划新增文档（按优先级）

### P0（本周必须）

- [ ] `doc/server-architecture-overview.md`
  - NestJS 分层架构、模块边界、依赖关系
- [ ] `doc/signaling-protocol-spec.md`
  - WebSocket 消息协议（send/receive/code/sdp/candidate/ping/err）
  - 状态机与时序图
- [ ] `doc/api-share-spec.md`
  - 分享 REST API（创建/查询/列表/删除）
  - 请求响应、错误码、鉴权要求
- [ ] `doc/data-model-design.md`
  - `devices` / `shares` / `sessions` 数据模型
  - 索引、唯一约束、过期策略
- [ ] `doc/flutter-server-integration-plan.md`
  - Flutter 端联调清单（baseUrl、WS 地址、鉴权、错误处理）

### P1（下周完成）

- [ ] `doc/auth-and-security-design.md`
  - JWT 认证流程、token 生命周期、刷新策略
  - WS 握手认证与设备签名
- [ ] `doc/reliability-design.md`
  - 心跳、重连、超时、幂等、会话恢复机制
- [ ] `doc/turn-stun-strategy.md`
  - STUN/TURN 配置策略、连接成功率保障
- [ ] `doc/error-code-convention.md`
  - 服务端统一错误码规范（HTTP + WS）
- [ ] `doc/logging-observability-plan.md`
  - 日志字段、链路追踪、监控告警指标

### P2（上线前）

- [ ] `doc/testing-strategy.md`
  - 单测/集成/E2E/压测范围与通过标准
- [ ] `doc/deployment-and-env.md`
  - Docker、环境变量、配置项说明（dev/staging/prod）
- [ ] `doc/release-checklist.md`
  - 发版前检查项（接口、协议、回归、监控）
- [ ] `doc/ops-runbook.md`
  - 常见故障处理手册（连接失败、配对异常、重连失败）
- [ ] `doc/roadmap-milestones.md`
  - 2~3 周里程碑、验收标准、风险跟踪

---

## 3. 推荐编写顺序

1. `server-architecture-overview.md`
2. `signaling-protocol-spec.md`
3. `api-share-spec.md`
4. `data-model-design.md`
5. `flutter-server-integration-plan.md`
6. `auth-and-security-design.md`
7. `reliability-design.md`
8. 其余文档按上线节奏补齐

---

## 4. 文档模板建议（统一格式）

每篇文档建议统一包含：

1. 背景与目标
2. 范围（In Scope / Out of Scope）
3. 设计方案
4. 接口或协议定义
5. 异常与边界处理
6. 验收标准
7. 待办项与风险

---

## 5. 文档维护约定

- 新增功能必须同步更新对应文档（接口、协议、数据模型至少一项）
- 协议和错误码文档优先级高于实现细节文档
- 每周例会前更新本清单中的完成状态
