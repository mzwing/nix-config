---
name: cnb-pipeline
description: 编写、修改、审查 .cnb.yml 流水线配置，诊断构建失败原因并优化性能
---

# CNB 流水线配置与诊断

> 文档 URL 中的 `${CNB_WEB_PROTOCOL:-https}`、`${CNB_WEB_HOST:-cnb.cool}` 为环境变量。
> 使用前先 `echo` 获取实际值。
>
> 项目有 `.cnb.yml` 既有约定、`CONTRIBUTING` 或其它明确说明时，一律以项目规定为准。

## 模式判定

按用户意图选：

- **配置模式**（写/改流水线，含搜索插件市场、生成插件任务配置）→ 走「配置工作流程」
- **诊断模式**（失败/报错/慢/优化）→ 走「诊断工作流程」
- **构建节点模式**（选择/调度/接入后的自托管 Runner 配置与排查）→ 读 `references/self-hosted-runner.md`

## 配置工作流程

按序执行（前四步**先看后写**，第五六步**配置必校**）：

1. **先问需求** -- 明确触发分支、事件、构建语言/环境、构建步骤、特殊需求。信息充足可直接生成。
2. **先读现状** -- 修改场景下先读取 `.cnb.yml` 和 `.ci/` 目录。
3. **插件查证** -- 需要插件任务（`image` + `settings`）时读 `references/plugin-search.md`：
   搜索插件市场 → 读插件 README → 生成配置片段（`settings` 参数以插件 README 为准，**禁止凭记忆生成**）。
   平台级插件知识（任务类型选择、插件制作规范、市场总览）走 `cnb-docs` 查官方文档。
4. **按需加载** -- 语法细节不确定时，读「详细参考文档」里对应的那篇；也可拼接在线文档 URL。
5. **套骨架生成** -- 按下方「结构骨架」生成完整可运行的配置。
6. **配置必校** -- 每次生成/修改 `.cnb.yml` 或 `.cnb/web_trigger.yml` 后必须校验通过才能展示给用户。
7. **解释要点** -- 简要说明关键部分。

### 校验命令

用 `nix-shell` 临时取 `check-jsonschema`，同时查 YAML 语法（含重复 key）和官方 Schema：

```bash
nix-shell -p check-jsonschema --run 'check-jsonschema --data-transform gitlab-ci --schemafile https://docs.cnb.cool/conf-schema-zh.json .cnb.yml'
nix-shell -p check-jsonschema --run 'check-jsonschema --schemafile https://docs.cnb.cool/web-trigger-schema-zh.json .cnb/web_trigger.yml'
```

- `.cnb.yml`（流水线配置）→ `YAML 语法` → `Schema` → 按下方「校验规则」逐条自查语义，三项均通过才算有效。
- `.cnb/web_trigger.yml`（Web 触发器）→ `YAML 语法` → `Schema` → `目录约束`（必须位于 `.cnb/` 下），不走语义规则；未配置时跳过。

`--data-transform gitlab-ci` 让 `!reference`（与 GitLab 同语法）能被解析，但引用会被当成字符串列表去校验。用到 `!reference` 时加 `--verbose` 看全部错误：值为引用列表（如 `['.docker-config']`）的错误及其上层路径的连带报错可以忽略，其余照常修复。

### 校验失败处理

校验不通过时按失败的那一关修复。

1. **语法关** → YAML 缩进（必须空格）、引号、特殊字符转义
2. **语义关** → 按下方「校验规则」逐项排查，参考对应 references 文档
3. **Schema 关** → 检查字段名拼写、类型、必填项，参考 `references/syntax-reference.md`

## 诊断工作流程

失败类型判定与性能优化分析的完整流程见 `references/diagnose-guide.md`，进入本节前先读它。

1. **取数据** -- 失败诊断用 `cnb pulls get-ci-logs`（自动定位失败构建，可用 `--sn` 指定）；
   性能优化先取 Stage 耗时与慢 Stage 日志（如 `cnb pulls get-ci-timing`）。
   需指定构建号时，取 `cnb pulls check-status` 的 `target_url` 末段作为 `--sn`。本机没有 `cnb` CLI 时，请用户贴出失败日志或 Stage 耗时。
2. **先判后修** -- 判定失败类型或耗时瓶颈，给出修复/优化建议；配置相关问题结合 references 分析。

---

## 结构骨架

配置层级：**分支 → 事件 → Pipeline → Stage → Job**

```yaml
<branch>:                          # main / "feature/*" / "$"(兜底)
  <event>:                         # push / pull_request / tag_push / ...
    - name: <pipeline-name>
      # runner:                    # 可选，默认 8 核 16G；低负载用 1/2/4，高负载/OOM 用 16/32
      #   cpus: 8
      #   namespace: group         # 自托管构建机：必须与 tags 同时配置（详见 references/self-hosted-runner.md）
      #   tags: [mac, arm64]
      docker:
        image: node:20             # 或 build (Dockerfile) 或 devcontainer
      services:
        - docker                   # Docker-in-Docker
      env:
        KEY: value
      imports:
        - https://cnb.cool/<org>/<secret-repo>/-/blob/main/secrets.yml
      stages:
        - name: step1
          script: echo hello       # 脚本任务
        - name: step2
          type: cnb:trigger        # 内置任务
          options: { ... }
        - name: step3
          image: plugins/docker    # 插件任务
          settings: { ... }
      failStages: [...]            # stages 失败时执行
      endStages: [...]             # prepare 成功后，无论 stages 成功或失败均执行
```

### Stage 执行语义（三态）

- **`stages`（主链）**：正常顺序执行，**任一失败则中断**，跳转到 `failStages`。**影响流水线状态**。典型用途：构建、测试、部署。
- **`failStages`（失败链）**：**仅当 `stages` 有失败时**执行。**影响流水线状态**。典型用途：发失败通知、回滚、清理。
- **`endStages`（收尾链）**：`prepare` 成功后，**无论 `stages` 成败均执行**（在 `stages`/`failStages` 之后）。
  - **不影响最终状态**。典型用途：清理临时文件、归档日志。

> **常见误区 — 成功/失败通知的正确放置**：
> 若需区分成功和失败发送不同消息：
> - **失败通知** → 放 `failStages`
> - **成功通知** → 放 `stages` **最后一个任务**（前面全部成功才会到达这里）
> - **不要**把"仅成功时才发的通知"放 `endStages`——失败时它也会执行，用户会同时收到红绿两条通知

下面列出常用内置变量，完整列表见 `references/env-variables.md`；触发事件与字段等价细节见「详细参考文档」。

### 常用内置变量

- `CNB_BRANCH`：分支/Tag 名
- `CNB_COMMIT` / `CNB_COMMIT_SHORT`：Commit SHA
- `CNB_REPO_SLUG`：仓库路径
- `CNB_BUILD_ID`：构建 ID
- `CNB_TOKEN`：构建凭证（PR 事件权限受限）
- `CNB_EVENT`：事件名
- `CNB_PULL_REQUEST_IID`：PR 编号
- `CNB_PIPELINE_KEY`：流水线 key（对象形式为 key 名如 `frontend`，数组形式为自动索引如 `pipeline-0`）
- `CNB_PIPELINE_NAME`：当前流水线的 `name` 字段（未声明时为空）；按 key 关联配置时优先用 `CNB_PIPELINE_KEY`
- `CNB_BUILD_JOB_NAME`：当前 Job 的 key 名
- `CNB_PIPELINE_STATUS`：流水线构建状态（`success`/`error`/`cancel`），可在 endStages 中使用
- `CNB_BUILD_FAILED_MSG`：构建失败错误信息，可在 failStages 中使用
- `CNB_TOKEN_USER_NAME`：固定为 `cnb`，配合 `CNB_TOKEN` 用于制品库登录
- `CNB_DOCKER_REGISTRY`：制品库 Docker 源地址
- `CNB_BUILD_WORKSPACE`：工作空间根目录
- `CNB_COMMITTER`：提交者用户名

> **重要**：`CNB_` 前缀为系统保留，禁止自定义同名变量，引用非内置 `CNB_` 变量通常是拼写错误。

---

## 详细参考文档

**按需取用**，一次只读当前场景需要的那篇：

- `references/plugin-search.md`：搜索插件市场、按插件 README 生成插件任务配置（`image`/`settings`/`args`）、插件与脚本任务选型
- `references/syntax-reference.md`：事件列表、Pipeline/Stage/Job 字段、include/!reference、数据卷、部署配置
- `references/builtin-tasks.md`：内置任务参数、支持的事件列表
- `references/env-variables.md`：完整内置变量列表、变量声明/导出/传递规则
- `references/best-practices.md`：配置模式、Monorepo 按需构建、公共模板/!reference 复用、Dockerfile 预装依赖、端到端示例
- `references/diagnose-guide.md`：诊断模式：失败类型判定、性能优化分析
- `references/self-hosted-runner.md`：构建节点选择（`runner.tags`/`cpus`/`namespace`）、平台与架构支持、节点离线/调度失败排查

---

## 校验规则

YAML 语法和 Schema 之外，语义需按以下规则逐条自查：

### 错误（校验不通过）

1. **CNB_ 前缀变量检查** — 禁止自定义/引用非内置 `CNB_` 变量，通常是拼写错误；内置变量全表见 `references/env-variables.md`
2. **内置任务事件限制** — 部分内置任务仅支持特定事件（如 `git:auto-merge` 仅 `pull_request.mergeable`），详见 `references/builtin-tasks.md`
3. **仓库级事件位置** — `issue.*`/`tag_push`/`tag_deploy.*`/`vscode`/`auto_tag` 只能放 `$` 兜底分支下
4. **crontab 事件位置** — 必须放在具体分支名下

### 警告（建议优化）

1. **系统依赖手动安装** — 检测到 `apt install`/`yum install`/`apk add` 时建议改用 `docker.build` Dockerfile 预装
2. **web_trigger / api_trigger 位置** — 建议放在 `$` 兜底分支下

---

## 约束速查

### 语法
- **缩进用空格**：YAML 缩进用空格，不用 Tab；分支名含特殊字符需引号包裹：`"feature/*"`
- **命名合规**：变量值上限 100KiB，变量名只能含字母/数字/下划线且不能数字开头
- **复用分域**：同文件用 YAML 锚点 `&`/`*`（支持 `<<:` 合并）；跨文件用 `!reference`（只引用值）
  - 引用源 key 以 `.` 开头（如 `.docker-config`），两者可混用
  - `!reference` 键名须全局唯一，跨文件共享时加前缀避免冲突（详见 `references/best-practices.md` 第 2 节）

### 语义
- **并发定序**：同事件多 Pipeline 并发；Pipeline 内 Stage 顺序；Stage 内 jobs 数组串行、对象并行
- **密钥就近**：`imports` 作用域 Pipeline 级对全部 stages 生效，Stage 级仅对当前 Stage 生效——仅特定 Stage 需要的密钥在 Stage 级引用

### 安全
- **敏感走 push**：PR 事件 `CNB_TOKEN` 权限受限，敏感操作放 `push`/`pull_request.target`/`tag_push`

### 最佳实践
- **部署防堆积**：`lock: { key: deploy-xxx, wait: true, cancel-in-wait: true }`（`cancel-in-wait` 只保留最新排队流水线）
