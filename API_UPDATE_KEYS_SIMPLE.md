# 交易所API密钥更新接口 - 简化版

## 🎯 核心功能

**直接更新数据库中的API密钥，不停止运行中的交易员，不影响AI决策周期。**

## 📡 接口信息

```
POST /api/exchanges/:exchange_id/update-keys
```

### 请求示例

```bash
curl -X POST "http://47.109.82.94/api/exchanges/binance/update-keys" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "api_key": "新的API_KEY",
    "secret_key": "新的SECRET_KEY"
  }'
```

### 响应示例

```json
{
  "message": "API密钥已更新到数据库",
  "affected_traders": 2,
  "running_traders": 1,
  "trader_ids": ["trader_1", "trader_2"],
  "note": "运行中的交易员将在下次重启时使用新密钥"
}
```

## 💡 工作原理

1. ✅ 接口只更新数据库中的密钥
2. ✅ 运行中的交易员继续使用旧密钥（不中断）
3. ✅ 不影响AI决策周期
4. ✅ 下次重启交易员时自动使用新密钥

## 🔧 集成示例

### JavaScript/TypeScript

```typescript
async function updateBinanceKeys(apiKey: string, secretKey: string) {
  const token = localStorage.getItem('auth_token');
  
  const response = await fetch(
    'http://47.109.82.94/api/exchanges/binance/update-keys',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        api_key: apiKey,
        secret_key: secretKey,
      }),
    }
  );

  if (!response.ok) {
    throw new Error('更新失败');
  }

  return await response.json();
}
```

### Python

```python
import requests

def update_binance_keys(api_key: str, secret_key: str, token: str):
    url = "http://47.109.82.94/api/exchanges/binance/update-keys"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    payload = {
        "api_key": api_key,
        "secret_key": secret_key
    }
    
    response = requests.post(url, headers=headers, json=payload)
    return response.json()
```

## ⚠️ 重要提示

1. **延迟生效**: 新密钥在交易员重启后才生效
2. **不验证密钥**: 系统不会验证密钥是否有效
3. **立即生效**: 如需立即使用新密钥，请手动重启交易员

## 📋 支持的交易所

- `binance` - 币安合约
- `okx` - OKX
- `hyperliquid` - Hyperliquid
- `aster` - Aster

## 🔐 获取JWT Token

```bash
# 登录获取Token
curl -X POST "http://47.109.82.94/api/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your@email.com",
    "password": "your_password"
  }'
```

响应中的 `token` 字段即为JWT Token。
