#!/bin/sh
set -eu

# ---------- 端口 ----------
# Orkestr 若注入 PORT 则使用；否则用 OpenList 默认 5244
if [ -n "${PORT:-}" ]; then
    HTTP_PORT_VALUE="$PORT"
else
    HTTP_PORT_VALUE="${HTTP_PORT:-5244}"
fi

# ---------- 数据目录 ----------
# 放 /tmp 避开 openlist 用户对 /opt/openlist/data 的权限问题
mkdir -p /tmp/openlist-data
mkdir -p /tmp/openlist-data/log
mkdir -p /tmp/openlist-temp
mkdir -p /tmp/openlist-bleve

# ---------- jwt_secret ----------
# 固定密钥：环境变量优先，未设则用写死默认值
# 注意：一旦部署就不要再改，改了所有旧签名和登录会话全部失效
JWT_SECRET_VALUE="${JWT_SECRET:-OpL1st2026xK9mQw7vBn3ZrTc5HjE8sY}"

# ---------- site_url ----------
# 环境变量 SITE_URL=https://openlist.orkestr.run（结尾不要带 /）
SITE_URL_VALUE="${SITE_URL:-}"

# ---------- 生成配置文件 ----------
cat > /tmp/openlist-data/config.json <<EOF
{
  "force": false,
  "site_url": "${SITE_URL_VALUE}",
  "jwt_secret": "${JWT_SECRET_VALUE}",
  "token_expires_in": 48,
  "database": {
    "type": "sqlite3",
    "host": "",
    "port": 0,
    "user": "",
    "password": "",
    "name": "",
    "db_file": "/tmp/openlist-data/data.db",
    "table_prefix": "x_",
    "ssl_mode": "",
    "dsn": ""
  },
  "scheme": {
    "address": "0.0.0.0",
    "http_port": ${HTTP_PORT_VALUE},
    "https_port": -1,
    "force_https": false,
    "cert_file": "",
    "key_file": "",
    "unix_file": "",
    "unix_file_perm": "",
    "enable_h2c": false
  },
  "temp_dir": "/tmp/openlist-temp",
  "bleve_dir": "/tmp/openlist-bleve",
  "dist_dir": "",
  "log": {
    "enable": true,
    "name": "/tmp/openlist-data/log/log.log",
    "max_size": 5,
    "max_backups": 1,
    "max_age": 1,
    "compress": false,
    "filter": {
      "enable": false,
      "filters": []
    }
  },
  "delayed_start": 0,
  "max_connections": 0,
  "max_concurrency": 16,
  "tls_insecure_skip_verify": true,
  "tasks": {
    "download": {
      "workers": 5,
      "max_retry": 1,
      "task_persistant": false
    },
    "transfer": {
      "workers": 5,
      "max_retry": 2,
      "task_persistant": false
    },
    "upload": {
      "workers": 5,
      "max_retry": 0,
      "task_persistant": false
    },
    "copy": {
      "workers": 5,
      "max_retry": 2,
      "task_persistant": false
    },
    "move": {
      "workers": 5,
      "max_retry": 2,
      "task_persistant": false
    },
    "decompress": {
      "workers": 5,
      "max_retry": 2,
      "task_persistant": false
    },
    "decompress_upload": {
      "workers": 5,
      "max_retry": 2,
      "task_persistant": false
    },
    "allow_retry_canceled": false
  },
  "cors": {
    "allow_origins": ["*"],
    "allow_methods": ["*"],
    "allow_headers": ["*"]
  },
  "s3": {
    "enable": false,
    "port": 5246,
    "ssl": false
  },
  "ftp": {
    "enable": false
  },
  "sftp": {
    "enable": false
  },
  "mcp": {
    "enable": false
  },
  "last_launched_version": "",
  "proxy_address": ""
}
EOF

# ---------- 启动信息 ----------
echo "=== OpenList start ==="
echo "PORT=${HTTP_PORT_VALUE}"
echo "SITE_URL=${SITE_URL_VALUE:-<empty>}"
echo "jwt_secret: fixed"
echo "database: sqlite3 (ephemeral /tmp)"
echo "======================"

# ---------- 启动 ----------
exec /opt/openlist/openlist server \
    --data /tmp/openlist-data \
    --config /tmp/openlist-data/config.json \
    --log-std \
    --no-prefix
