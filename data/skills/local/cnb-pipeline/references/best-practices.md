# CNB 流水线最佳实践

> 各节只讲模式选型与骨架，字段细节按需查 `syntax-reference.md`，锚点与 `!reference` 的规则见其中「Include 和 !reference」。

## 1. 跨文件拆分：`.ci/` 目录

配置超过 150 行时，按「功能 + 触发事件」拆分：

```
.cnb.yml                    # 仅 include 列表
.ci/
├── .shared-config.yml      # 公共配置（Docker 环境、Go 环境、Node 安装等）
├── .variables.yml          # 全局变量（webhook robot ID 等）
├── .docker-build.yml       # Docker 镜像构建
├── .pr.yml                 # PR 检查
├── .push-deploy-dev.yml    # push → dev 部署
├── .deploy.yml             # 生产/staging 部署
├── .tag-push.yml           # tag 发版
└── .e2e-test.yml           # E2E 测试
```

公共片段（Docker 环境、环境变量、Stage 片段、robot ID 等常量）放在 `.shared-config.yml`/`.variables.yml` 中以 `.` 开头的 key 下，业务文件用 `!reference` 引用；同文件内的模板继承用锚点。

---

## 2. Monorepo 大仓按需构建

通过 `ifModify` + `CNB_PIPELINE_KEY` + `cnb:resolve`/`cnb:await` 实现**按需构建 + 编排部署**。模板靠 `CNB_PIPELINE_KEY` 取模块名，流水线须写成对象形式（数组形式下它是自动索引，如 `pipeline-0`）。

> **参考文档**：https://docs.cnb.cool/zh/build/showcase/monorepo.html

### 2.1 模板 + 批量映射

定义一个构建模板，用 `${CNB_PIPELINE_KEY}` 动态引用模块名，然后在分支触发处用 key 名批量展开：

```yaml
# 构建模板 — CNB_PIPELINE_KEY 运行时自动替换为流水线 key 名
.build-module: &build-module
  services:
    - docker
  ifModify:
    - packages/${CNB_PIPELINE_KEY}/**    # 仅该模块目录有变更时触发
  stages:
    - name: build
      script: cd packages/${CNB_PIPELINE_KEY} && docker build -t $IMAGE_TAG .
    - name: push
      script: docker push $IMAGE_TAG
    - name: resolve
      type: cnb:resolve
      options:
        key: build-${CNB_PIPELINE_KEY}   # 发出完成信号

# 分支触发 — 每个 key 就是一个模块，CNB_PIPELINE_KEY 自动等于 key 名
main:
  push:
    user-service: *build-module          # CNB_PIPELINE_KEY = "user-service"
    order-service: *build-module         # CNB_PIPELINE_KEY = "order-service"
    gateway: *build-module               # CNB_PIPELINE_KEY = "gateway"
```

> **新增模块只需加一行** `new-module: *build-module`。

### 2.2 部署编排：await 等待所有模块构建完成

部署流水线用 `cnb:await` 等待所有模块构建就绪后再统一部署。模块带 `ifModify` 时，按 2.3 的方式只 await 有变更的模块。

```yaml
# await 模板（锚点复用）
.await-module: &await-module
  type: cnb:await
  options:
    key: build-${CNB_BUILD_JOB_NAME}         # CNB_BUILD_JOB_NAME = job 的 key 名

main:
  push:
    deploy:
      lock:
        key: deploy-dev
        wait: true
        cancel-in-wait: true
      stages:
        - name: await all modules
          jobs:
            frontend: *await-module          # 等待 frontend 构建完成
            backend: *await-module
            gateway: *await-module
        - name: deploy
          script: ./deploy.sh
```

### 2.3 PR 检查：ifModify + cnb:await 按需等待

PR 检查流水线中，各模块独立检查并 `resolve`，汇总流水线只 `await` 有变更的模块：

```yaml
"**":
  pull_request:
    # 各模块独立检查（并发执行）
    golang-lint:
      ifModify: &go-files
        - "**/*.go"
        - "**/go.mod"
      stages:
        - name: lint
          script: golangci-lint run ./...
        - name: resolve
          type: cnb:resolve
          options:
            key: golang-check

    frontend-lint:
      ifModify: &frontend-files
        - frontend/**
      stages:
        - name: lint
          script: cd frontend && npm run lint
        - name: resolve
          type: cnb:resolve
          options:
            key: frontend-check

    # 汇总流水线 — 只 await 有变更的模块
    summary:
      stages:
        - name: await golang
          type: cnb:await
          ifModify: *go-files               # 仅 Go 文件有变更时才等待
          options:
            key: golang-check
        - name: await frontend
          type: cnb:await
          ifModify: *frontend-files         # 仅前端文件有变更时才等待
          options:
            key: frontend-check
```

> **关键技巧**：`cnb:await` 的 `ifModify` 使用锚点引用对应模块的路径匹配规则，确保只等待有变更的模块。

---

## 3. 跨仓库公共模板：通用流程复用 + 业务变量分离

当多个业务仓库共享相同的构建部署流程（如 docker build → push → deploy TKE），可将通用流程封装到**公共模板仓库**，各业务仓库只需声明自己的变量即可。

### 3.1 公共模板仓库

模板中只写通用流程逻辑，所有业务差异通过**环境变量**注入：

```yaml
# org/template/build-deploy/build-deploy.yml

.build-and-deploy:
  services:
    - docker
  imports:
    # 密钥仓库（制品库凭证、kubeconfig 等）
    - https://cnb.cool/<org>/<secret-repo>/-/blob/main/secret.yml
    # 业务仓库本地的变量配置文件（通过 $CNB_PIPELINE_KEY 动态匹配）
    - .cnb/workload_env.$CNB_PIPELINE_KEY.yml
  stages:
    - name: build image
      script: |
        docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD" ${IMAGE_DOMAIN}
        docker build -f ${DOCKERFILE:-Dockerfile} -t ${IMAGE}:${CNB_COMMIT_SHORT} ${CONTEXT_PATH:-.}
        docker push ${IMAGE}:${CNB_COMMIT_SHORT}
    - name: deploy
      image: bitnami/kubectl
      script: |
        echo "$KUBECONFIG_DATA" > ~/.kube/config
        kubectl set image ${WORKLOAD_TYPE}/${NAME} ${CONTAINER}=${IMAGE}:${CNB_COMMIT_SHORT} -n ${NS}
```

> **关键**：`imports: .cnb/workload_env.$CNB_PIPELINE_KEY.yml` — 模板通过 `$CNB_PIPELINE_KEY` 动态加载业务仓库中对应流水线 key 的配置文件，实现一套模板支持多条流水线。

### 3.2 业务仓库

业务仓库只需 `include` 远程模板 + 声明自己的变量：

```yaml
# 业务仓库 .cnb.yml — 跨文件必须用 !reference，不能用 YAML 锚点
include:
  - https://cnb.cool/<org>/template/build-deploy/-/blob/main/build-deploy.yml

main:
  push:
    service-a: !reference [.build-and-deploy]   # CNB_PIPELINE_KEY = "service-a"
    service-b: !reference [.build-and-deploy]   # CNB_PIPELINE_KEY = "service-b"
```

```yaml
# 业务仓库 .cnb/workload_env.service-a.yml（环境变量声明）
IMAGE_DOMAIN: registry.example.com
IMAGE: registry.example.com/myteam/service-a
WORKLOAD_TYPE: deployment
NAME: service-a
CONTAINER: service-a
NS: production
DOCKERFILE: Dockerfile
CONTEXT_PATH: .
```

---

## 4. 多架构镜像构建（amd64 + arm64）

通过 `runner.tags` 指定不同架构的构建节点，配合 `cnb:resolve`/`cnb:await` 编排，最后用 manifest 插件合并多架构镜像：

```yaml
# 构建步骤模板
.build-by-arch: &build-by-arch
  - name: docker build & push
    script:
      - docker build -t $IMAGE:$VERSION-linux-$BUILD_ARCH .
      - docker push $IMAGE:$VERSION-linux-$BUILD_ARCH
  - name: resolve
    type: cnb:resolve
    options:
      key: build-$BUILD_ARCH

main:
  push:
    - name: build-amd64                # 与 build-arm64 并发构建
      runner:
        tags: cnb:arch:amd64
      services:
        - docker
      env:
        BUILD_ARCH: amd64
      stages: *build-by-arch
    - name: build-arm64
      runner:
        tags: cnb:arch:arm64:v8
      services:
        - docker
      env:
        BUILD_ARCH: arm64
      stages: *build-by-arch
    - name: combine-arch
      services:
        - docker
      stages:
        - name: await amd64
          type: cnb:await
          options:
            key: build-amd64
        - name: await arm64
          type: cnb:await
          options:
            key: build-arm64
        - name: manifest               # 合并多架构镜像
          image: cnbcool/manifest
          settings:
            target: $IMAGE:$VERSION
            template: $IMAGE:$VERSION-OS-ARCH
            platforms:
              - linux/amd64
              - linux/arm64
```
