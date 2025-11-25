# NOFX 胖虎定制版 - AI 加密货币交易系统

> 🏆 **AI 模型排名参考**: https://nof1.ai - 本系统根据该排名动态切换最优 AI 模型

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Go Version](https://img.shields.io/badge/go-1.21+-00ADD8.svg)](https://golang.org/)
[![React](https://img.shields.io/badge/react-18.0+-61DAFB.svg)](https://reactjs.org/)

## 📖 项目简介

NOFX 胖虎定制版是一个基于 AI 的加密货币自动交易系统，支持币安合约交易。系统采用先进的 AI 决策引擎，结合实时市场数据分析，实现智能化的交易策略。

本版本在原 [NoFxAiOS/nofx](https://github.com/NoFxAiOS/nofx) 基础上进行了深度定制和优化，专注于提升交易性能和用户体验。

## ✨ 核心特性

### 🤖 智能 AI 决策
- **动态模型切换**: 根据 [nof1.ai](https://nof1.ai) 排名自动选择最优 AI 模型
- **多模型支持**: DeepSeek、Qwen 等主流 AI 模型
- **实时市场分析**: 结合技术指标和市场情绪进行决策
- **风险控制**: 智能止损、仓位管理、最大回撤限制

### 📊 性能优化
- **夏普比率修复**: 使用实际保证金计算，准确反映风险调整后收益
- **WebSocket 优化**: 实时市场数据推送，低延迟响应
- **数据持久化**: 完整的交易历史记录和性能分析
- **代理支持**: 支持 HTTP/SOCKS5 代理，确保网络稳定

### 💼 交易功能
- **多币种支持**: BTC、ETH、SOL、BNB、XRP 等主流币种
- **合约交易**: 支持币安 USDT 永续合约
- **灵活杠杆**: 可配置杠杆倍数（1-125x）
- **自动化交易**: 24/7 无人值守自动交易

### 📈 数据分析
- **实时监控**: 账户净值、持仓、盈亏实时展示
- **性能指标**: 胜率、盈亏比、夏普比率、最大回撤
- **交易历史**: 完整的交易记录和决策日志
- **AI 学习**: 系统自动分析历史表现，优化策略

## 🚀 快速开始

### 环境要求

- Go 1.21+
- Node.js 18+
- MySQL/SQLite
- 币安 API 密钥

### 安装部署

#### 1. 克隆仓库
```bash
git clone https://github.com/871311823/NOFX_panghu.git
cd NOFX_panghu
```

#### 2. 配置环境
```bash
# 复制配置文件
cp config.json.example config.json

# 编辑配置文件，填入你的 API 密钥
vim config.json
```

#### 3. 编译后端
```bash
go mod download
go build -o nofx main.go
```

#### 4. 编译前端
```bash
cd web
npm install
npm run build
cd ..
```

#### 5. 启动服务
```bash
./nofx
```

访问 http://localhost:8080 即可使用系统。

### Docker 部署

```bash
# 使用 Docker Compose
docker-compose up -d
```

详细部署文档请参考 [部署指南](docs/getting-started/docker-deploy.zh-CN.md)。

## 📋 配置说明

### 基础配置 (config.json)

```json
{
  "api_server_port": 8080,
  "leverage": {
    "btc_eth_leverage": 5,
    "altcoin_leverage": 3
  },
  "use_default_coins": true,
  "default_coins": [
    "BTCUSDT",
    "ETHUSDT",
    "SOLUSDT",
    "BNBUSDT"
  ],
  "max_daily_loss": 10.0,
  "max_drawdown": 20.0
}
```

### AI 模型配置

系统支持多个 AI 模型，可在前端界面配置：

- **DeepSeek**: 推理能力强，适合复杂市场分析
- **Qwen**: 响应速度快，适合高频交易
- **自定义模型**: 支持任何兼容 OpenAI API 的模型

**模型选择建议**: 访问 https://nof1.ai 查看最新排名，选择排名靠前的模型。

## 🎯 核心优化

### 1. 夏普比率计算修复

**问题**: 原版使用固定估算值计算收益率，导致夏普比率不准确。

**解决方案**:
- 使用实际保证金 (MarginUsed) 计算收益率
- 移除不合理的年化计算
- 添加详细的计算日志

**效果**: 夏普比率准确反映风险调整后收益，帮助评估策略有效性。

### 2. WebSocket 数据优化

**问题**: 数据更新延迟，影响决策时效性。

**解决方案**:
- 优化 WebSocket 连接管理
- 实现数据缓存和去重
- 添加断线重连机制

**效果**: 市场数据实时更新，决策响应更快。

### 3. 代理支持

**问题**: 部分地区无法直接访问币安 API。

**解决方案**:
- 支持 HTTP/SOCKS5 代理
- 自动代理切换
- 代理健康检查

**效果**: 确保网络连接稳定，避免交易中断。

## 📊 性能数据

基于实际运行数据（63 笔交易）：

| 指标 | 数值 | 说明 |
|------|------|------|
| 总交易数 | 63 | 已完成的交易笔数 |
| 胜率 | 34.92% | 盈利交易占比 |
| 盈亏比 | 1.75 | 平均盈利/平均亏损 |
| 夏普比率 | -0.15 | 风险调整后收益 |
| 最大回撤 | -25.32% | 最大资金回撤 |

**分析**: 当前策略盈亏比良好，但胜率偏低。系统正在通过 AI 学习优化策略，预期 3-6 个月达到盈利状态。

## 🛠️ 技术栈

### 后端
- **语言**: Go 1.21+
- **框架**: Gin (HTTP), Gorilla WebSocket
- **数据库**: SQLite/MySQL
- **AI 集成**: OpenAI API 兼容接口

### 前端
- **框架**: React 18 + TypeScript
- **UI 库**: Tailwind CSS
- **图表**: Recharts
- **状态管理**: Zustand

### 基础设施
- **容器化**: Docker + Docker Compose
- **反向代理**: Nginx
- **进程管理**: Systemd

## 📚 文档

- [快速开始](docs/getting-started/README.zh-CN.md)
- [Docker 部署](docs/getting-started/docker-deploy.zh-CN.md)
- [API 文档](docs/api/README.md)
- [常见问题](docs/guides/faq.zh-CN.md)
- [故障排除](docs/guides/TROUBLESHOOTING.zh-CN.md)

## 🔧 开发指南

### 本地开发

```bash
# 后端开发
go run main.go

# 前端开发
cd web
npm run dev
```

### 代码规范

- Go: 遵循 [Effective Go](https://golang.org/doc/effective_go.html)
- TypeScript: 使用 ESLint + Prettier
- 提交信息: 遵循 [Conventional Commits](https://www.conventionalcommits.org/)

### 测试

```bash
# 后端测试
go test ./...

# 前端测试
cd web
npm test
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

在提交 PR 前，请确保：
1. 代码通过所有测试
2. 遵循项目代码规范
3. 更新相关文档

## 📄 许可证

本项目基于 MIT 许可证开源。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- 原项目: [NoFxAiOS/nofx](https://github.com/NoFxAiOS/nofx)
- AI 模型排名: [nof1.ai](https://nof1.ai)
- 币安 API: [Binance](https://www.binance.com/)

## 📞 联系方式

- GitHub Issues: https://github.com/871311823/NOFX_panghu/issues
- 项目主页: https://github.com/871311823/NOFX_panghu

## ⚠️ 免责声明

本软件仅供学习和研究使用。加密货币交易存在高风险，可能导致资金损失。使用本软件进行实盘交易的风险由用户自行承担。

**请注意**:
- 加密货币市场波动剧烈，可能造成重大损失
- AI 决策不保证盈利，历史表现不代表未来收益
- 建议先在模拟环境测试，充分了解系统后再进行实盘交易
- 请根据自身风险承受能力合理配置资金

---

**🌟 如果这个项目对你有帮助，请给个 Star！**

**📈 AI 模型排名**: https://nof1.ai - 持续关注，选择最优模型！
