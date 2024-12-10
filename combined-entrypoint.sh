#!/bin/bash

# 启动API服务（在后台运行）
cd /app/api
npm run start &

# 启动UI服务
cd /app/ui
npm run start
