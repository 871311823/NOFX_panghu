#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# NOFX 无缝更新脚本 v2.0
# 功能: 安全更新代码，保护历史数据，自动配置代理
# ═══════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DEPLOY_DIR="/root/nofx"
BACKUP_DIR="/root/nofx_backups"
DATA_DIR="/root/nofx_data"  # 持久化数据目录

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║    🔄 NOFX 无缝更新系统                                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

cd ${DEPLOY_DIR}

echo -e "${BLUE}[1/8]${NC} 检查Git状态..."
if [ ! -d ".git" ]; then
    echo -e "${RED}✗${NC} 不是Git仓库，无法更新"
    exit 1
fi

CURRENT_COMMIT=$(git rev-parse HEAD)
echo -e "${BLUE}当前版本:${NC} ${CURRENT_COMMIT:0:8}"

echo -e "${BLUE}[2/8]${NC} 获取远程更新..."
# 配置Git使用代理
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

git fetch origin main

REMOTE_COMMIT=$(git rev-parse origin/main)
echo -e "${BLUE}远程版本:${NC} ${REMOTE_COMMIT:0:8}"
echo ""

if [ "$CURRENT_COMMIT" = "$REMOTE_COMMIT" ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║    ✅ 已是最新版本，无需更新                              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 0
fi

echo -e "${YELLOW}⚠️  发现新版本${NC}"
echo ""
echo -e "${BLUE}更新内容:${NC}"
git log --oneline ${CURRENT_COMMIT}..${REMOTE_COMMIT} | head -10
echo ""

read -p "确认更新？(y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo -e "${BLUE}已取消更新${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[3/10]${NC} 备份当前版本和数据..."
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_BACKUP="${BACKUP_DIR}/update_${BACKUP_TIMESTAMP}"
mkdir -p ${CURRENT_BACKUP}
mkdir -p ${DATA_DIR}

# 备份关键文件
cp config.json ${CURRENT_BACKUP}/ 2>/dev/null || true
cp config.db* ${CURRENT_BACKUP}/ 2>/dev/null || true
cp .env ${CURRENT_BACKUP}/ 2>/dev/null || true
cp nofx ${CURRENT_BACKUP}/ 2>/dev/null || true

# 备份历史数据（决策日志、交易记录等）
if [ -d "decision_logs" ]; then
    echo -e "${BLUE}  备份决策日志...${NC}"
    cp -r decision_logs ${CURRENT_BACKUP}/ 2>/dev/null || true
fi

if [ -d "secrets" ]; then
    echo -e "${BLUE}  备份密钥文件...${NC}"
    cp -r secrets ${CURRENT_BACKUP}/ 2>/dev/null || true
fi

# 同步到持久化目录
echo -e "${BLUE}  同步到持久化目录...${NC}"
rsync -a --ignore-existing config.db* ${DATA_DIR}/ 2>/dev/null || true
rsync -a --ignore-existing decision_logs/ ${DATA_DIR}/decision_logs/ 2>/dev/null || true

echo -e "${GREEN}✓${NC} 备份完成: ${CURRENT_BACKUP}"
echo -e "${GREEN}✓${NC} 数据已同步到: ${DATA_DIR}"
echo ""

echo -e "${BLUE}[4/10]${NC} 拉取最新代码..."
git pull origin main
echo -e "${GREEN}✓${NC} 代码更新完成"
echo ""

echo -e "${BLUE}[5/10]${NC} 检查并配置系统服务..."
# 确保服务配置包含代理设置
SERVICE_FILE="/etc/systemd/system/nofx.service"
if ! grep -q "HTTP_PROXY" ${SERVICE_FILE}; then
    echo -e "${YELLOW}  添加代理配置到服务文件...${NC}"
    cat > ${SERVICE_FILE} << 'EOF'
[Unit]
Description=NOFX AI Trading System
After=network.target clash.service
Wants=clash.service

[Service]
Type=simple
User=root
WorkingDirectory=/root/nofx
EnvironmentFile=/root/nofx/.env
ExecStart=/root/nofx/nofx
Restart=always
RestartSec=10
Environment="PATH=/usr/local/go/bin:/usr/bin:/bin"
Environment="HTTP_PROXY=http://127.0.0.1:7890"
Environment="HTTPS_PROXY=http://127.0.0.1:7890"
Environment="NO_PROXY=localhost,127.0.0.1"

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    echo -e "${GREEN}✓${NC} 服务配置已更新"
else
    echo -e "${GREEN}✓${NC} 服务配置正常"
fi
echo ""

echo -e "${BLUE}[6/10]${NC} 编译后端..."
export PATH=/usr/local/go/bin:$PATH
export GOPROXY=https://goproxy.cn,direct
go build -o nofx_new main.go

if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} 编译失败，回滚..."
    git reset --hard ${CURRENT_COMMIT}
    exit 1
fi

echo -e "${GREEN}✓${NC} 后端编译成功"
echo ""

echo -e "${BLUE}[7/10]${NC} 编译前端..."
cd web

# 检查package.json是否有变化
if git diff ${CURRENT_COMMIT}..${REMOTE_COMMIT} --name-only | grep -q "web/package"; then
    echo -e "${YELLOW}  检测到依赖变化，重新安装...${NC}"
    npm install --registry=https://registry.npmmirror.com
fi

npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} 前端编译失败，回滚..."
    cd ${DEPLOY_DIR}
    git reset --hard ${CURRENT_COMMIT}
    exit 1
fi

echo -e "${GREEN}✓${NC} 前端编译成功"
cd ${DEPLOY_DIR}
echo ""

echo -e "${BLUE}[8/10]${NC} 恢复持久化数据..."
# 确保数据库和历史数据不会丢失
if [ -f "${DATA_DIR}/config.db" ]; then
    echo -e "${BLUE}  恢复数据库...${NC}"
    cp ${DATA_DIR}/config.db* ./ 2>/dev/null || true
fi

if [ -d "${DATA_DIR}/decision_logs" ]; then
    echo -e "${BLUE}  恢复决策日志...${NC}"
    rsync -a ${DATA_DIR}/decision_logs/ ./decision_logs/ 2>/dev/null || true
fi

echo -e "${GREEN}✓${NC} 数据恢复完成"
echo ""

echo -e "${BLUE}[9/10]${NC} 替换可执行文件..."
mv nofx_new nofx
chmod +x nofx
echo -e "${GREEN}✓${NC} 文件替换完成"
echo ""

echo -e "${BLUE}[10/10]${NC} 重启服务..."
echo -e "${YELLOW}⚠️  即将重启服务，当前周期的决策会被中断${NC}"
sleep 2

systemctl restart nofx
sleep 5

if systemctl is-active --quiet nofx; then
    echo -e "${GREEN}✓${NC} 服务重启成功"
else
    echo -e "${RED}✗${NC} 服务启动失败，尝试回滚..."
    
    # 回滚
    git reset --hard ${CURRENT_COMMIT}
    cp ${CURRENT_BACKUP}/nofx ./
    cp ${CURRENT_BACKUP}/config.db* ./ 2>/dev/null || true
    systemctl restart nofx
    
    echo -e "${YELLOW}已回滚到之前版本${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    ✅ 更新完成！                                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

NEW_COMMIT=$(git rev-parse HEAD)
echo -e "${BLUE}📊 更新信息:${NC}"
echo -e "  • 旧版本: ${CURRENT_COMMIT:0:8}"
echo -e "  • 新版本: ${NEW_COMMIT:0:8}"
echo -e "  • 备份位置: ${CURRENT_BACKUP}"
echo -e "  • 数据目录: ${DATA_DIR}"
echo ""

echo -e "${BLUE}🔍 服务状态:${NC}"
systemctl status nofx --no-pager | head -10
echo ""

echo -e "${BLUE}📝 最新日志:${NC}"
journalctl -u nofx -n 15 --no-pager
echo ""

echo -e "${BLUE}💾 数据保护:${NC}"
echo -e "  • 数据库: $(ls -lh config.db 2>/dev/null | awk '{print $5}' || echo '未找到')"
echo -e "  • 决策日志: $(find decision_logs -type f 2>/dev/null | wc -l || echo '0') 个文件"
echo -e "  • 备份保留: 最近10次更新"
echo ""

# 清理旧备份（保留最近10次）
echo -e "${BLUE}🧹 清理旧备份...${NC}"
cd ${BACKUP_DIR}
ls -t | tail -n +11 | xargs -r rm -rf
echo -e "${GREEN}✓${NC} 备份清理完成"
echo ""

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ 更新成功！系统已恢复运行${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
