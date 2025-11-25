package mcp

import (
	"encoding/json"
	"fmt"
	"strings"
)

// APIError AI API错误
type APIError struct {
	StatusCode int    `json:"status_code"`
	Code       int    `json:"code"`
	Message    string `json:"message"`
	RawBody    string `json:"raw_body"`
}

func (e *APIError) Error() string {
	return fmt.Sprintf("API返回错误 (status %d, code %d): %s", e.StatusCode, e.Code, e.Message)
}

// IsInsufficientBalance 检查是否是余额不足错误
func (e *APIError) IsInsufficientBalance() bool {
	// DeepSeek/Qwen 余额不足错误码
	if e.Code == 30001 {
		return true
	}
	
	// 检查消息内容
	msg := strings.ToLower(e.Message)
	return strings.Contains(msg, "balance") && strings.Contains(msg, "insufficient") ||
		strings.Contains(msg, "余额不足") ||
		strings.Contains(msg, "账户余额不足")
}

// ParseAPIError 从响应体解析API错误
func ParseAPIError(statusCode int, body []byte) *APIError {
	apiErr := &APIError{
		StatusCode: statusCode,
		RawBody:    string(body),
	}

	// 尝试解析JSON错误响应
	var errResp struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
		Error   struct {
			Code    string `json:"code"`
			Message string `json:"message"`
		} `json:"error"`
	}

	if err := json.Unmarshal(body, &errResp); err == nil {
		// DeepSeek/Qwen 格式
		if errResp.Code != 0 {
			apiErr.Code = errResp.Code
			apiErr.Message = errResp.Message
		} else if errResp.Error.Message != "" {
			// OpenAI 格式
			apiErr.Message = errResp.Error.Message
		}
	}

	// 如果解析失败，使用原始响应
	if apiErr.Message == "" {
		apiErr.Message = string(body)
	}

	return apiErr
}

// InsufficientBalanceError 余额不足错误（特殊标记）
type InsufficientBalanceError struct {
	Provider string
	APIError *APIError
}

func (e *InsufficientBalanceError) Error() string {
	return fmt.Sprintf("[%s] 账户余额不足，请充值或更新API Key: %s", e.Provider, e.APIError.Message)
}

func (e *InsufficientBalanceError) Unwrap() error {
	return e.APIError
}

// IsInsufficientBalanceError 检查是否是余额不足错误
func IsInsufficientBalanceError(err error) bool {
	if err == nil {
		return false
	}

	// 直接类型断言
	if _, ok := err.(*InsufficientBalanceError); ok {
		return true
	}

	// 检查错误消息
	errMsg := strings.ToLower(err.Error())
	return (strings.Contains(errMsg, "balance") && strings.Contains(errMsg, "insufficient")) ||
		strings.Contains(errMsg, "余额不足") ||
		strings.Contains(errMsg, "账户余额不足") ||
		strings.Contains(errMsg, "code=30001")
}
