export const CLIENT_COMPAT_FLOW_OPTIONS: Array<string> = [
  'none',
  'xtls-rprx-vision',
  'xtls-rprx-vision-udp443'
];

export const CLIENT_COMPAT_UTLS_FINGERPRINT_OPTIONS: Array<string> = [
  'none',
  'chrome',
  'firefox',
  'safari',
  'ios',
  'android',
  'edge',
  '360',
  'qq',
  'random',
  'randomized'
];

export const CLIENT_COMPAT_DEFAULT_VMESS_SECURITY: string = 'chacha20-poly1305';

export const CLIENT_COMPAT_VMESS_SECURITY_OPTIONS: Array<string> = [
  CLIENT_COMPAT_DEFAULT_VMESS_SECURITY,
  'aes-128-gcm',
  'auto',
  'none',
  'zero'
];

export const CLIENT_COMPAT_SS_SECURITY_OPTIONS: Array<string> = [
  'aes-256-gcm',
  'aes-128-gcm',
  'chacha20-poly1305',
  'chacha20-ietf-poly1305',
  'xchacha20-poly1305',
  'xchacha20-ietf-poly1305',
  'none',
  'plain',
  '2022-blake3-aes-128-gcm',
  '2022-blake3-aes-256-gcm',
  '2022-blake3-chacha20-poly1305'
];

export const CLIENT_COMPAT_SUPPORTED_TRANSPORT_OPTIONS: Array<string> = [
  'tcp',
  'kcp',
  'ws',
  'httpupgrade',
  'xhttp',
  'h2',
  'grpc'
];

export const CLIENT_COMPAT_TCP_HEADER_TYPE_OPTIONS: Array<string> = [
  'none',
  'http'
];

export const CLIENT_COMPAT_KCP_HEADER_TYPE_OPTIONS: Array<string> = [
  'none',
  'srtp',
  'utp',
  'wechat-video',
  'dtls',
  'wireguard',
  'dns'
];

export const CLIENT_COMPAT_XHTTP_MODE_OPTIONS: Array<string> = [
  'auto',
  'packet-up',
  'stream-up',
  'stream-one'
];

export const CLIENT_COMPAT_DEFAULT_XHTTP_MODE: string = 'auto';

export function normalizeClientCompatXhttpMode(value: string, fallback: string = CLIENT_COMPAT_DEFAULT_XHTTP_MODE): string {
  const trimmed = value.trim();
  if (CLIENT_COMPAT_XHTTP_MODE_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  if (CLIENT_COMPAT_XHTTP_MODE_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return CLIENT_COMPAT_DEFAULT_XHTTP_MODE;
}

export const CLIENT_COMPAT_BROWSER_DIALER_MODE_OPTIONS: Array<string> = [
  'Disable',
  'OkHttp',
  'WebView'
];

export const CLIENT_COMPAT_DEFAULT_BROWSER_DIALER_MODE: string = 'Disable';

export function normalizeClientCompatBrowserDialerMode(
  value: string,
  fallback: string = CLIENT_COMPAT_DEFAULT_BROWSER_DIALER_MODE
): string {
  const trimmed = value.trim();
  for (let index = 0; index < CLIENT_COMPAT_BROWSER_DIALER_MODE_OPTIONS.length; index++) {
    const option = CLIENT_COMPAT_BROWSER_DIALER_MODE_OPTIONS[index];
    if (trimmed === option || trimmed.toLowerCase() === option.toLowerCase()) {
      return option;
    }
  }
  if (CLIENT_COMPAT_BROWSER_DIALER_MODE_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return CLIENT_COMPAT_DEFAULT_BROWSER_DIALER_MODE;
}

export const CLIENT_COMPAT_GRPC_MODE_OPTIONS: Array<string> = [
  'gun',
  'multi'
];

export const CLIENT_COMPAT_STREAM_ALPN_OPTIONS: Array<string> = [
  '',
  'h3',
  'h2',
  'http/1.1',
  'h3,h2,http/1.1',
  'h3,h2',
  'h2,http/1.1'
];

export const CLIENT_COMPAT_DEFAULT_STREAM_ALPN: string = '';

export const CLIENT_COMPAT_HYSTERIA2_SECURITY_OPTIONS: Array<string> = [
  'none',
  'tls'
];

export const CLIENT_COMPAT_DEFAULT_HYSTERIA2_SECURITY: string = 'tls';

export function normalizeClientCompatHysteria2Security(
  value: string,
  fallback: string = CLIENT_COMPAT_DEFAULT_HYSTERIA2_SECURITY
): string {
  const trimmed = value.trim();
  if (CLIENT_COMPAT_HYSTERIA2_SECURITY_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  if (CLIENT_COMPAT_HYSTERIA2_SECURITY_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return CLIENT_COMPAT_DEFAULT_HYSTERIA2_SECURITY;
}

export function normalizeClientCompatStreamAlpn(value: string, fallback: string = CLIENT_COMPAT_DEFAULT_STREAM_ALPN): string {
  const trimmed = value.trim();
  if (CLIENT_COMPAT_STREAM_ALPN_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  if (CLIENT_COMPAT_STREAM_ALPN_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return CLIENT_COMPAT_DEFAULT_STREAM_ALPN;
}

export function normalizeClientCompatStreamAlpnWithFallback(value: string, fallback: string): string {
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    if (CLIENT_COMPAT_STREAM_ALPN_OPTIONS.indexOf(fallback) >= 0) {
      return fallback;
    }
    return CLIENT_COMPAT_DEFAULT_STREAM_ALPN;
  }
  return normalizeClientCompatStreamAlpn(trimmed, fallback);
}

export const CLIENT_COMPAT_MUX_XUDP_QUIC_OPTIONS: Array<string> = [
  'reject',
  'allow',
  'skip'
];

export const CLIENT_COMPAT_DEFAULT_MUX_XUDP_QUIC: string = 'reject';

export function normalizeClientCompatMuxXudpQuic(value: string, fallback: string = CLIENT_COMPAT_DEFAULT_MUX_XUDP_QUIC): string {
  const trimmed = value.trim();
  if (CLIENT_COMPAT_MUX_XUDP_QUIC_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  if (CLIENT_COMPAT_MUX_XUDP_QUIC_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return CLIENT_COMPAT_DEFAULT_MUX_XUDP_QUIC;
}

export const CLIENT_COMPAT_CORE_LOG_LEVEL_OPTIONS: Array<string> = [
  'debug',
  'info',
  'warning',
  'error',
  'none'
];

export const CLIENT_COMPAT_DEFAULT_CORE_LOG_LEVEL: string = 'warning';

export function normalizeClientCompatCoreLogLevel(value: string, fallback: string = CLIENT_COMPAT_DEFAULT_CORE_LOG_LEVEL): string {
  const trimmed = value.trim();
  if (CLIENT_COMPAT_CORE_LOG_LEVEL_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  if (CLIENT_COMPAT_CORE_LOG_LEVEL_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return CLIENT_COMPAT_DEFAULT_CORE_LOG_LEVEL;
}

export const CLIENT_COMPAT_FRAGMENT_PACKET_OPTIONS: Array<string> = [
  'tlshello',
  '1-2',
  '1-3',
  '1-5'
];

export const CLIENT_COMPAT_DEFAULT_FRAGMENT_PACKETS: string = 'tlshello';

export function normalizeClientCompatFragmentPackets(value: string, fallback: string = CLIENT_COMPAT_DEFAULT_FRAGMENT_PACKETS): string {
  const trimmed = value.trim();
  if (CLIENT_COMPAT_FRAGMENT_PACKET_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  return fallback;
}
