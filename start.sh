#!/bin/sh
# PaaS 常注入 $PORT 并要求应用监听它，而 OpenList 只认 HTTP_PORT
if [ -n "$PORT" ]; then
  export HTTP_PORT="$PORT"
fi
exec ./openlist server --no-prefix
