package market

import (
	"log"
	"net/http"
	"net/url"
	"os"
)

// getProxyFunc 获取代理函数（支持环境变量）
// 用于WebSocket连接，确保能够访问币安API
func getProxyFunc() func(*http.Request) (*url.URL, error) {
	// 优先使用 HTTPS_PROXY，其次 HTTP_PROXY
	proxyURL := os.Getenv("HTTPS_PROXY")
	if proxyURL == "" {
		proxyURL = os.Getenv("HTTP_PROXY")
	}
	if proxyURL == "" {
		proxyURL = os.Getenv("https_proxy")
	}
	if proxyURL == "" {
		proxyURL = os.Getenv("http_proxy")
	}

	if proxyURL != "" {
		log.Printf("🌐 WebSocket使用代理: %s", proxyURL)
		parsedURL, err := url.Parse(proxyURL)
		if err != nil {
			log.Printf("⚠️  代理URL解析失败: %v，使用直连", err)
			return http.ProxyFromEnvironment
		}
		return http.ProxyURL(parsedURL)
	}

	// 没有配置代理，使用系统默认
	log.Printf("ℹ️  WebSocket未配置代理，使用系统默认")
	return http.ProxyFromEnvironment
}
