package market

import (
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

type CombinedStreamsClient struct {
	conn              *websocket.Conn
	mu                sync.RWMutex
	subscribers       map[string]chan []byte
	reconnect         bool
	done              chan struct{}
	batchSize         int      // 每批订阅的流数量
	subscribedStreams []string // 记录已订阅的流，用于重连后恢复
}

func NewCombinedStreamsClient(batchSize int) *CombinedStreamsClient {
	return &CombinedStreamsClient{
		subscribers:       make(map[string]chan []byte),
		reconnect:         true,
		done:              make(chan struct{}),
		batchSize:         batchSize,
		subscribedStreams: make([]string, 0),
	}
}

func (c *CombinedStreamsClient) Connect() error {
	dialer := websocket.Dialer{
		HandshakeTimeout: 45 * time.Second, // 增加超时时间以适应代理
		Proxy:            getProxyFunc(),    // ✅ 添加代理支持
	}

	// 组合流使用不同的端点
	conn, _, err := dialer.Dial("wss://fstream.binance.com/stream", nil)
	if err != nil {
		return fmt.Errorf("组合流WebSocket连接失败: %v", err)
	}

	c.mu.Lock()
	c.conn = conn
	c.mu.Unlock()

	log.Println("组合流WebSocket连接成功")
	go c.readMessages()

	return nil
}

// BatchSubscribeKlines 批量订阅K线
func (c *CombinedStreamsClient) BatchSubscribeKlines(symbols []string, interval string) error {
	// 将symbols分批处理
	batches := c.splitIntoBatches(symbols, c.batchSize)

	for i, batch := range batches {
		log.Printf("订阅第 %d 批, 数量: %d", i+1, len(batch))

		streams := make([]string, len(batch))
		for j, symbol := range batch {
			streams[j] = fmt.Sprintf("%s@kline_%s", strings.ToLower(symbol), interval)
		}

		if err := c.subscribeStreams(streams); err != nil {
			return fmt.Errorf("第 %d 批订阅失败: %v", i+1, err)
		}

		// 批次间延迟，避免被限制
		if i < len(batches)-1 {
			time.Sleep(100 * time.Millisecond)
		}
	}

	return nil
}

// splitIntoBatches 将切片分成指定大小的批次
func (c *CombinedStreamsClient) splitIntoBatches(symbols []string, batchSize int) [][]string {
	var batches [][]string

	for i := 0; i < len(symbols); i += batchSize {
		end := i + batchSize
		if end > len(symbols) {
			end = len(symbols)
		}
		batches = append(batches, symbols[i:end])
	}

	return batches
}

// subscribeStreams 订阅多个流
func (c *CombinedStreamsClient) subscribeStreams(streams []string) error {
	subscribeMsg := map[string]interface{}{
		"method": "SUBSCRIBE",
		"params": streams,
		"id":     time.Now().UnixNano(),
	}

	c.mu.Lock()
	if c.conn == nil {
		c.mu.Unlock()
		return fmt.Errorf("WebSocket未连接")
	}

	// 记录已订阅的流（用于重连后恢复）
	c.subscribedStreams = append(c.subscribedStreams, streams...)
	conn := c.conn
	c.mu.Unlock()

	log.Printf("订阅流: %v", streams)
	return conn.WriteJSON(subscribeMsg)
}

func (c *CombinedStreamsClient) readMessages() {
	for {
		select {
		case <-c.done:
			return
		default:
			c.mu.RLock()
			conn := c.conn
			c.mu.RUnlock()

			if conn == nil {
				time.Sleep(1 * time.Second)
				continue
			}

			// ✅ 设置读取超时（60秒），防止静默失败
			conn.SetReadDeadline(time.Now().Add(60 * time.Second))

			_, message, err := conn.ReadMessage()
			if err != nil {
				// 检查是否是超时错误
				if netErr, ok := err.(interface{ Timeout() bool }); ok && netErr.Timeout() {
					log.Printf("⚠️  WebSocket 读取超时（60秒无数据），触发重连...")
				} else {
					log.Printf("读取组合流消息失败: %v", err)
				}
				c.handleReconnect()
				return
			}

			c.handleCombinedMessage(message)
		}
	}
}

func (c *CombinedStreamsClient) handleCombinedMessage(message []byte) {
	var combinedMsg struct {
		Stream string          `json:"stream"`
		Data   json.RawMessage `json:"data"`
	}

	if err := json.Unmarshal(message, &combinedMsg); err != nil {
		log.Printf("解析组合消息失败: %v", err)
		return
	}

	c.mu.RLock()
	ch, exists := c.subscribers[combinedMsg.Stream]
	c.mu.RUnlock()

	if exists {
		select {
		case ch <- combinedMsg.Data:
		default:
			log.Printf("订阅者通道已满: %s", combinedMsg.Stream)
		}
	}
}

func (c *CombinedStreamsClient) AddSubscriber(stream string, bufferSize int) <-chan []byte {
	ch := make(chan []byte, bufferSize)
	c.mu.Lock()
	c.subscribers[stream] = ch
	c.mu.Unlock()
	return ch
}

func (c *CombinedStreamsClient) handleReconnect() {
	if !c.reconnect {
		return
	}

	log.Println("组合流尝试重新连接...")
	time.Sleep(3 * time.Second)

	if err := c.Connect(); err != nil {
		log.Printf("组合流重新连接失败: %v", err)
		go c.handleReconnect()
		return
	}

	// ✅ 重连成功后，重新订阅所有流
	c.mu.Lock()
	// 去重订阅流列表
	streamSet := make(map[string]bool)
	for _, stream := range c.subscribedStreams {
		streamSet[stream] = true
	}
	uniqueStreams := make([]string, 0, len(streamSet))
	for stream := range streamSet {
		uniqueStreams = append(uniqueStreams, stream)
	}
	c.mu.Unlock()

	if len(uniqueStreams) > 0 {
		log.Printf("🔄 重新订阅 %d 个数据流...", len(uniqueStreams))
		// 分批重新订阅
		for i := 0; i < len(uniqueStreams); i += c.batchSize {
			end := i + c.batchSize
			if end > len(uniqueStreams) {
				end = len(uniqueStreams)
			}
			batch := uniqueStreams[i:end]

			subscribeMsg := map[string]interface{}{
				"method": "SUBSCRIBE",
				"params": batch,
				"id":     time.Now().UnixNano(),
			}

			c.mu.RLock()
			conn := c.conn
			c.mu.RUnlock()

			if conn != nil {
				if err := conn.WriteJSON(subscribeMsg); err != nil {
					log.Printf("⚠️  重新订阅失败: %v", err)
				} else {
					log.Printf("✅ 已重新订阅批次 %d/%d", (i/c.batchSize)+1, (len(uniqueStreams)+c.batchSize-1)/c.batchSize)
				}
			}

			if i+c.batchSize < len(uniqueStreams) {
				time.Sleep(100 * time.Millisecond)
			}
		}
		log.Printf("✅ 所有数据流重新订阅完成")
	}

	// 重新启动读取循环
	go c.readMessages()
}

func (c *CombinedStreamsClient) Close() {
	c.reconnect = false
	close(c.done)

	c.mu.Lock()
	defer c.mu.Unlock()

	if c.conn != nil {
		c.conn.Close()
		c.conn = nil
	}

	for stream, ch := range c.subscribers {
		close(ch)
		delete(c.subscribers, stream)
	}
}
