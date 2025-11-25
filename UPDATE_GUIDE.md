# NOFX 更新指南

## 📋 更新脚本功能

`update.sh` 脚本提供安全的无缝更新功能，包括：

### ✨ 核心功能

1. **数据保护**
   - 自动备份数据库（config.db）
   - 保护决策日志（decision_logs）
   - 保护密钥文件（secrets）
   - 持久化数据到独立目录

2. **代理配置**
   - 自动配置Git代理（访问GitHub）
   - 自动配置服务代理（访问Binance API）
   - 确保Clash代理正确集成

3. **安全更新**
   - 编译前备份当前版本
   - 编译失败自动回滚
   - 服务启动失败自动回滚
   - 保留最近10次备份

4. **完整流程**
   - 检查更新
   - 备份数据
   - 拉取代码
   - 配置服务
   - 编译后端
   - 编译前端
   - 恢复数据
   - 替换文件
   - 重启服务
   - 验证状态

## 🚀 使用方法

### 标准更新

```bash
cd /root/nofx
./update.sh
```

### 查看更新内容

脚本会自动显示：
- 当前版本号
- 远程版本号
- 更新日志（最近10条提交）

### 确认更新

```
确认更新？(y/n): y
```

## 📁 目录结构

```
/root/nofx/              # 主程序目录
/root/nofx_data/         # 持久化数据目录
  ├── config.db          # 数据库
  ├── decision_logs/     # 决策日志
  └── secrets/           # 密钥文件
/root/nofx_backups/      # 备份目录
  ├── update_20251121_180000/
  ├── update_20251121_190000/
  └── ...
```

## 🔧 数据恢复

### 从备份恢复

```bash
# 查看可用备份
ls -lt /root/nofx_backups/

# 恢复特定备份
BACKUP_DIR="/root/nofx_backups/update_20251121_180000"
cd /root/nofx
systemctl stop nofx
cp ${BACKUP_DIR}/config.db* ./
cp ${BACKUP_DIR}/nofx ./
systemctl start nofx
```

### 从持久化目录恢复

```bash
cd /root/nofx
systemctl stop nofx
cp /root/nofx_data/config.db* ./
rsync -a /root/nofx_data/decision_logs/ ./decision_logs/
systemctl start nofx
```

## ⚠️ 注意事项

1. **更新时机**
   - 建议在交易员停止时更新
   - 更新会中断当前周期的决策
   - 历史数据和配置不会丢失

2. **网络要求**
   - 确保Clash代理正在运行
   - 脚本会自动配置代理

3. **磁盘空间**
   - 每次更新约占用50-100MB
   - 自动清理旧备份（保留10次）

4. **回滚机制**
   - 编译失败：自动回滚代码
   - 启动失败：自动回滚程序和数据
   - 手动回滚：使用备份目录

## 🔍 故障排查

### 更新失败

```bash
# 查看服务状态
systemctl status nofx

# 查看最新日志
journalctl -u nofx -n 50 --no-pager

# 手动回滚
cd /root/nofx
git reset --hard HEAD~1
systemctl restart nofx
```

### 数据丢失

```bash
# 检查持久化目录
ls -lh /root/nofx_data/

# 检查备份
ls -lt /root/nofx_backups/

# 恢复数据（见上文）
```

### 代理问题

```bash
# 检查Clash状态
systemctl status clash

# 测试代理
curl -x http://127.0.0.1:7890 https://api.binance.com/api/v3/ping

# 重启Clash
systemctl restart clash
```

## 📊 更新后检查

更新完成后，脚本会自动显示：

1. **版本信息**
   - 旧版本号
   - 新版本号
   - 备份位置

2. **服务状态**
   - 运行状态
   - 内存使用
   - 进程信息

3. **最新日志**
   - 启动日志
   - 交易员加载
   - 错误信息

4. **数据统计**
   - 数据库大小
   - 决策日志数量
   - 备份数量

## 🎯 最佳实践

1. **定期更新**
   - 每周检查一次更新
   - 重要更新及时应用

2. **备份管理**
   - 定期检查备份目录
   - 重要数据额外备份

3. **监控日志**
   - 更新后查看日志
   - 确认交易员正常运行

4. **测试验证**
   - 更新后访问Web界面
   - 检查交易员状态
   - 验证API连接

## 📞 支持

如遇问题，请检查：
1. 服务日志：`journalctl -u nofx -f`
2. 备份目录：`/root/nofx_backups/`
3. 持久化数据：`/root/nofx_data/`
