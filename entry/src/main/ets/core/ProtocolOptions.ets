export const FLOW_OPTIONS: Array<string> = [
  'none',
  'xtls-rprx-vision',
  'xtls-rprx-vision-udp443'
];

export const UTLS_FINGERPRINT_OPTIONS: Array<string> = [
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

export const DEFAULT_VMESS_SECURITY: string = 'chacha20-poly1305';

export const VMESS_SECURITY_OPTIONS: Array<string> = [
  DEFAULT_VMESS_SECURITY,
  'aes-128-gcm',
  'auto',
  'none',
  'zero'
];

export const SS_SECURITY_OPTIONS: Array<string> = [
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

export const SUPPORTED_TRANSPORT_OPTIONS: Array<string> = [
  'tcp',
  'kcp',
  'ws',
  'httpupgrade',
  'xhttp',
  'h2',
  'grpc'
];

export const TCP_HEADER_TYPE_OPTIONS: Array<string> = [
  'none',
  'http'
];

export const KCP_HEADER_TYPE_OPTIONS: Array<string> = [
  'none',
  'srtp',
  'utp',
  'wechat-video',
  'dtls',
  'wireguard',
  'dns'
];

export const XHTTP_MODE_OPTIONS: Array<string> = [
  'auto',
  'packet-up',
  'stream-up',
  'stream-one'
];

export const DEFAULT_XHTTP_MODE: string = 'auto';

export function normalizeXhttpMode(value: string, fallback: string = DEFAULT_XHTTP_MODE): string {
  const trimmed = value.trim();
  if (XHTTP_MODE_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  if (XHTTP_MODE_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return DEFAULT_XHTTP_MODE;
}

export const BROWSER_DIALER_MODE_OPTIONS: Array<string> = [
  'Disable',
  'OkHttp',
  'WebView'
];

export const DEFAULT_BROWSER_DIALER_MODE: string = 'Disable';

export function normalizeBrowserDialerMode(
  value: string,
  fallback: string = DEFAULT_BROWSER_DIALER_MODE
): string {
  const trimmed = value.trim();
  for (let index = 0; index < BROWSER_DIALER_MODE_OPTIONS.length; index++) {
    const option = BROWSER_DIALER_MODE_OPTIONS[index];
    if (trimmed === option || trimmed.toLowerCase() === option.toLowerCase()) {
      return option;
    }
  }
  if (BROWSER_DIALER_MODE_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return DEFAULT_BROWSER_DIALER_MODE;
}

export const GRPC_MODE_OPTIONS: Array<string> = [
  'gun',
  'multi'
];

export const STREAM_ALPN_OPTIONS: Array<string> = [
  '',
  'h3',
  'h2',
  'http/1.1',
  'h3,h2,http/1.1',
  'h3,h2',
  'h2,http/1.1'
];

export const DEFAULT_STREAM_ALPN: string = '';

export const HYSTERIA2_SECURITY_OPTIONS: Array<string> = [
  'none',
  'tls'
];

export const DEFAULT_HYSTERIA2_SECURITY: string = 'tls';

export function normalizeHysteria2Security(
  value: string,
  fallback: string = DEFAULT_HYSTERIA2_SECURITY
): string {
  const trimmed = value.trim();
  if (HYSTERIA2_SECURITY_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  if (HYSTERIA2_SECURITY_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return DEFAULT_HYSTERIA2_SECURITY;
}

export function normalizeStreamAlpn(value: string, fallback: string = DEFAULT_STREAM_ALPN): string {
  const trimmed = value.trim();
  if (STREAM_ALPN_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  if (STREAM_ALPN_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return DEFAULT_STREAM_ALPN;
}

export function normalizeStreamAlpnWithFallback(value: string, fallback: string): string {
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    if (STREAM_ALPN_OPTIONS.indexOf(fallback) >= 0) {
      return fallback;
    }
    return DEFAULT_STREAM_ALPN;
  }
  return normalizeStreamAlpn(trimmed, fallback);
}

export const MUX_XUDP_QUIC_OPTIONS: Array<string> = [
  'reject',
  'allow',
  'skip'
];

export const DEFAULT_MUX_XUDP_QUIC: string = 'reject';

export function normalizeMuxXudpQuic(value: string, fallback: string = DEFAULT_MUX_XUDP_QUIC): string {
  const trimmed = value.trim();
  if (MUX_XUDP_QUIC_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  if (MUX_XUDP_QUIC_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return DEFAULT_MUX_XUDP_QUIC;
}

export const CORE_LOG_LEVEL_OPTIONS: Array<string> = [
  'debug',
  'info',
  'warning',
  'error',
  'none'
];

export const DEFAULT_CORE_LOG_LEVEL: string = 'warning';

export function normalizeCoreLogLevel(value: string, fallback: string = DEFAULT_CORE_LOG_LEVEL): string {
  const trimmed = value.trim();
  if (CORE_LOG_LEVEL_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  if (CORE_LOG_LEVEL_OPTIONS.indexOf(fallback) >= 0) {
    return fallback;
  }
  return DEFAULT_CORE_LOG_LEVEL;
}

export const FRAGMENT_PACKET_OPTIONS: Array<string> = [
  'tlshello',
  '1-2',
  '1-3',
  '1-5'
];

export const DEFAULT_FRAGMENT_PACKETS: string = 'tlshello';

export function normalizeFragmentPackets(value: string, fallback: string = DEFAULT_FRAGMENT_PACKETS): string {
  const trimmed = value.trim();
  if (FRAGMENT_PACKET_OPTIONS.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  return fallback;
}
