#!/bin/bash

# 启动API服务（在后台运行）
cd /app/api
./entrypoint.sh &

# 启动UI服务
cd /app/ui
npm run start
