#!/bin/sh
set -eu

# Infrlo 若注入 PORT，则让 OpenList 监听该端口；
# 未注入时保留 OpenList 默认端口 5244。
if [ -n "${PORT:-}" ]; then
    case "$PORT" in
        ''|*[!0-9]*)
            echo "Invalid PORT: $PORT" >&2
            exit 1
            ;;
        *)
            export HTTP_PORT="$PORT"
            ;;
    esac
fi

echo "Starting OpenList on HTTP_PORT=${HTTP_PORT:-5244}"
exec /opt/openlist/openlist server --no-prefix
