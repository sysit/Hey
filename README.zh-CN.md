# Hey

Hey 是一个面向 HarmonyOS NEXT 的 VPN 客户端 MVP，使用 ArkTS、Stage 模型、
VPN Extension Ability 和原生 Xray 内核实现。项目目标是在鸿蒙设备上导入代理节点
或订阅，生成 Xray 运行配置，启动系统 VPN，并把设备的 TUN 流量交给 Xray 原生
TUN 入站处理。

> 当前项目仍处于 MVP 阶段。界面、节点导入、订阅加载、Xray 配置生成、Native
> 桥接打包和 VPN Extension 启动链路已经就位，但完整流量闭环仍建议在真实
> HarmonyOS NEXT 设备上验证；部分模拟器或系统镜像可能没有 VPN 授权组件。

## 主要功能

- HarmonyOS Stage 应用，包含 `EntryAbility`、`HeyVpnAbility` 和备份能力。
- 节点列表、搜索、选择、启动、停止、重启和运行状态展示。
- 支持导入订阅 URL、Xray outbound JSON 和常见分享链接。
- 分享链接解析覆盖 `vless://`、`vmess://`、`trojan://`、`ss://`、`socks://`、
  `http://`、`https://`、`wireguard://`、`hysteria2://` 和 `hy2://`。
- 根据当前节点和设置生成 Xray 配置，包含原生 TUN 入站、代理出站、直连出站和阻断出站。
- 通过 Native N-API 桥接打包的 `libxray.so`，支持 TUN fd 注入、Xray 启停和节点延迟测试。
- 提供诊断日志面板、Native 运行状态和基础流量统计展示。
- 已搭建路由、设置、分应用代理、资源管理、扫码、订阅、日志、关于等页面。

## 当前完成度

| 模块 | 状态 | 说明 |
| --- | --- | --- |
| 应用骨架 / 导航 / 多语言 | 基本完成 | 页面路由和中英文资源已具备 |
| 节点与订阅 | 可用 | 支持多订阅分组、节点导入和当前节点选择 |
| VPN 启停链路 | 已实现，待真机闭环 | `VpnExtensionAbility -> TUN fd -> Xray TUN inbound` 链路已接通 |
| 节点测速 | 已实现，待更多真机验证 | 通过 `CGoPing` 做真实出站延迟测试 |
| 路由设置 | 部分完成 | 基础绕过 LAN/CN 已进入配置，广告拦截和自定义规则仍待接入 |
| Geo 资源 | 可用 | 支持 geoip/geosite 下载、自定义 URL 和备份还原 |
| 分应用代理 | 原型阶段 | 开关可持久化，真实应用枚举和白/黑名单映射仍待实现 |
| 扫码与分享 | 部分完成 | 文本导入/导出可用，摄像头扫码和二维码生成待补齐 |

更完整的功能对照和计划见 [`docs/roadmap.md`](docs/roadmap.md) 与
[`docs/v2rayng-feature-map.md`](docs/v2rayng-feature-map.md)。

## 运行链路

当前 VPN 数据面的核心路径如下：

```text
用户点击连接
  -> vpnExtension.startVpnExtensionAbility(...)
  -> HeyVpnAbility.onCreate(want)
  -> vpnExtension.createVpnConnection(context)
  -> vpnConnection.create(vpnConfig)
  -> 获取 Harmony VPN TUN fd
  -> libheyvpn.so dlopen(libxray.so)
  -> CGoSetTunFd(tunFd)
  -> CGoRunXrayFromJSON(config)
  -> Xray 原生 TUN inbound 读取 Harmony VPN fd
  -> Xray outbound 出站
```

Hey 不再通过 `tun2socks` 或 TUN-to-SOCKS 适配层转发 VPN 数据。系统创建 VPN
TUN fd 后，`libheyvpn.so` 会通过 `CGoSetTunFd` 把 fd 交给 Xray，运行时配置使用
Xray 的 `protocol: "tun"` 入站。节点延迟测试可能临时生成本地 SOCKS 入站，但它不参与
VPN 数据面转发。

## 项目结构

```text
AppScope/                         应用级 HarmonyOS 元数据和资源
entry/src/main/ets/               ArkTS UI、服务、存储、VPN Ability
entry/src/main/cpp/               Native N-API 桥接和原生内核说明
entry/src/main/cpp/prebuilt/      已打包的 arm64-v8a 原生库
scripts/                          Native 构建和真机烟测脚本
docs/                             路线图、功能对照和真机测试文档
```

## 开发环境

- DevEco Studio / HarmonyOS SDK 6.1.1，API 24。
- 用于端到端验证的 HarmonyOS NEXT 手机或平板。
- 如需重新构建 Xray 共享库，需要 Go 和 DevEco Native 工具链。

## 构建应用

使用项目内的烟测脚本构建 HAP：

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/device_vpn_smoke_test.sh build
```

构建产物默认位于：

```text
entry/build/default/outputs/default/entry-default-signed.hap
```

如需重新构建 Xray 原生内核：

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/build_libxray_ohos.sh
```

脚本会把 `libxray.so` 和 `libxray.h` 放到：

```text
entry/src/main/cpp/prebuilt/arm64-v8a/
```

## 真机安装与测试

查看已连接设备：

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/device_vpn_smoke_test.sh targets
```

安装 HAP：

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/device_vpn_smoke_test.sh install
```

查看 VPN 和 Native 桥接日志：

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/device_vpn_smoke_test.sh logs
```

推荐按 [`docs/real-device-vpn-test.md`](docs/real-device-vpn-test.md) 的清单完成一次真机闭环：

1. 打开 Hey。
2. 粘贴订阅 URL 或单个节点分享链接。
3. 选择一个节点并点击连接。
4. 接受系统 VPN 授权弹窗。
5. 在日志中确认 `VPN created`、`Xray TUN fd configured`、`Xray started` 等事件。
6. 打开浏览器或其他应用访问需要代理的网站。
7. 回到 Hey，确认流量统计变化。
8. 点击停止，确认 Xray 和 VPN 都正常释放。

## Native 内核说明

Native 桥接会构建 `libheyvpn.so`，并在运行时加载同目录下打包的 `libxray.so`。
当前已接通的核心接口包括：

- `CGoSetTunFd`：把 Harmony VPN TUN fd 交给 Xray。
- `CGoRunXrayFromJSON`：从 JSON 配置启动 Xray。
- `CGoStopXray`：停止 Xray。
- `CGoPing`：用于节点真实延迟测试。

更多原生运行时细节见 [`entry/src/main/cpp/README.md`](entry/src/main/cpp/README.md)
和 [`docs/vpn-native-runtime-fix.md`](docs/vpn-native-runtime-fix.md)。

## 后续计划

- 在更多 HarmonyOS NEXT 真机版本上完成 VPN 流量闭环验证。
- 接入更完整的 Native 内核能力，例如真实流量统计、配置预检和 Xray 版本显示。
- 完善路由规则系统，支持广告拦截、自定义规则集和规则编辑。
- 补齐分应用代理的真实应用枚举和白/黑名单映射。
- 支持摄像头扫码、二维码分享、自动订阅更新、去重和批量更新。
- 增加 HarmonyOS 深链导入、快捷入口、服务卡片等平台能力。
