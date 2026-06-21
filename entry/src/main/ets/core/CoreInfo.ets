/**
 * 内置 Xray 内核（xtls/xray-core）的版本号 —— 即 `core.Version()` 的返回值。
 *
 * 注意：不要在运行时调用原生 `CGoXrayVersion()` 去取这个值。该函数在为
 * `GOOS=android` 编译、运行于 HarmonyOS 的 libxray.so 里冷调用会触发不可捕获的
 * 原生段错误（SIGSEGV，崩在 Go runtime 的 m/g 线程上下文里）。详见
 * scripts/build_libxray_ohos.sh 与 pages/About.ets。
 *
 * 此常量在重新编译 libxray.so 时由 scripts/build_libxray_ohos.sh 从所锁定的
 * xtls/xray-core 源码（core/core.go 的 Version_x/y/z 常量）自动写入，
 * 与 prebuilt/arm64-v8a/libxray.so 保持同步——请勿手动修改。
 */
export const BUNDLED_XRAY_VERSION: string = '26.6.1';
