#!/bin/sh
set -eu

# Orkestr 如果注入 PORT，就让 OpenList 使用该端口。
# 没有 PORT 时使用官方默认端口 5244。
if [ -n "${PORT:-}" ]; then
    export HTTP_PORT="$PORT"
else
    export HTTP_PORT="${HTTP_PORT:-5244}"
fi

# Orkestr PostgreSQL 附加组件会注入 DATABASE_URL。
# OpenList 使用 DB_DSN 接收 PostgreSQL 连接字符串。
if [ -n "${DATABASE_URL:-}" ]; then
    export DB_TYPE="postgres"
    export DB_DSN="$DATABASE_URL"
fi

# 使用临时目录，避免官方镜像检查 /opt/openlist/data 时遇到权限问题。
mkdir -p /tmp/openlist-data
mkdir -p /tmp/openlist-temp
mkdir -p /tmp/openlist-bleve

export TEMP_DIR="/tmp/openlist-temp"
export BLEVE_DIR="/tmp/openlist-bleve"

echo "Starting OpenList on port ${HTTP_PORT}"
echo "Database type: ${DB_TYPE:-sqlite3}"

exec /opt/openlist/openlist \
    server \
    --data /tmp/openlist-data \
    --no-prefix
