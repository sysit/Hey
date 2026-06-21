// Package main 是 sing-box 内核的 HarmonyOS c-shared 封装（libsingbox.so）。
//
// 这是 Phase 0 spike 的产物：目标只是验证 sing-box（同样是 Go 写的）能不能在
// HarmonyOS（musl libc）上交叉编译成 .so、被 libheyvpn 的 dlopen 加载、并在 VPN
// 原生线程里跑通一条连接 —— 不撞死在那堵 Go-on-musl TLS 墙上。
//
// 导出协议刻意对齐 libXray：入参是 base64(JSON)，返回 base64(CallResponse JSON)，
// 这样以后能复用 entry/src/main/cpp/napi_init.cpp 里现成的解码逻辑。
//
// 分两阶段验证（务必按顺序）：
//   Stage A —— 只调 CGoSingBoxVersion()。这能一次性回答最致命的问题：
//              c-shared 能不能编出来、dlopen 会不会被 musl 以 IE-TLS 拒、
//              一次 cgo->Go 调用会不会 SIGSEGV。约 20 行，零 PlatformInterface 负担。
//   Stage B —— CGoSetTunFd + CGoStartSingBox + CGoStopSingBox，真正喂 tun fd 跑流量。
//              这步依赖 platform_stub.go 里的 PlatformInterface 实现（版本敏感）。
package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"runtime/debug"
	"sync"

	"github.com/sagernet/sing-box/experimental/libbox"
)

// main 是 c-shared 构建的占位入口，不会被调用。
func main() {}

var (
	mu         sync.Mutex
	boxService *libbox.BoxService
	// savedTunFd 存 HarmonyOS VpnExtension 创建好的 tun fd。
	// platform_stub.go 的 OpenTun() 直接把它返回给 sing-box —— 这是和 Xray 最大的
	// 区别：Xray 是内核外面 setTunFd 后内核自己读 TUN；sing-box 自己管 tun，
	// 必须通过 PlatformInterface 把已打开的 fd 喂进去。
	savedTunFd int32 = -1
)

// callResponse 与 libXray 的返回结构一致，便于 napi 侧复用解码。
type callResponse struct {
	Success bool   `json:"success"`
	Data    string `json:"data,omitempty"`
	Err     string `json:"err,omitempty"`
}

// startRequest 是 CGoStartSingBox 的 base64(JSON) 入参。
type startRequest struct {
	// BasePath 给 sing-box 放工作目录/缓存（用 app 的 filesDir）。
	BasePath string `json:"basePath"`
	// Config 是完整的 sing-box JSON 配置（spike 阶段可写死后传入）。
	Config string `json:"config"`
}

func encode(data string, err error) *C.char {
	resp := callResponse{Success: err == nil, Data: data}
	if err != nil {
		resp.Err = err.Error()
	}
	raw, _ := json.Marshal(resp)
	return C.CString(base64.StdEncoding.EncodeToString(raw))
}

func decodeRequest(base64Text *C.char, out interface{}) error {
	raw, err := base64.StdEncoding.DecodeString(C.GoString(base64Text))
	if err != nil {
		return err
	}
	return json.Unmarshal(raw, out)
}

// ---- Stage A：最小验证面，先跑通这个 ----

//export CGoSingBoxVersion
func CGoSingBoxVersion() *C.char {
	// 注意（和 Xray 同一堵墙）：即便这个能在 VPN 线程跑通，也不要从 ArkTS/UI 线程
	// 冷调它——GOOS=android 下 UI 线程的 cgo->Go 调用会 SIGSEGV。版本号应像
	// CoreInfo.ets 那样在构建期 stamp 进常量，UI 直接读常量。
	return encode(libbox.Version(), nil)
}

// ---- Stage B：真正喂 tun fd 跑连接 ----

//export CGoSetTunFd
func CGoSetTunFd(fd C.int) {
	mu.Lock()
	savedTunFd = int32(fd)
	mu.Unlock()
}

//export CGoStartSingBox
func CGoStartSingBox(base64Text *C.char) (result *C.char) {
	// 诊断兜底：libbox 启动若在本 goroutine 同步路径 panic（如 platform 接口返回 nil
	// 被解引用），recover 抓住并把原因+栈当错误返回，避免 VPN 扩展进程整个崩掉、看不到原因。
	// 注意：libbox 自己 spawn 的 goroutine 里的 panic / 真正的 cgo SIGSEGV 抓不到。
	defer func() {
		if r := recover(); r != nil {
			result = encode("", fmt.Errorf("sing-box start panic: %v | %s", r, string(debug.Stack())))
		}
	}()

	var req startRequest
	if err := decodeRequest(base64Text, &req); err != nil {
		return encode("", err)
	}

	mu.Lock()
	defer mu.Unlock()

	if boxService != nil {
		return encode("already running", nil)
	}

	// libbox.Setup 初始化基础目录（v1.11.0 签名：Setup(*SetupOptions) error）。
	// FixAndroidStack 对应 GOOS=android 构建。
	if err := libbox.Setup(&libbox.SetupOptions{
		BasePath:        req.BasePath,
		WorkingPath:     req.BasePath,
		TempPath:        req.BasePath,
		FixAndroidStack: true,
	}); err != nil {
		return encode("", err)
	}

	svc, err := libbox.NewService(req.Config, newPlatformInterface())
	if err != nil {
		return encode("", err)
	}
	if err := svc.Start(); err != nil {
		return encode("", err)
	}
	boxService = svc
	return encode("started", nil)
}

//export CGoStopSingBox
func CGoStopSingBox() *C.char {
	mu.Lock()
	defer mu.Unlock()
	if boxService == nil {
		return encode("not running", nil)
	}
	err := boxService.Close()
	boxService = nil
	return encode("stopped", err)
}
