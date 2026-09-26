#!/bin/bash

echo "========================================"
echo "Clean old OTA progress (avoid residue)"
echo "========================================"
# 清空旧状态（关键）
rm -rf /data/ota/progress
mkdir -p /data/ota/progress

echo "========================================"
echo "Deploy OTA service..."
echo "========================================"
# 创建目录
mkdir -p /data/ota/service

# 复制 service 文件
cp -f /data/ota/ota-upgrade-ab.service /data/ota/service/

# 建立 systemd 链接
systemctl link /data/ota/service/ota-upgrade-ab.service

# 启用并启动
systemctl enable ota-upgrade-ab.service
systemctl start ota-upgrade-ab.service &

echo "========================================"
echo "OTA service deploy SUCCESS!"
echo "========================================"
