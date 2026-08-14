/**
 * uTLS 指纹兼容性重映射。
 *
 * 内置 xray-core v1.250803.0 与 sing-box 的 chrome 系 uTLS 指纹会启用后量子
 * X25519MLKEM768 密钥交换，而这两个核心从 MLKEM key share 推导 AuthKey 的方式
 * 与服务端(纯 X25519)不一致，导致服务端解不开 ClientHello.SessionId 里的认证 →
 * 判 `processed invalid connection` → 连接失败。
 *
 * 认证本身不依赖指纹取值，因此在核心修复 MLKEM 之前，把会触发 MLKEM 的取值
 * 重映射为纯 X25519 的 safari。其余取值保持不变。
 */

// 会启用 X25519MLKEM768 的 uTLS 指纹。
const REALITY_MLKEM_FINGERPRINTS: Array<string> = ['chrome', 'edge', 'firefox', 'random', 'randomized'];
// 已知不使用 MLKEM、REALITY 握手可用的替代指纹(走纯 X25519)。
const REALITY_SAFE_FINGERPRINT: string = 'safari';

export function coerceRealitySafeFingerprint(fingerprint: string): string {
  const current = fingerprint.trim().toLowerCase();
  if (current.length === 0 || REALITY_MLKEM_FINGERPRINTS.indexOf(current) >= 0) {
    return REALITY_SAFE_FINGERPRINT;
  }
  return fingerprint;
}
