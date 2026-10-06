#!/bin/sh
set -eu

# 端口
if [ -n "${PORT:-}" ]; then
    export HTTP_PORT="$PORT"
else
    export HTTP_PORT="${HTTP_PORT:-5244}"
fi

# 手写配置文件，绕开 DSN 解析问题
mkdir -p /tmp/openlist-data
mkdir -p /tmp/openlist-temp
mkdir -p /tmp/openlist-bleve

# 从 DATABASE_URL 中提取各字段
DB_TYPE_VALUE="sqlite3"
DB_HOST_VALUE=""
DB_PORT_VALUE="5432"
DB_USER_VALUE=""
DB_PASS_VALUE=""
DB_NAME_VALUE=""
DB_SSL_VALUE="disable"

if [ -n "${DATABASE_URL:-}" ]; then
    DB_TYPE_VALUE="postgres"

    # 按 URL 结构解析: scheme://user:pass@host:port/dbname?params
    REST="${DATABASE_URL#*://}"          # user:pass@host:port/dbname?params
    CRED="${REST%%@*}"                   # user:pass
    HOSTPART="${REST#*@}"                # host:port/dbname?params

    DB_USER_VALUE="${CRED%%:*}"
    DB_PASS_VALUE="${CRED#*:}"

    HOSTPORT="${HOSTPART%%/*}"           # host:port
    DBPART="${HOSTPART#*/}"              # dbname?params

    case "$HOSTPORT" in
        *:*)
            DB_HOST_VALUE="${HOSTPORT%:*}"
            DB_PORT_VALUE="${HOSTPORT##*:}"
            ;;
        *)
            DB_HOST_VALUE="$HOSTPORT"
            DB_PORT_VALUE="5432"
            ;;
    esac

    DB_NAME_VALUE="${DBPART%%\?*}"

    # 处理 sslmode
    case "$DATABASE_URL" in
        *sslmode=require*) DB_SSL_VALUE="require" ;;
        *sslmode=disable*) DB_SSL_VALUE="disable" ;;
        *) DB_SSL_VALUE="require" ;;
    esac
fi

cat > /tmp/openlist-data/config.json <<EOF
{
  "force": false,
  "site_url": "${SITE_URL:-}",
  "jwt_secret": "${JWT_SECRET:-infrlo-orkestr-openlist-please-change}",
  "database": {
    "type": "${DB_TYPE_VALUE}",
    "host": "${DB_HOST_VALUE}",
    "port": ${DB_PORT_VALUE},
    "user": "${DB_USER_VALUE}",
    "password": "${DB_PASS_VALUE}",
    "name": "${DB_NAME_VALUE}",
    "db_file": "/tmp/openlist-data/data.db",
    "table_prefix": "x_",
    "ssl_mode": "${DB_SSL_VALUE}",
    "dsn": ""
  },
  "scheme": {
    "address": "0.0.0.0",
    "http_port": ${HTTP_PORT},
    "https_port": -1,
    "force_https": false
  },
  "temp_dir": "/tmp/openlist-temp",
  "bleve_dir": "/tmp/openlist-bleve",
  "log": {
    "enable": true,
    "name": "/tmp/openlist-data/log/log.log",
    "max_size": 5,
    "max_backups": 1,
    "max_age": 1,
    "compress": false,
    "filter": { "enable": false, "filters": [] }
  },
  "max_concurrency": 16,
  "tls_insecure_skip_verify": true
}
EOF

echo "=== OpenList start ==="
echo "PORT=${HTTP_PORT}"
echo "DB_TYPE=${DB_TYPE_VALUE}"
echo "DB_HOST=${DB_HOST_VALUE}"
echo "DB_PORT=${DB_PORT_VALUE}"
echo "DB_NAME=${DB_NAME_VALUE}"
echo "======================"

exec /opt/openlist/openlist server \
    --data /tmp/openlist-data \
    --config /tmp/openlist-data/config.json \
    --log-std \
    --no-prefix
