package main

import (
	"os"

	"github.com/sagernet/sing-box/experimental/libbox"
)

// platformInterface 是 sing-box 在「平台托管」模式下回调宿主的接口实现。
//
// ⚠️⚠️ 这是整个 spike 里最版本敏感的部分。libbox.PlatformInterface 的方法集
// 会随 sing-box 版本增删。go mod tidy 之后，务必执行：
//
//	go doc github.com/sagernet/sing-box/experimental/libbox.PlatformInterface
//
// 然后对照增删下面的方法。下面的编译期断言会让缺失/多余的方法直接报错，
// 编译器会精确告诉你差哪个方法——按提示补齐即可。
//
// 设计原则（spike 阶段最小化 OHOS/musl 雷区）：
//   - OpenTun 直接返回宿主已创建好的 tun fd（savedTunFd）；
//   - 关掉接口自动探测与平台接口监控，避免 sing-box 在 OHOS-musl 上走 netlink
//     （netlink/接口监控是 musl 下的高危点，先全部躲开）；
//   - 关掉进程级路由（uid/包名查询），spike 用不到。
//
// 如果关掉平台监控后 sing-box 仍因 netlink 崩，再把 UsePlatformDefaultInterfaceMonitor
// 改成返回 true，并在 StartDefaultInterfaceMonitor 里给 listener 喂一个固定默认接口。
var _ libbox.PlatformInterface = (*platformInterface)(nil)

type platformInterface struct{}

func newPlatformInterface() *platformInterface {
	return &platformInterface{}
}

// OpenTun 是 Stage B 的核心：把 HarmonyOS 给的 fd 交给 sing-box。
func (p *platformInterface) OpenTun(options libbox.TunOptions) (int32, error) {
	mu.Lock()
	fd := savedTunFd
	mu.Unlock()
	if fd < 0 {
		return -1, os.ErrInvalid
	}
	// fd 已是 VpnExtension 配置好的 tun，options 在 spike 阶段忽略。
	return fd, nil
}

// ---- 以下均为 spike 最小实现，按需在设备上迭代 ----

func (p *platformInterface) UsePlatformAutoDetectInterfaceControl() bool { return false }

func (p *platformInterface) AutoDetectInterfaceControl(fd int32) error { return nil }

func (p *platformInterface) WriteLog(message string) {
	// 转到 stderr；构建脚本里的 android_log_stub 会把 stderr 打到 hilog。
	os.Stderr.WriteString("[sing-box] " + message + "\n")
}

func (p *platformInterface) UseProcFS() bool { return false }

func (p *platformInterface) FindConnectionOwner(ipProtocol int32, sourceAddress string, sourcePort int32, destinationAddress string, destinationPort int32) (int32, error) {
	return -1, os.ErrInvalid
}

func (p *platformInterface) PackageNameByUid(uid int32) (string, error) {
	return "", os.ErrInvalid
}

func (p *platformInterface) UIDByPackageName(packageName string) (int32, error) {
	return -1, os.ErrInvalid
}

// v1.11.0 的 PlatformInterface 没有 Use*Monitor/Getter 开关 —— 宿主总是要提供接口
// 监控。spike 阶段给空实现：固定配置下不依赖接口更新事件。若设备上因缺接口信息出问题，
// 再在 StartDefaultInterfaceMonitor 里向 listener 推一个固定默认接口。
func (p *platformInterface) StartDefaultInterfaceMonitor(listener libbox.InterfaceUpdateListener) error {
	return nil
}

func (p *platformInterface) CloseDefaultInterfaceMonitor(listener libbox.InterfaceUpdateListener) error {
	return nil
}

func (p *platformInterface) GetInterfaces() (libbox.NetworkInterfaceIterator, error) {
	return nil, nil
}

func (p *platformInterface) UnderNetworkExtension() bool { return false }

func (p *platformInterface) IncludeAllNetworks() bool { return false }

func (p *platformInterface) ReadWIFIState() *libbox.WIFIState { return nil }

func (p *platformInterface) ClearDNSCache() {}

// SendNotification：spike 阶段忽略（sing-box 用它推系统通知，如订阅更新提示）。
func (p *platformInterface) SendNotification(notification *libbox.Notification) error { return nil }
