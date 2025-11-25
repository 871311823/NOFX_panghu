# 交易所API密钥更新接口文档

## 📋 接口概述

此接口用于更新交易所API密钥到数据库，**不会停止或重启运行中的交易员**。

### 🎯 设计理念

- **不中断交易**: 运行中的交易员继续使用旧密钥完成当前周期
- **不影响AI决策**: 避免因重启导致周期重新计算
- **自动生效**: 交易员下次重启时自动使用新密钥
- **安全更新**: 仅更新数据库，不影响内存中的配置

## 🔗 接口信息

### 基本信息

- **接口路径**: `/api/exchanges/:exchange_id/update-keys`
- **请求方法**: `POST`
- **认证方式**: Bearer Token (JWT)
- **Content-Type**: `application/json`

### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| exchange_id | string | 是 | 交易所ID，如：`binance`, `okx`, `hyperliquid` 等 |

### 请求头

```http
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

### 请求体

```json
{
  "api_key": "your_new_api_key",
  "secret_key": "your_new_secret_key"
}
```

#### 请求参数说明

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| api_key | string | 是 | 新的API Key |
| secret_key | string | 是 | 新的Secret Key |

### 响应格式

#### 成功响应 (200 OK)

```json
{
  "message": "API密钥已更新到数据库",
  "affected_traders": 2,
  "running_traders": 1,
  "trader_ids": [
    "binance_user123_deepseek_trader456",
    "binance_user123_qwen_trader789"
  ],
  "note": "运行中的交易员将在下次重启时使用新密钥"
}
```

#### 响应字段说明

| 字段名 | 类型 | 说明 |
|--------|------|------|
| message | string | 操作结果消息 |
| affected_traders | integer | 受影响的交易员总数 |
| running_traders | integer | 当前正在运行的交易员数量 |
| trader_ids | array | 受影响的交易员ID列表 |
| note | string | 重要提示信息 |

#### 错误响应

**400 Bad Request** - 请求参数错误
```json
{
  "error": "请求参数错误: Key: 'api_key' Error:Field validation for 'api_key' failed on the 'required' tag"
}
```

**401 Unauthorized** - 未授权
```json
{
  "error": "未授权访问"
}
```

**404 Not Found** - 交易所配置不存在
```json
{
  "error": "交易所配置不存在"
}
```

**500 Internal Server Error** - 服务器内部错误
```json
{
  "error": "更新API密钥失败: database error"
}
```

## 📝 使用示例

### cURL 示例

```bash
curl -X POST "http://your-domain.com/api/exchanges/binance/update-keys" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "api_key": "your_new_binance_api_key",
    "secret_key": "your_new_binance_secret_key"
  }'
```

### JavaScript/TypeScript 示例

```typescript
async function updateExchangeKeys(
  exchangeId: string,
  apiKey: string,
  secretKey: string
): Promise<void> {
  const token = localStorage.getItem('auth_token');
  
  const response = await fetch(
    `http://your-domain.com/api/exchanges/${exchangeId}/update-keys`,
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
    const error = await response.json();
    throw new Error(error.error || '更新失败');
  }

  const result = await response.json();
  console.log('更新成功:', result);
  return result;
}

// 使用示例
updateExchangeKeys('binance', 'new_api_key', 'new_secret_key')
  .then(result => {
    console.log(`已更新 ${result.affected_traders} 个交易员的配置`);
    console.log(`其中 ${result.running_traders} 个正在运行`);
    console.log(`提示: ${result.note}`);
  })
  .catch(error => {
    console.error('更新失败:', error.message);
  });
```

### Python 示例

```python
import requests
import json

def update_exchange_keys(exchange_id: str, api_key: str, secret_key: str, token: str):
    """
    更新交易所API密钥
    
    Args:
        exchange_id: 交易所ID (如 'binance', 'okx')
        api_key: 新的API Key
        secret_key: 新的Secret Key
        token: JWT认证令牌
    
    Returns:
        dict: 更新结果
    """
    url = f"http://your-domain.com/api/exchanges/{exchange_id}/update-keys"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "api_key": api_key,
        "secret_key": secret_key
    }
    
    response = requests.post(url, headers=headers, json=payload)
    
    if response.status_code == 200:
        result = response.json()
        print(f"✅ 更新成功!")
        print(f"   受影响的交易员: {result['affected_traders']}")
        print(f"   运行中的交易员: {result['running_traders']}")
        print(f"   提示: {result['note']}")
        return result
    else:
        error = response.json()
        raise Exception(f"更新失败: {error.get('error', '未知错误')}")

# 使用示例
try:
    result = update_exchange_keys(
        exchange_id="binance",
        api_key="your_new_api_key",
        secret_key="your_new_secret_key",
        token="your_jwt_token"
    )
except Exception as e:
    print(f"❌ 错误: {e}")
```

### Go 示例

```go
package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
)

type UpdateKeysRequest struct {
    APIKey    string `json:"api_key"`
    SecretKey string `json:"secret_key"`
}

type UpdateKeysResponse struct {
    Message          string   `json:"message"`
    AffectedTraders  int      `json:"affected_traders"`
    RestartedTraders int      `json:"restarted_traders"`
    TraderIDs        []string `json:"trader_ids"`
}

func UpdateExchangeKeys(exchangeID, apiKey, secretKey, token string) (*UpdateKeysResponse, error) {
    url := fmt.Sprintf("http://your-domain.com/api/exchanges/%s/update-keys", exchangeID)
    
    reqBody := UpdateKeysRequest{
        APIKey:    apiKey,
        SecretKey: secretKey,
    }
    
    jsonData, err := json.Marshal(reqBody)
    if err != nil {
        return nil, err
    }
    
    req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
    if err != nil {
        return nil, err
    }
    
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Content-Type", "application/json")
    
    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }
    
    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("更新失败: %s", string(body))
    }
    
    var result UpdateKeysResponse
    if err := json.Unmarshal(body, &result); err != nil {
        return nil, err
    }
    
    return &result, nil
}

func main() {
    result, err := UpdateExchangeKeys(
        "binance",
        "your_new_api_key",
        "your_new_secret_key",
        "your_jwt_token",
    )
    
    if err != nil {
        fmt.Printf("❌ 错误: %v\n", err)
        return
    }
    
    fmt.Printf("✅ 更新成功!\n")
    fmt.Printf("   受影响的交易员: %d\n", result.AffectedTraders)
    fmt.Printf("   运行中的交易员: %d\n", result.RestartedTraders)
    fmt.Printf("   提示: %s\n", result.Note)
}
```

## 🔄 工作流程

```
1. 接收请求
   ↓
2. 验证用户身份 (JWT Token)
   ↓
3. 查找使用该交易所的所有交易员
   ↓
4. 获取现有交易所配置
   ↓
5. 更新数据库中的API密钥（保留其他配置）
   ↓
6. 返回更新结果
   ↓
7. 运行中的交易员继续使用旧密钥
   ↓
8. 下次重启时自动使用新密钥
```

## ⚠️ 注意事项

1. **不中断交易**: 运行中的交易员不会被停止，继续使用旧密钥完成当前周期
2. **延迟生效**: 新密钥在交易员下次重启时才会生效
3. **密钥验证**: 系统不会验证新密钥的有效性，请确保提供正确的密钥
4. **并发安全**: 同一用户同时更新多个交易所的密钥是安全的
5. **日志记录**: 所有操作都会记录到系统日志中，便于追踪
6. **手动重启**: 如需立即使用新密钥，请手动停止并重启交易员

## 🔐 安全建议

1. **HTTPS**: 生产环境必须使用HTTPS传输
2. **Token管理**: 妥善保管JWT Token，定期更换
3. **密钥加密**: 建议在传输前对密钥进行加密
4. **访问控制**: 确保只有授权用户可以访问此接口
5. **审计日志**: 定期检查API密钥更新日志

## 📊 支持的交易所

| 交易所ID | 名称 | 说明 |
|----------|------|------|
| binance | Binance Futures | 币安合约 |
| okx | OKX | OKX交易所 |
| hyperliquid | Hyperliquid | Hyperliquid DEX |
| aster | Aster | Aster交易所 |

## 🐛 故障排查

### 问题1: 401 Unauthorized

**原因**: JWT Token无效或已过期

**解决方案**:
```bash
# 重新登录获取新的Token
curl -X POST "http://your-domain.com/api/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "your@email.com", "password": "your_password"}'
```

### 问题2: 新密钥未生效

**原因**: 交易员仍在运行，使用的是内存中的旧密钥

**解决方案**:
```bash
# 方案1: 通过Web界面手动停止并重启交易员

# 方案2: 重启整个服务（会影响所有交易员）
systemctl restart nofx
```

### 问题3: API密钥无效

**原因**: 提供的密钥不正确或权限不足

**解决方案**:
- 检查Binance API密钥权限（需要合约交易权限）
- 确认API密钥未被删除或禁用
- 验证IP白名单设置

## 📞 技术支持

如遇问题，请提供以下信息：
1. 请求的完整URL和参数
2. 返回的错误信息
3. 系统日志（`journalctl -u nofx -n 100`）
4. 交易员ID和交易所ID
