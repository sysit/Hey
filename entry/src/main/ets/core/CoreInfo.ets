/**
 * 内置 Xray 内核（xtls/xray-core）的版本号 —— 即 `core.Version()` 的返回值。
 *
 * 注意：不要在运行时调用原生 `CGoXrayVersion()` 去取这个值。该函数在为
 * `GOOS=android` 编译、运行于 HarmonyOS 的 libxray.so 里冷调用会触发不可捕获的
 * 原生段错误（SIGSEGV，崩在 Go runtime 的 m/g 线程上下文里）。详见
 * scripts/build_libxray_ohos.sh 与 pages/About.ets。
 *
 * 正常应由 scripts/build_libxray_ohos.sh 在重编 libxray.so 时从所锁定的 xtls/xray-core
 * 源码（core/core.go 的 Version_x/y/z）自动写入。当前 libxray.so 是用 OHOS Go fork
 * （GOOS=openharmony）+ xray-core v1.250803.0 手动编的（见 docs/harmonyos-go-tls-wall.md），
 * 故此值手动同步为 25.8.3；待构建脚本补上 openharmony 分支后改回自动 stamp。
 */
export const BUNDLED_XRAY_VERSION: string = '25.8.3';

/**
 * 内置 sing-box 内核（sagernet/sing-box）的版本号。同样用编译期常量，不要运行时调
 * 原生 `CGoSingBoxVersion()`——libsingbox.so 目前仍是 GOOS=android 构建，UI 线程冷调
 * 会 SIGSEGV。来源：libsingbox/go.mod 钉定的 sing-box 版本（当前 v1.11.0）。
 */
export const BUNDLED_SINGBOX_VERSION: string = '1.11.0';
