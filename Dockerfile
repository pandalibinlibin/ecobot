########################  1. 构建前端  ########################
FROM node:18.12.0-alpine3.16 AS web

WORKDIR /opt/vue-fastapi-admin/web
# 先拷包管理文件，利用缓存
COPY web/package*.json ./
RUN npm ci

# 再拷源码并构建
COPY web/ ./
RUN npm run build          # 这一步会生成 dist 目录

########################  2. 运行环境  ########################
FROM python:3.11-slim-bullseye

WORKDIR /opt/vue-fastapi-admin

# 系统依赖
RUN --mount=type=cache,target=/var/cache/apt \
    sed -i 's@http://.*.debian.org@http://mirrors.ustc.edu.cn@g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends gcc python3-dev bash nginx curl && \
    rm -rf /var/lib/apt/lists/*

# Python 依赖
COPY requirements.txt ./
RUN pip install -r requirements.txt -i https://pypi.org/simple

# 拷后端代码
COPY . .

# 拷前端构建产物
COPY --from=web /opt/vue-fastapi-admin/web/dist ./web/dist

# Nginx 配置
COPY deploy/web.conf /etc/nginx/sites-available/web.conf
RUN ln -sf /etc/nginx/sites-available/web.conf /etc/nginx/sites-enabled/web.conf \
 && rm -f /etc/nginx/sites-enabled/default

EXPOSE 80
ENTRYPOINT ["sh", "deploy/entrypoint.sh"]