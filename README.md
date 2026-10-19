# Business Toolkit

一个独立的 ChatGPT Business 价格与脚本工具箱。价格雷达从 `chatgpt.com` 的公开结账价格配置中读取 `currency_config.business.month`，保留官方原币价格并按公开汇率换算；脚本生成器在浏览器本地生成 Team 优惠、Codex 按量和账单查询脚本。支持 Docker 一键部署（适配 1Panel）。

> 本项目不是 OpenAI 官方产品，与 OpenAI 没有隶属、合作或背书关系。实际价格、税费、付款资格和地区可用性以结账页为准。

| | |
| :-- | :-- |
| 📖 **使用说明** | [docs/usage.md](docs/usage.md) —— 页面总览、四步上手、价格表与三个脚本生成器详解、数据口径、部署与更新、FAQ |
| 🚀 **快速部署** | Docker Hub 镜像 `kunkun66/chatgpt-business-price-radar:latest`，1Panel 编排粘贴即用，见下方[部署章节](#docker-部署) |
| 🔗 **仓库** | [GitHub](https://github.com/jackxunkun163/chatgpt-business-price-radar) · 镜像 [Docker Hub](https://hub.docker.com/r/kunkun66/chatgpt-business-price-radar) / [GHCR](https://github.com/jackxunkun163/chatgpt-business-price-radar/pkgs/container/chatgpt-business-price-radar) |

## 功能

- 探测完整的 ISO 3166-1 alpha-2 国家和地区代码。
- 仅展示标准 ChatGPT Business 月付价格，不包含年付或非营利套餐。
- 显示官方原币价格、人民币/美元估算、含税或未含税口径。
- 支持搜索、筛选、排序以及桌面表格和移动端卡片。
- 从任意地区一键带入国家和货币，生成 ChatGPT Team 结账脚本。
- Team 优惠生成器支持 39 种货币、已有空间 UUID、实时预览、复制和 `.js` 下载。
- Codex 按量生成器支持空间名称、Credit 数量和国家到货币自动匹配。
- 账单查询生成器可查询最近 10 条发票、支付方式和账单资料。
- 优惠码和手动提供的 Token 仅在当前浏览器内处理，不写入网址或本地存储。
- 数据每两天自动刷新（GitHub Actions），结构异常或覆盖率骤降时停止部署。
- 单个地区暂时失败时，最多沿用 14 天的上次成功结果并标记为“数据暂旧”。
- 提供 Docker 镜像（nginx 静态站，约 50MB），一条命令自托管。

## Docker 部署

镜像是纯静态站（Vite 构建产物 + nginx），无数据库、无运行时依赖：

- **Docker Hub（主要）**：`kunkun66/chatgpt-business-price-radar:latest`
- 备用源 GHCR：`ghcr.io/jackxunkun163/chatgpt-business-price-radar:latest`（需将 Package 设为 Public）

直接运行：

```bash
docker run -d --name price-radar --restart unless-stopped \
  -p 8080:80 \
  kunkun66/chatgpt-business-price-radar:latest
```

访问 `http://服务器IP:8080` 即可。

### 1Panel 编排（推荐，无需克隆代码）

1. 打开 1Panel → **容器** → **编排** → **创建编排**：
   - 名称：`price-radar`
   - 来源选择**编辑内容**（或模板编辑），粘贴以下内容：

     ```yaml
     services:
       price-radar:
         image: kunkun66/chatgpt-business-price-radar:latest
         container_name: price-radar
         restart: unless-stopped
         ports:
           - "8080:80"   # 左侧为宿主机端口，可按需修改
     ```

2. 点击**确认**，等待镜像拉取并启动，访问 `http://服务器IP:8080`。

> 也可使用仓库根目录的 `docker-compose.yml`（内容与上面一致）。本站是纯静态站点，无需挂载卷。

### 1Panel 容器界面直接拉镜像

1Panel → **容器** → **容器** → **创建容器**：

- 名称：`price-radar`
- 镜像：`kunkun66/chatgpt-business-price-radar:latest`
- 端口映射：宿主机 `8080` → 容器 `80`

### 从源码构建

```bash
git clone https://github.com/jackxunkun163/chatgpt-business-price-radar.git
cd chatgpt-business-price-radar
docker compose -f docker-compose.build.yml up -d --build
```

构建过程会先抓取一次最新真实价格再打包；若构建机无法访问 `chatgpt.com`（采集自动回退内置演示数据），或想加速构建，可用 `--build-arg COLLECT_PRICES=false` 跳过采集。

### 数据更新方式

- 价格数据在**镜像构建时**抓取并打包进镜像；CI 每两天自动重新构建并推送 `latest`。
- 服务器上更新数据 = 更新镜像：

  ```bash
  docker pull kunkun66/chatgpt-business-price-radar:latest
  docker compose up -d   # 在编排目录执行；1Panel 中可在编排页点「重建」
  ```

- 若显示“本地演示快照”横幅，说明构建时采集失败回退了演示数据，等待下一次 CI 重建即可。

### 建议的配套设置

- **域名 + HTTPS**：1Panel → **网站** → **创建网站** → **反向代理**，代理到 `http://127.0.0.1:8080`，再申请 Let's Encrypt 证书。
- **防火墙**：1Panel → **主机** → **防火墙** 放行对应端口（使用反向代理时可只放行 80/443）。

## 项目结构

```
├── src/                        # React + TypeScript 前端源码
│   ├── App.tsx                 # 价格雷达页（搜索/筛选/排序/币种切换）
│   ├── CheckoutGenerator.tsx   # 脚本生成器页（三个工具）
│   └── checkout-generator.ts / script-generators.ts / lib.ts
├── scripts/collect-prices.mjs  # 价格采集器（249 地区 + 汇率换算）
├── public/data/                # sample-prices.json 演示数据；prices.json 为采集产物
├── tests/                      # 测试
├── .github/workflows/
│   ├── ci.yml                  # PR / 非 main 分支：测试 + 类型检查 + 构建
│   ├── pages.yml               # 每 2 天采集价格并发布 GitHub Pages
│   └── docker-publish.yml      # 构建多架构 Docker 镜像，双推 Docker Hub + GHCR
├── docs/usage.md               # 使用说明（功能详解 / 示例 / FAQ）
├── Dockerfile                  # 多阶段构建：node 构建产物 → nginx 运行
├── nginx.conf                  # 容器内 nginx 配置（缓存策略 / gzip）
├── docker-compose.yml          # 拉取镜像部署（1Panel 粘贴即用）
└── docker-compose.build.yml    # 从源码构建部署
```

## 本地开发

需要 Node.js 22 或更高版本，推荐 Node.js 24 LTS。

```bash
npm install
npm run dev
```

本地首次打开会使用 `public/data/sample-prices.json` 演示数据。获取真实数据：

```bash
npm run collect
npm run dev
```

生成的 `public/data/prices.json` 已加入 `.gitignore`，不会提交到仓库。

常用检查：

```bash
npm test
npm run typecheck
npm run build
```

## 数据采集规则

采集器位于 `scripts/collect-prices.mjs`：

1. 遍历 249 个 ISO 国家/地区代码。
2. 请求 `https://chatgpt.com/backend-anon/checkout_pricing_config/configs/{CODE}`。
3. 校验返回地区、币种和 `business.month.amount/tax`。
4. 以 Frankfurter 为主要汇率源；未覆盖币种由 `open.er-api.com` 补齐。
5. 通过美元中间价换算：`USD = 本币金额 ÷ USD→本币汇率`，`CNY = USD × USD→CNY汇率`。
6. 不自行加税，只展示接口提供的税务口径。

采集请求不使用 Cookie、设备 ID、会话 ID、登录凭据或浏览器指纹头。

## 脚本生成器

顶部导航可切换到脚本生成器，也可以从价格表或移动端价格卡片直接进入 Team 优惠工具。生成器内部通过 `tool=checkout|codex|billing` 切换工具；地区入口会预填国家和货币，优惠码、Token 和空间信息不会出现在网址中。

Team 优惠生成器默认使用 `US / EGP`、月付、两个席位和工作区名称 `xxx`；空间 UUID 留空时创建新空间。Codex 按量生成器默认使用空间名称 `work`、`13` Credit 和美国地区。

三个工具都支持在脚本运行时从登录 Session 自动获取 Access Token，也可以手动粘贴原始 `accessToken` 或 `/api/auth/session` 返回的完整 JSON；完整 JSON 只会提取其中的 `accessToken` 写入脚本。切回自动获取时，手动输入会立即清空。

生成器只生成文本，不会在本站请求登录凭证、支付或账单接口，也不会代替用户执行代码。账单结果可能包含敏感付款资料，请勿分享控制台输出。请仅在有权操作的账号中使用，并以实际 ChatGPT 页面结果为准。

### 发布保护

- 首次快照必须包含新鲜的 US、至少一个非 USD 地区、CNY 汇率和至少 20 个有效地区。
- 后续快照总行数不得低于上一线上快照的 90%。
- 任何保护条件失败时，Action 直接失败，不会覆盖当前线上版本。

可通过环境变量调整：

- `PREVIOUS_SNAPSHOT_URL`：上一线上快照地址。
- `PREVIOUS_SNAPSHOT_PATH`：本地上一快照路径。
- `MIN_FIRST_RUN_ROWS`：首次部署最少行数，默认 `20`。
- `OUTPUT_PATH`：输出文件，默认 `public/data/prices.json`。

## 发布到 Docker Hub / GHCR

CI（`.github/workflows/docker-publish.yml`）在每次 push 到 `main`、打 `v*` 标签、手动运行以及**每两天定时**（重新采集价格）时构建 `linux/amd64` + `linux/arm64` 镜像并推送：

- **GHCR**：`ghcr.io/jackxunkun163/chatgpt-business-price-radar`（使用内置 `GITHUB_TOKEN`，默认私有，可在 Package settings 改为 Public）
- **Docker Hub**：`kunkun66/chatgpt-business-price-radar`（需在仓库 **Settings → Secrets and variables → Actions** 添加 `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN`，与 [vps-value-calculator](https://github.com/jackxunkun163/vps-value-calculator) 仓库中使用的相同）

> 在 Secrets 配置完成之前，Docker Hub 侧由 vps-value-calculator 仓库的 `radar-docker-hub` 工作流代为构建推送；配置后即可由本仓库独立双推，该代构建工作流可删除。

## GitHub Pages 发布

1. 新建 GitHub 仓库并推送本目录内容，默认分支命名为 `main`。
2. 打开仓库 **Settings → Pages**。
3. 在 **Build and deployment → Source** 中选择 **GitHub Actions**。
4. 打开 **Actions → Refresh prices and deploy Pages → Run workflow**，执行首次手动刷新。
5. 首次成功后，网站会发布到仓库对应的 GitHub Pages 地址。

工作流还会在北京时间每天 03:17 唤醒，通过日期门控每两天真正刷新一次；主分支推送和手动运行会立即刷新。

GitHub 可能在公开仓库连续 60 天没有活动后停用定时工作流。本项目按约定不创建保活提交；如被停用，请在 Actions 页面手动重新启用并运行一次。

## 环境要求（Docker 部署）

- Docker 20.10+ / Docker Compose v2（1Panel 自带）
- 磁盘约 100MB（镜像约 50MB）
- 无需出网访问 `chatgpt.com`（价格数据已打包在镜像内；仅构建镜像时需要）

## 计费与免责声明

ChatGPT Business 按标准席位计费，通常至少需要两个标准席位。本站表格显示的是接口返回的**每用户月价**，不代表两席位总账单。企业税号、VAT/GST、反向征税、发卡行汇率和手续费都可能改变最终金额。

- [OpenAI Business 官方价格页](https://openai.com/business/pricing/)
- [OpenAI Business 账单与席位说明](https://help.openai.com/en/articles/8792536)

## 授权与归属

代码采用 [MIT License](LICENSE)。

ChatGPT 与 OpenAI 是其各自权利人的商标。本项目仅作描述性使用。项目受到 PriceAI 信息架构的启发，但没有复制 PriceAI 的代码、品牌、素材、价格快照或线上数据；详见 [NOTICE.md](NOTICE.md)。
