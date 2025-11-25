#!/bin/bash

# 快速部署 WebSocket 数据流卡住修复
# 适用于服务器环境

set -e

echo "=========================================="
echo "🚀 快速部署 WebSocket 数据流修复"
echo "=========================================="
echo ""

# 检查是否在服务器上
if [ ! -f "main.go" ]; then
    echo "❌ 错误：请在项目根目录执行此脚本"
    exit 1
fi

# 1. 备份当前版本
echo "📦 备份当前版本..."
if [ -f "nofx" ]; then
    cp nofx nofx.backup.$(date +%Y%m%d_%H%M%S)
    echo "✓ 已备份到 nofx.backup.$(date +%Y%m%d_%H%M%S)"
fi
echo ""

# 2. 编译新版本
echo "🔨 编译新版本..."
go build -o nofx main.go
if [ $? -ne 0 ]; then
    echo "❌ 编译失败"
    exit 1
fi
echo "✓ 编译成功"
echo ""

# 3. 停止旧进程（保存PID用于验证）
echo "⏹ 停止旧进程..."
OLD_PID=$(pgrep -f "./nofx" || echo "")
if [ -n "$OLD_PID" ]; then
    kill $OLD_PID
    sleep 3
    # 强制杀死（如果还在运行）
    if ps -p $OLD_PID > /dev/null 2>&1; then
        kill -9 $OLD_PID
        sleep 1
    fi
    echo "✓ 旧进程已停止 (PID: $OLD_PID)"
else
    echo "ℹ️  没有运行中的进程"
fi
echo ""

# 4. 启动新进程
echo "🚀 启动新进程..."
nohup ./nofx > nofx.log 2>&1 &
NEW_PID=$!
echo "✓ 新进程已启动 (PID: $NEW_PID)"
echo ""

# 5. 等待启动
echo "⏳ 等待进程启动..."
sleep 5

# 6. 验证
echo "🔍 验证进程状态..."
if ps -p $NEW_PID > /dev/null; then
    echo "✓ 进程运行正常 (PID: $NEW_PID)"
    echo ""
    
    # 检查日志
    echo "📊 最近日志（最后20行）："
    echo "----------------------------------------"
    tail -n 20 nofx.log
    echo "----------------------------------------"
    echo ""
    
    echo "=========================================="
    echo "✅ 部署成功！"
    echo "=========================================="
    echo ""
    echo "📝 修复内容："
    echo "  1. 数据新鲜度检测（5分钟/5小时超时自动刷新）"
    echo "  2. WebSocket 心跳检测（60秒超时自动重连）"
    echo "  3. 定期强制刷新（每30分钟）"
    echo ""
    echo "🔍 监控命令："
    echo "  tail -f nofx.log | grep -E '(数据过期|WebSocket|刷新|BTC)'"
    echo ""
    echo "📊 查看完整日志："
    echo "  tail -f nofx.log"
    echo ""
else
    echo "❌ 进程启动失败"
    echo ""
    echo "📋 错误日志："
    tail -n 50 nofx.log
    echo ""
    echo "💡 尝试手动启动："
    echo "  ./nofx"
    exit 1
fi
