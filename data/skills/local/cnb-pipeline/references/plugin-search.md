# 插件任务：搜索与配置生成

CNB 插件即「封装好的 Docker 镜像 + `settings` 参数接口」，能覆盖绝大多数 CI/CD 场景。本文件是配置工作流程「插件查证」一步的展开：**先搜市场插件，再按插件 README 生成 `image` + `settings`**。

## 何时必须搜插件

以下场景**必须先搜索插件市场**，不要直接手写脚本：

- **消息通知**：向 IM 群聊或 Webhook 推送构建状态、结果通知
- **代码质量**：lint、格式化、AI 评审，或检查 commit/PR 规范
- **构建与打包**：构建/合并 Docker 镜像，或使用市场现成的构建工具插件（Maven、Gradle、Kaniko 等；一般代码构建测试优先脚本任务，见下方「插件任务 vs 脚本任务」）
- **发布与版本**：自动打 tag、生成 changelog、语义化发布
- **部署与运维**：部署到容器平台/Serverless/边缘节点，或执行 SSH/kubectl 命令
- **安全与扫描**：依赖漏洞扫描、安全审计
- **Git 协作**：自动化创建 PR 或管理 Git 操作
- **文件与存储**：上传/下载 COS 文件、替换环境变量
- **微信小程序 CI**：微信小程序 CI 构建上传

> **核心规则**：
> - **形状定死**：用插件 `image` + `settings` 生成配置。
> - **脚本兜底**：仅确认无匹配插件或需求极简时，才 fallback 到 script 手写方案。
> - **参数查证**：插件具体用法（`settings` 参数名、类型、必填性）以插件 README 为准，**禁止凭记忆生成**——同名插件不同版本参数可能不同，凭记忆极易编错。

## 插件任务 vs 脚本任务

流水线 `Job` 分脚本任务、插件任务、内置任务三类（内置任务见 `builtin-tasks.md`）。按官方文档 `/zh/build/script-vs-plugin.md`：代码构建和测试、与业务强相关的自定义逻辑用脚本任务；通知、发布部署、代码质量检查等有现成插件的通用操作用插件任务。

- **执行方式**：脚本任务用 `script`/`commands`；插件任务运行镜像内置 `ENTRYPOINT`
- **参数通道**：脚本任务用 `env`/`imports`；插件任务用 `settings`
- **变量显式引用**：插件任务**不传递** `env`/`imports` 变量，须在 `settings`/`args` 中用 `$VAR` 引用（详见下方「生成配置」）

## 模式判定

- **搜索模式**（用户描述需求但未指定插件）→ 走下方「搜索工作流程」
- **直选模式**（用户已明确指定插件名）→ 跳过搜索，直接走「获取插件文档 → 生成配置」

## 搜索工作流程

### 1. 搜索插件市场

**默认数据源**（CNB SaaS 插件市场）：
```
URL: ${CNB_WEB_PROTOCOL:-https}://${CNB_WEB_HOST:-cnb.cool}/cnb/plugins/market/-/git/raw/main/plugins/plugins.json
提示：从插件列表中找出与"{用户需求关键词}"最相关的插件，返回 id、name、description、tags、readme、images、source，按相关性排序，列出 Top 5
```

> **私有化 / 自定义数据源**：若无法获取 SaaS 数据源（私有化部署或自建市场），可请用户提供 `plugins.json` 内容（格式与 SaaS 一致）或数据源 URL。

每个插件条目结构（以 wecom-message 为例）：
```json
{
  "id": "tencentcom/wecom-message",
  "name": "wecom-message",
  "description": "企业微信群里发消息的插件，通过机器人，可以向固定的群中推送消息。",
  "tags": ["企业微信", "WeCom", "消息"],
  "mark": "",
  "images": "https://hub.docker.com/r/tencentcom/wecom-message/tags",
  "source": "${CNB_WEB_PROTOCOL:-https}://${CNB_WEB_HOST:-cnb.cool}/cnb/plugins/tencentcom/wecom-message",
  "bugs": "${CNB_WEB_PROTOCOL:-https}://${CNB_WEB_HOST:-cnb.cool}/cnb/plugins/tencentcom/wecom-message/-/issues",
  "logo": "logo.png",
  "readme": "${CNB_WEB_PROTOCOL:-https}://${CNB_WEB_HOST:-cnb.cool}/cnb/plugins/market/-/git/raw/main/plugins/tencentcom/wecom-message/README.md"
}
```

`mark` 为角标：`official`(官方) / `private`(特定组织) / 空(社区)。

### 2. 推荐确认

向用户展示 Top 3-5 匹配结果（名称、描述、标签、镜像），给出推荐并让用户确认或改选。

### 3. 获取插件文档

确认插件后，读取条目 `readme` 字段指向的 README（市场仓库中缓存的 raw 地址）：

```
URL: <插件 readme URL>
提示：提取使用说明，重点关注 settings 参数列表、每个参数的类型和含义、使用示例中的 .cnb.yml 配置片段
```

> **README 缺失或信息不足时**，依次回退：`source` 源码仓库 README → Docker Hub 镜像页（`images` 字段）→ 用 `cnb-docs` skill 查官方文档。仍无法确认参数时，如实告知用户，只给带占位符的示例配置并注明需查证。

### 4. 生成配置

**生成规则**：

- `image` — 从 `images` 字段提取 Docker 镜像名（不带 tag，使用默认 `latest`）。常见格式：
  - `https://hub.docker.com/r/<org>/<name>/tags` → `<org>/<name>`
  - `https://hub.docker.com/repository/docker/<org>/<name>/tags` → `<org>/<name>`
  - `docker.cnb.cool/.../<name>` → 完整路径
  - 其他格式以 `images` 值中能识别的镜像标识为准，不确定时查看插件 README 确认
  - 如需固定版本在镜像名后加 `:<版本>`（如 `tencentcom/npm:1.2.3`）
- `settings` — 按文档参数表填写，**参数名保持小写**（CI 自动转为 `PLUGIN_` + 大写前缀传入插件；编写时无需关心此转换）
- `args` — 插件支持命令行参数时可用 `args:` 数组传递（追加到 ENTRYPOINT，等同 `docker run <image> <args...>`）；大部分 CNB 插件优先用 `settings`
- **变量引用机制（核心）**：`env`/`imports` 声明的变量**不会直接传入**插件，须在 `settings` 或 `args` 中用 `$VAR` 引用，`settings` 即参数白名单；系统内置变量（如 `CNB_REPO_SLUG`）始终传入
- **变量声明**：`$VAR` 的 `VAR` 必须是 `env` 或 `imports` 中真实声明的变量名；敏感值放密钥仓库，用 `imports` 引入（见 `env-variables.md`「声明和导入」）

**配置模板**：

```yaml
main:
  push:
    - imports:
        - https://cnb.cool/<org>/<secret-repo>/-/blob/main/secrets.yml  # 声明 MY_TOKEN
      stages:
        - name: <任务名>
          image: <镜像名>    # 不带 tag 使用 latest
          settings:
            <参数>: <值>
            <参数>: $MY_TOKEN   # MY_TOKEN 必须是 imports 或 env 中声明的变量名
```

## 常见场景速查

以下为高频需求与推荐插件的快速参考（**基于当前市场快照，完整列表以 `plugins.json` 为准**）：

**通知**
- 发企业微信通知 → wecom-message（`tencentcom/wecom-message`）
- 发飞书通知 → feishu-message（`tencentcom/feishu-message`）
- 发钉钉通知 → dingtalk-bot-msg（`tencentcom/dingtalk-bot-msg`）
- Webhook 通知 → webhook（`cnbcool/webhook`）

**代码质量**
- AI 代码评审 → code-review（`cnbcool/code-review`）
- Commit 规范检查 → commitlint（`cnbcool/commitlint`）
- PR 标题规范检查 → git-pr-title-lint（`cnbcool/git-pr-title-lint`）
- PR 变更量检查 → git-pr-limit（`cnbcool/git-pr-limit`）

**构建与发布**
- 发布 npm 包 → npm（`tencentcom/npm`）
- Maven 构建 → maven（`tencentcom/maven`）
- Gradle 构建 → gradle（`tencentcom/gradle`）
- 生成 changelog → changelog（`cnbcool/changelog`）
- Semantic Release → semantic-release（`tencentcom/semantic-release`）
- 多架构镜像合并 → manifest（`cnbcool/manifest`）
- 微信小程序 CI → miniprogram-ci（`tencentcom/miniprogram-ci`）

**部署**
- 部署到 TKE → deploy-to-tke（`tencentcom/deploy-to-tke`）
- 部署到 SCF → scf（`tencentcom/tencentyun-scf`）
- 部署 EdgeOne Pages → deploy-eopages（`tencentcom/deploy-eopages`）
- Kaniko 构建镜像 → kaniko（`banzaicloud/drone-kaniko`）
- kubectl 操作 → kubectl（`alpine/kubectl`）
- Terraform 部署 → terraform（`jmccann/drone-terraform`）

**Git & 协作**
- 自动打 tag → git-auto-tag（`cnbcool/git-auto-tag`）
- 创建 PR → create-pr（`cnbcool/create-pr`）
- SSH 远程执行 → ssh（`cnbcool/ssh`）

**文件与工具**
- 上传下载 COS → coscli（`tencentcom/coscli`）
- 环境变量替换 → envsubst（`tencentcom/envsubst`）

> **注**：open-source 类插件多为命令行工具镜像，使用时**可能需配合 `args:`** 传参（参考上方「生成配置」）。完整列表走[搜索工作流程](#搜索工作流程)。

## 无匹配时

如实告知，插件即 Docker 镜像，可引导用户：
- 去 Docker Hub 等镜像源找满足需求的镜像，直接在流水线中作插件使用
- 自行编写插件：插件写法规范见官方文档 `${CNB_WEB_PROTOCOL:-https}://docs.${CNB_WEB_HOST:-cnb.cool}/zh/build/create-plugin.md`（参数设计、Dockerfile、导出变量、发布流程）
- 贡献到市场：官方文档 `${CNB_WEB_PROTOCOL:-https}://docs.${CNB_WEB_HOST:-cnb.cool}/zh/build/contribute-plugin.md`，市场入口 `${CNB_WEB_PROTOCOL:-https}://${CNB_WEB_HOST:-cnb.cool}/cnb/plugins/market?tabValue=CONTRIBUTING-ov-file`
