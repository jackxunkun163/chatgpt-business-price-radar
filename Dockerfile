# ---------- 构建阶段 ----------
FROM node:24-alpine AS builder
WORKDIR /app

# 先复制依赖清单，充分利用 Docker 层缓存
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY . .

# 构建时抓取最新真实价格（需访问 chatgpt.com 与汇率接口）；
# 抓取失败时自动回退内置演示数据，保证镜像仍能构建成功。
# 本地网络无法访问 chatgpt.com 时可用 --build-arg COLLECT_PRICES=false 跳过
ARG COLLECT_PRICES=true
RUN if [ "$COLLECT_PRICES" = "true" ]; then \
        node scripts/collect-prices.mjs \
        || echo "[warn] 价格采集失败，镜像将使用内置演示数据"; \
    fi

RUN npm run build

# ---------- 运行阶段 ----------
FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="ChatGPT Business 全球价格雷达"
LABEL org.opencontainers.image.description="查询 ChatGPT Business 全球月付价格（249 地区，原币/USD/CNY，含税口径），并在浏览器本地生成 Team 优惠、Codex 按量与账单查询脚本"
LABEL org.opencontainers.image.source="https://github.com/jackxunkun163/chatgpt-business-price-radar"
LABEL org.opencontainers.image.licenses="MIT"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist/ /usr/share/nginx/html/

EXPOSE 80
