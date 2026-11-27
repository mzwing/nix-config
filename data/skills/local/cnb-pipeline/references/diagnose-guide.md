# CI 流水线诊断指南

两种模式：**🔧 失败诊断**（根因分析 + 修复）｜**⚡ 性能优化**（瓶颈分析 + 加速）。失败 + 慢并存时，先诊断失败，再附耗时分析。

下文的 `cnb` 命令需要本机已登录的 cnb CLI，并显式传 `--repo <组织/仓库> --number <PR 编号>`（不传时读的是 CNB 流水线里的环境变量）。

---

## Step 1：确定构建 sn（可选）

默认不传 `--sn`，CLI 自动定位失败构建。需显式指定时，从 `cnb pulls check-status` 对应检查项的 `target_url` 末段取 sn（形如 `cnb-xxx-xxxxxxxxx`），勿用 `context` 字段。

其他来源：

| 用户输入 | 获取方式 |
|---------|---------|
| 构建链接 | URL 中 `/-/build/logs/{sn}` 片段 |
| 已知 sn | 直接使用 |
| 历史构建 | `cnb build get-build-logs --repo ... --sourceRef ...` 查询后挑选 |

---

## 🔧 失败诊断

```bash
cnb pulls get-ci-logs           # 自动定位失败构建
```

CLI 自动：查询状态 → 定位失败 Stage → 获取详细日志（无日志时降级到全量 + base64 解码）→ 输出耗时概览。

**失败类型判定**（多类型并存时按 代码 > 配置 > 外部服务 定优先级）：

| 类型 | 特征关键词 | 处理 |
|------|-----------|------|
| 🔴 代码 | `error:` `FAILED` `test failed` `eslint` `TypeError` `SyntaxError` `npm ERR!` `ERESOLVE` | 定位错误文件/行号，关联最近提交 |
| 🟡 配置 | `image not found` `pull image failed` `invalid configuration` `env not set` `permission denied` `OOM` | 读取 `.cnb.yml` / `.ci/` 分析配置 |
| 🔵 外部服务 | `ETIMEDOUT` `ECONNREFUSED` `ENOTFOUND` `502/503/504` `rate limit` `SSL` | 指出故障服务，建议重试 |

---

## ⚡ 性能优化

先取 Stage 耗时与慢 Stage 日志（如 `cnb pulls get-ci-timing`；其余命令用 `cnb build --help` / `cnb pulls --help` 查）。分析要点：耗时 >5min、占比 >50%、无依赖可并行。

CNB 侧的优化手段：依赖缓存用 `docker.volumes`，系统依赖用 `docker.build` 预装，无依赖的步骤改用 `jobs` 对象形式并行或拆成同事件的多条 Pipeline，资源不足时调大 `runner.cpus`（字段见 `syntax-reference.md`）。

---

## 报告输出

- **失败诊断**：构建编号、失败类型、Pipeline/Stage 状态表、根因（含关键日志）、修复建议。
- **性能优化**：构建编号、总耗时、Stage 耗时排行、瓶颈分析、按收益排序的优化建议（附预估节省时间与 `.cnb.yml` 修改片段）。

报告遵循**结论先行**：先给判定结论，再附证据日志。
