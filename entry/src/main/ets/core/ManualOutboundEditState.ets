import { readKcpShareParamsFromFinalMask } from './KcpTransport';
import {
  V2RAYNG_DEFAULT_VMESS_SECURITY,
  V2RAYNG_DEFAULT_BROWSER_DIALER_MODE,
  V2RAYNG_KCP_HEADER_TYPE_OPTIONS,
  V2RAYNG_SS_SECURITY_OPTIONS,
  V2RAYNG_SUPPORTED_TRANSPORT_OPTIONS,
  V2RAYNG_TCP_HEADER_TYPE_OPTIONS,
  V2RAYNG_UTLS_FINGERPRINT_OPTIONS,
  V2RAYNG_VMESS_SECURITY_OPTIONS,
  V2RAYNG_XHTTP_MODE_OPTIONS,
  normalizeV2rayNgBrowserDialerMode,
  normalizeV2rayNgStreamAlpn
} from './V2rayNgOptions';

type JsonPrimitive = string | number | boolean;
type JsonValue = Object | JsonPrimitive | undefined;
type JsonRecord = Record<string, JsonValue>;

interface ParsedEndpoint {
  host: string;
  port: string;
}

export interface ManualOutboundEditState {
  valid: boolean;
  message: string;
  protocol: string;
  nodeName: string;
  serverHost: string;
  serverPort: string;
  userIdOrPassword: string;
  proxyUser: string;
  proxyPass: string;
  securityOrMethod: string;
  vmessAlterId: string;
  vlessFlow: string;
  transportType: string;
  transportHost: string;
  transportPath: string;
  transportFinalMask: string;
  transportTcpHeaderType: string;
  transportKcpHeaderType: string;
  transportKcpMtu: string;
  transportKcpTti: string;
  transportGrpcMode: string;
  transportXhttpMode: string;
  transportXhttpExtra: string;
  browserDialerMode: string;
  tlsSecurity: string;
  tlsSni: string;
  tlsAlpn: string;
  tlsAllowInsecure: boolean;
  tlsFingerprint: string;
  tlsEchConfigList: string;
  tlsPinnedPeerCertSha256: string;
  realityPublicKey: string;
  realityShortId: string;
  realitySpiderX: string;
  realityMldsa65Verify: string;
  wgPublicKey: string;
  wgPreSharedKey: string;
  wgReserved: string;
  wgLocalAddress: string;
  wgMtu: string;
  hy2ObfsPassword: string;
  hy2PortHopping: string;
  hy2PortHoppingInterval: string;
  hy2PinSha256: string;
  hy2BandwidthDown: string;
  hy2BandwidthUp: string;
}

export function parseManualOutboundEditState(outboundJson: string, nodeName: string = '', fallbackProtocol: string = ''): ManualOutboundEditState {
  try {
    const root = JSON.parse(outboundJson) as JsonRecord;
    const protocol = normalizeManualEditProtocol(stringValue(root, 'protocol', fallbackProtocol));
    if (!isManualEditProtocol(protocol)) {
      return invalidState('不支持编辑此协议节点。');
    }

    const state = createDefaultManualOutboundEditState(protocol);
    state.nodeName = nodeName.trim().length > 0 ? nodeName.trim() : stringValue(root, 'tag', '');
    const settings = recordValue(root, 'settings');
    if (settings === null) {
      return invalidState('节点配置缺少 settings。');
    }

    if (protocol === 'vless') {
      const server = firstArrayRecord(settings, 'vnext');
      applyServerAddress(state, server);
      const user = firstArrayRecord(server, 'users');
      if (user !== null) {
        state.userIdOrPassword = stringValue(user, 'id', '');
        state.securityOrMethod = stringValue(user, 'encryption', 'none');
        state.vlessFlow = stringValue(user, 'flow', 'none');
      }
    } else if (protocol === 'vmess') {
      const server = firstArrayRecord(settings, 'vnext');
      applyServerAddress(state, server);
      const user = firstArrayRecord(server, 'users');
      if (user !== null) {
        state.userIdOrPassword = stringValue(user, 'id', '');
        state.vmessAlterId = numberString(user, 'alterId', '0');
        state.securityOrMethod = normalizeOption(stringValue(user, 'security', V2RAYNG_DEFAULT_VMESS_SECURITY), V2RAYNG_VMESS_SECURITY_OPTIONS, V2RAYNG_DEFAULT_VMESS_SECURITY);
      }
    } else if (protocol === 'trojan') {
      const server = firstArrayRecord(settings, 'servers');
      applyServerAddress(state, server);
      if (server !== null) {
        state.userIdOrPassword = stringValue(server, 'password', '');
        state.vlessFlow = stringValue(server, 'flow', 'none');
      }
    } else if (protocol === 'ss') {
      const server = firstArrayRecord(settings, 'servers');
      applyServerAddress(state, server);
      if (server !== null) {
        state.userIdOrPassword = stringValue(server, 'password', '');
        state.securityOrMethod = normalizeOption(stringValue(server, 'method', 'aes-128-gcm'), V2RAYNG_SS_SECURITY_OPTIONS, 'aes-128-gcm');
      }
    } else if (protocol === 'socks' || protocol === 'http') {
      const server = firstArrayRecord(settings, 'servers');
      applyServerAddress(state, server);
      const user = firstArrayRecord(server, 'users');
      if (user !== null) {
        state.proxyUser = stringValue(user, 'user', '');
        state.proxyPass = stringValue(user, 'pass', '');
      }
    } else if (protocol === 'wireguard') {
      applyWireguardState(state, settings);
    } else if (protocol === 'hysteria2') {
      applyHysteria2State(state, settings);
    }

    applyStreamState(state, recordValue(root, 'streamSettings'));
    applyBrowserDialerMode(state, root);
    return state;
  } catch (error) {
    return invalidState(`节点配置解析失败：${JSON.stringify(error)}`);
  }
}

export function isManualEditProtocol(protocol: string): boolean {
  const normalized = normalizeManualEditProtocol(protocol);
  return normalized === 'vless' ||
    normalized === 'vmess' ||
    normalized === 'trojan' ||
    normalized === 'ss' ||
    normalized === 'socks' ||
    normalized === 'http' ||
    normalized === 'wireguard' ||
    normalized === 'hysteria2';
}

export function normalizeManualEditProtocol(protocol: string): string {
  const normalized = protocol.trim().toLowerCase();
  if (normalized === 'shadowsocks') {
    return 'ss';
  }
  if (normalized === 'hy2' || normalized === 'hysteria') {
    return 'hysteria2';
  }
  return normalized;
}

function createDefaultManualOutboundEditState(protocol: string): ManualOutboundEditState {
  return {
    valid: true,
    message: '',
    protocol,
    nodeName: '',
    serverHost: '',
    serverPort: protocol === 'ss' ? '8388' : protocol === 'socks' ? '1080' : protocol === 'http' ? '8080' : protocol === 'wireguard' ? '51820' : '443',
    userIdOrPassword: '',
    proxyUser: '',
    proxyPass: '',
    securityOrMethod: protocol === 'vmess' ? V2RAYNG_DEFAULT_VMESS_SECURITY : protocol === 'ss' ? 'aes-128-gcm' : 'none',
    vmessAlterId: '0',
    vlessFlow: 'none',
    transportType: 'tcp',
    transportHost: '',
    transportPath: '',
    transportFinalMask: '',
    transportTcpHeaderType: 'none',
    transportKcpHeaderType: 'none',
    transportKcpMtu: '',
    transportKcpTti: '',
    transportGrpcMode: 'gun',
    transportXhttpMode: 'auto',
    transportXhttpExtra: '',
    browserDialerMode: V2RAYNG_DEFAULT_BROWSER_DIALER_MODE,
    tlsSecurity: 'none',
    tlsSni: '',
    tlsAlpn: protocol === 'hysteria2' ? 'h3' : '',
    tlsAllowInsecure: false,
    tlsFingerprint: 'none',
    tlsEchConfigList: '',
    tlsPinnedPeerCertSha256: '',
    realityPublicKey: '',
    realityShortId: '',
    realitySpiderX: '/',
    realityMldsa65Verify: '',
    wgPublicKey: '',
    wgPreSharedKey: '',
    wgReserved: '0,0,0',
    wgLocalAddress: '172.16.0.2/32',
    wgMtu: '1420',
    hy2ObfsPassword: '',
    hy2PortHopping: '',
    hy2PortHoppingInterval: '',
    hy2PinSha256: '',
    hy2BandwidthDown: '',
    hy2BandwidthUp: ''
  };
}

function invalidState(message: string): ManualOutboundEditState {
  const state = createDefaultManualOutboundEditState('vless');
  state.valid = false;
  state.message = message;
  return state;
}

function applyServerAddress(state: ManualOutboundEditState, server: JsonRecord | null): void {
  if (server === null) {
    return;
  }
  state.serverHost = stringValue(server, 'address', state.serverHost);
  state.serverPort = numberString(server, 'port', state.serverPort);
}

function applyWireguardState(state: ManualOutboundEditState, settings: JsonRecord): void {
  state.userIdOrPassword = stringValue(settings, 'secretKey', '');
  state.wgLocalAddress = csvFromValue(settings['address'], '172.16.0.2/32');
  state.wgReserved = csvFromValue(settings['reserved'], '0,0,0');
  state.wgMtu = numberString(settings, 'mtu', '1420');
  const peer = firstArrayRecord(settings, 'peers');
  if (peer === null) {
    return;
  }
  state.wgPublicKey = stringValue(peer, 'publicKey', '');
  state.wgPreSharedKey = stringValue(peer, 'preSharedKey', '');
  const endpoint = parseEndpoint(stringValue(peer, 'endpoint', ''));
  if (endpoint.host.length > 0) {
    state.serverHost = endpoint.host;
  }
  if (endpoint.port.length > 0) {
    state.serverPort = endpoint.port;
  }
}

function applyHysteria2State(state: ManualOutboundEditState, settings: JsonRecord): void {
  const server = firstArrayRecord(settings, 'servers');
  applyServerAddress(state, server);
  if (server === null) {
    return;
  }
  state.userIdOrPassword = stringValue(server, 'password', '');
  state.tlsSni = stringValue(server, 'sni', '');
  state.tlsAlpn = normalizeV2rayNgStreamAlpn(stringValue(server, 'alpn', 'h3'), 'h3');
  state.tlsAllowInsecure = booleanValue(server, 'insecure', false);
  state.hy2ObfsPassword = stringValue(server, 'obfsPassword', '');
  state.hy2PortHopping = stringValue(server, 'portHopping', '');
  state.hy2PortHoppingInterval = stringValue(server, 'portHoppingInterval', '');
  state.hy2PinSha256 = stringValue(server, 'pinSHA256', '');
  state.hy2BandwidthDown = stringValue(server, 'bandwidthDown', '');
  state.hy2BandwidthUp = stringValue(server, 'bandwidthUp', '');
}

function applyStreamState(state: ManualOutboundEditState, stream: JsonRecord | null): void {
  if (stream === null) {
    return;
  }
  const network = normalizeOption(stringValue(stream, 'network', 'tcp'), V2RAYNG_SUPPORTED_TRANSPORT_OPTIONS, 'tcp');
  state.transportType = network;
  const security = stringValue(stream, 'security', 'none').toLowerCase();
  if (security === 'tls' || security === 'reality') {
    state.tlsSecurity = security;
    applyTlsState(state, recordValue(stream, security === 'tls' ? 'tlsSettings' : 'realitySettings'), security);
  }

  if (network === 'tcp') {
    const header = recordValue(recordValue(stream, 'tcpSettings'), 'header');
    state.transportTcpHeaderType = normalizeOption(stringValue(header, 'type', 'none'), V2RAYNG_TCP_HEADER_TYPE_OPTIONS, 'none');
    const request = recordValue(header, 'request');
    state.transportHost = csvFromValue(recordValue(request, 'headers')?.['Host'], '');
    state.transportPath = csvFromValue(request?.['path'], '');
  } else if (network === 'kcp') {
    const kcpSettings = recordValue(stream, 'kcpSettings');
    state.transportKcpMtu = numberString(kcpSettings, 'mtu', '');
    state.transportKcpTti = numberString(kcpSettings, 'tti', '');
    const finalMask = objectValue(stream, 'finalmask');
    const kcpParams = readKcpShareParamsFromFinalMask(finalMask);
    state.transportKcpHeaderType = normalizeOption(kcpParams.headerType, V2RAYNG_KCP_HEADER_TYPE_OPTIONS, 'none');
    state.transportHost = kcpParams.host;
    state.transportPath = kcpParams.seed;
  } else if (network === 'ws') {
    const wsSettings = recordValue(stream, 'wsSettings');
    state.transportPath = stringValue(wsSettings, 'path', '');
    state.transportHost = stringValue(recordValue(wsSettings, 'headers'), 'Host', '');
  } else if (network === 'httpupgrade') {
    const settings = recordValue(stream, 'httpupgradeSettings');
    state.transportPath = stringValue(settings, 'path', '');
    state.transportHost = stringValue(settings, 'host', '');
  } else if (network === 'grpc') {
    const settings = recordValue(stream, 'grpcSettings');
    state.transportPath = stringValue(settings, 'serviceName', '');
    state.transportHost = stringValue(settings, 'authority', '');
    state.transportGrpcMode = booleanValue(settings, 'multiMode', false) ? 'multi' : 'gun';
  } else if (network === 'h2') {
    const settings = recordValue(stream, 'httpSettings');
    state.transportPath = stringValue(settings, 'path', '');
    state.transportHost = csvFromValue(settings?.['host'], '');
  } else if (network === 'xhttp') {
    const settings = recordValue(stream, 'xhttpSettings');
    state.transportPath = stringValue(settings, 'path', '');
    state.transportHost = stringValue(settings, 'host', '');
    state.transportXhttpMode = normalizeOption(stringValue(settings, 'mode', 'auto'), V2RAYNG_XHTTP_MODE_OPTIONS, 'auto');
    const extra = objectValue(settings, 'extra');
    if (extra !== undefined) {
      state.transportXhttpExtra = JSON.stringify(extra, null, 2);
    }
  }

  const finalMask = objectValue(stream, 'finalmask');
  if (finalMask !== undefined) {
    state.transportFinalMask = JSON.stringify(finalMask, null, 2);
  }
}

function applyBrowserDialerMode(state: ManualOutboundEditState, root: JsonRecord): void {
  if (state.transportType !== 'ws' && state.transportType !== 'xhttp') {
    state.browserDialerMode = V2RAYNG_DEFAULT_BROWSER_DIALER_MODE;
    return;
  }
  state.browserDialerMode = normalizeV2rayNgBrowserDialerMode(stringValue(root, 'browserDialerMode', V2RAYNG_DEFAULT_BROWSER_DIALER_MODE));
}

function applyTlsState(state: ManualOutboundEditState, tls: JsonRecord | null, security: string): void {
  if (tls === null) {
    return;
  }
  state.tlsSni = stringValue(tls, 'serverName', '');
  state.tlsAlpn = normalizeV2rayNgStreamAlpn(csvFromValue(tls['alpn'], ''), '');
  state.tlsAllowInsecure = booleanValue(tls, 'allowInsecure', false);
  state.tlsFingerprint = normalizeOption(stringValue(tls, 'fingerprint', 'none'), V2RAYNG_UTLS_FINGERPRINT_OPTIONS, 'none');
  state.tlsEchConfigList = stringValue(tls, 'echConfigList', '');
  state.tlsPinnedPeerCertSha256 = stringValue(tls, 'pinnedPeerCertSha256', '');
  if (security === 'reality') {
    state.realityPublicKey = stringValue(tls, 'publicKey', '');
    state.realityShortId = stringValue(tls, 'shortId', '');
    state.realitySpiderX = stringValue(tls, 'spiderX', '/');
    state.realityMldsa65Verify = stringValue(tls, 'mldsa65Verify', '');
  }
}

function normalizeOption(value: string, options: Array<string>, fallback: string): string {
  const trimmed = value.trim();
  if (options.indexOf(trimmed) >= 0) {
    return trimmed;
  }
  return fallback;
}

function recordValue(record: JsonRecord | null, key: string): JsonRecord | null {
  if (record === null) {
    return null;
  }
  const value = record[key];
  if (value !== undefined && value !== null && typeof value === 'object' && !Array.isArray(value)) {
    return value as JsonRecord;
  }
  return null;
}

function objectValue(record: JsonRecord | null, key: string): Object | undefined {
  if (record === null) {
    return undefined;
  }
  const value = record[key];
  if (value !== undefined && value !== null && typeof value === 'object') {
    return value as Object;
  }
  return undefined;
}

function firstArrayRecord(record: JsonRecord | null, key: string): JsonRecord | null {
  if (record === null) {
    return null;
  }
  return firstRecord(record[key]);
}

function firstRecord(value: JsonValue | null): JsonRecord | null {
  if (!Array.isArray(value) || value.length === 0) {
    return null;
  }
  const first = value[0] as JsonValue;
  if (first !== undefined && first !== null && typeof first === 'object' && !Array.isArray(first)) {
    return first as JsonRecord;
  }
  return null;
}

function stringValue(record: JsonRecord | null, key: string, fallback: string): string {
  if (record === null) {
    return fallback;
  }
  const value = record[key];
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  return fallback;
}

function numberString(record: JsonRecord | null, key: string, fallback: string): string {
  if (record === null) {
    return fallback;
  }
  const value = record[key];
  if (typeof value === 'number' && !Number.isNaN(value)) {
    return String(value);
  }
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.trim();
  }
  return fallback;
}

function booleanValue(record: JsonRecord | null, key: string, fallback: boolean): boolean {
  if (record === null) {
    return fallback;
  }
  const value = record[key];
  if (typeof value === 'boolean') {
    return value;
  }
  return fallback;
}

function csvFromValue(value: JsonValue | null, fallback: string): string {
  if (Array.isArray(value)) {
    const parts = new Array<string>();
    for (let index = 0; index < value.length; index++) {
      const item = value[index] as JsonValue;
      if (typeof item === 'string' || typeof item === 'number') {
        parts.push(String(item));
      }
    }
    return parts.length > 0 ? parts.join(',') : fallback;
  }
  if (typeof value === 'string' || typeof value === 'number') {
    return String(value);
  }
  return fallback;
}

function parseEndpoint(endpoint: string): ParsedEndpoint {
  const trimmed = endpoint.trim();
  if (trimmed.length === 0) {
    return makeParsedEndpoint('', '');
  }
  if (trimmed.startsWith('[')) {
    const closeIndex = trimmed.indexOf(']');
    if (closeIndex > 0) {
      const host = trimmed.substring(1, closeIndex);
      const rest = trimmed.substring(closeIndex + 1);
      const port = rest.startsWith(':') ? rest.substring(1) : '';
      return makeParsedEndpoint(host, port);
    }
  }
  const separator = trimmed.lastIndexOf(':');
  if (separator > 0 && separator < trimmed.length - 1) {
    return makeParsedEndpoint(trimmed.substring(0, separator), trimmed.substring(separator + 1));
  }
  return makeParsedEndpoint(trimmed, '');
}

function makeParsedEndpoint(host: string, port: string): ParsedEndpoint {
  return {
    host,
    port
  };
}
