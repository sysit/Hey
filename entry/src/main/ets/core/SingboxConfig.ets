import { AppSettings } from './Profile';
import { VPN_DATA_SOCKS_HOST, VPN_DATA_SOCKS_PORT } from './XrayConfig';

/**
 * sing-box 配置生成器（预览功能）。
 *
 * 把单个节点的 Xray outbound JSON 转换成 sing-box 的完整运行配置：
 *   本地 SOCKS(mixed) 入站（监听 VPN_DATA_SOCKS 端口，由 libheytun2socks.so 把 Harmony
 *   TUN fd 的流量转发进来——与 Xray 统一走 tun2socks 数据面，不用 tun 入站/OpenTun）+
 *   代理出站 + direct/dns 出站 + 基础路由（DNS 劫持、私网直连、其余走代理）+ 基础 DNS。
 *
 * 覆盖最常见协议：VLESS / VMess / Trojan / Shadowsocks / AnyTLS，传输 tcp/ws/grpc/http(upgrade)，
 * 安全 none/tls/reality。不支持的协议返回 ok=false（不抛异常），由调用方提示。
 *
 * 注意：节点凭据（地址/端口/UUID/密码/TLS）与 Xray 是同一份事实，这里只做"格式翻译"——
 * 字段名、结构、嵌套都按 sing-box schema 重新组织（见 README 里 VLESS 对照）。
 */

type JsonField = Object | string | number | boolean | undefined;
type JsonObject = Record<string, JsonField>;

export interface GeneratedSingboxConfig {
  ok: boolean;
  message: string;
  configJson: string;
}

// ---- sing-box 输出 schema（仅声明用到的字段；可选字段为 undefined 时被 JSON.stringify 省略）----

interface SbUtls {
  enabled: boolean;
  fingerprint: string;
}

interface SbReality {
  enabled: boolean;
  public_key: string;
  short_id: string;
}

interface SbTls {
  enabled: boolean;
  server_name?: string;
  insecure?: boolean;
  alpn?: Array<string>;
  utls?: SbUtls;
  reality?: SbReality;
}

interface SbTransport {
  type: string;
  path?: string;
  headers?: Record<string, string>;
  service_name?: string;
  host?: Array<string>;
}

interface SbOutbound {
  type: string;
  tag: string;
  server?: string;
  server_port?: number;
  uuid?: string;
  flow?: string;
  security?: string;
  alter_id?: number;
  password?: string;
  method?: string;
  network?: string;
  packet_encoding?: string;
  tls?: SbTls;
  transport?: SbTransport;
}

interface SbInbound {
  type: string;
  tag: string;
  listen?: string;
  listen_port?: number;
  sniff?: boolean;
  sniff_override_destination?: boolean;
}

interface SbDnsServer {
  tag: string;
  address: string;
  detour?: string;
}

interface SbDns {
  servers: Array<SbDnsServer>;
  final?: string;
  strategy?: string;
}

interface SbRouteRule {
  protocol?: string;
  outbound?: string;
  ip_is_private?: boolean;
}

interface SbRoute {
  rules: Array<SbRouteRule>;
  final: string;
  auto_detect_interface: boolean;
}

interface SbLog {
  level: string;
  timestamp: boolean;
}

interface SbConfig {
  log: SbLog;
  dns: SbDns;
  inbounds: Array<SbInbound>;
  outbounds: Array<SbOutbound>;
  route: SbRoute;
}

// ---- JSON 读取辅助（沿用 XrayConfig.ets 的 ArkTS 惯用法）----

function asObject(value: JsonField): JsonObject | undefined {
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== 'object' || Array.isArray(value)) {
    return undefined;
  }
  return value as JsonObject;
}

function asString(value: JsonField): string {
  return typeof value === 'string' ? value : '';
}

function asNumber(value: JsonField): number {
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isNaN(parsed) ? 0 : parsed;
  }
  return 0;
}

function asStringArray(value: JsonField): Array<string> {
  if (!Array.isArray(value)) {
    return [];
  }
  const result = new Array<string>();
  for (let index = 0; index < value.length; index++) {
    const item = value[index] as JsonField;
    if (typeof item === 'string' && item.length > 0) {
      result.push(item);
    }
  }
  return result;
}

function firstObject(value: JsonField): JsonObject | undefined {
  if (!Array.isArray(value) || value.length === 0) {
    return undefined;
  }
  return asObject(value[0] as JsonField);
}

// ---- TLS / 传输转换 ----

function buildTls(stream: JsonObject): SbTls | undefined {
  const security = asString(stream['security']);
  if (security === 'tls' || security === 'xtls') {
    const tlsSettings = asObject(stream['tlsSettings']) ?? asObject(stream['xtlsSettings']) ?? {};
    const tls: SbTls = { enabled: true };
    const sni = asString(tlsSettings['serverName']);
    if (sni.length > 0) {
      tls.server_name = sni;
    }
    if (tlsSettings['allowInsecure'] === true) {
      tls.insecure = true;
    }
    const alpn = asStringArray(tlsSettings['alpn']);
    if (alpn.length > 0) {
      tls.alpn = alpn;
    }
    const fingerprint = asString(tlsSettings['fingerprint']);
    if (fingerprint.length > 0) {
      tls.utls = { enabled: true, fingerprint };
    }
    return tls;
  }
  if (security === 'reality') {
    const realitySettings = asObject(stream['realitySettings']) ?? {};
    const tls: SbTls = { enabled: true };
    const sni = asString(realitySettings['serverName']);
    if (sni.length > 0) {
      tls.server_name = sni;
    }
    const fingerprint = asString(realitySettings['fingerprint']);
    // reality 必须有 utls 指纹，缺省给 chrome。
    tls.utls = { enabled: true, fingerprint: fingerprint.length > 0 ? fingerprint : 'chrome' };
    tls.reality = {
      enabled: true,
      public_key: asString(realitySettings['publicKey']),
      short_id: asString(realitySettings['shortId'])
    };
    return tls;
  }
  return undefined;
}

// anytls 这类把 TLS 字段内联在 server 对象（而非 streamSettings）里的协议：直接从 server 组 sing-box TLS。
// anytls 协议本身即「any TLS」，链路恒走 TLS，所以这里恒为 enabled。
function buildServerTls(server: JsonObject): SbTls {
  const tls: SbTls = { enabled: true };
  const sni = asString(server['sni']);
  if (sni.length > 0) {
    tls.server_name = sni;
  }
  if (server['insecure'] === true) {
    tls.insecure = true;
  }
  const alpn = splitCsv(asString(server['alpn']));
  if (alpn.length > 0) {
    tls.alpn = alpn;
  }
  const fingerprint = asString(server['fingerprint']);
  if (fingerprint.length > 0) {
    tls.utls = { enabled: true, fingerprint };
  }
  return tls;
}

function splitCsv(value: string): Array<string> {
  const result = new Array<string>();
  if (value.length === 0) {
    return result;
  }
  const parts = value.split(',');
  for (let index = 0; index < parts.length; index++) {
    const item = parts[index].trim();
    if (item.length > 0) {
      result.push(item);
    }
  }
  return result;
}

function stripEarlyData(path: string): string {
  const queryIndex = path.indexOf('?');
  return queryIndex >= 0 ? path.substring(0, queryIndex) : path;
}

function buildTransport(stream: JsonObject): SbTransport | undefined {
  const network = asString(stream['network']);
  if (network === 'ws' || network === 'websocket') {
    const ws = asObject(stream['wsSettings']) ?? {};
    const transport: SbTransport = { type: 'ws' };
    const path = asString(ws['path']);
    transport.path = path.length > 0 ? stripEarlyData(path) : '/';
    const headers = asObject(ws['headers']);
    const host = headers !== undefined ? asString(headers['Host']) : asString(ws['host']);
    if (host.length > 0) {
      transport.headers = { 'Host': host };
    }
    return transport;
  }
  if (network === 'grpc') {
    const grpc = asObject(stream['grpcSettings']) ?? {};
    const transport: SbTransport = { type: 'grpc' };
    const serviceName = asString(grpc['serviceName']);
    if (serviceName.length > 0) {
      transport.service_name = serviceName;
    }
    return transport;
  }
  if (network === 'h2' || network === 'http') {
    const http = asObject(stream['httpSettings']) ?? {};
    const transport: SbTransport = { type: 'http' };
    const path = asString(http['path']);
    if (path.length > 0) {
      transport.path = path;
    }
    const hosts = asStringArray(http['host']);
    if (hosts.length > 0) {
      transport.host = hosts;
    }
    return transport;
  }
  if (network === 'httpupgrade') {
    const hu = asObject(stream['httpupgradeSettings']) ?? {};
    const transport: SbTransport = { type: 'httpupgrade' };
    const path = asString(hu['path']);
    if (path.length > 0) {
      transport.path = path;
    }
    const host = asString(hu['host']);
    if (host.length > 0) {
      transport.host = [host];
    }
    return transport;
  }
  // tcp / raw（含 http obfs header，sing-box 无直接对应，按裸 tcp 处理）→ 无 transport。
  return undefined;
}

// ---- 各协议 outbound 转换 ----

function convertOutbound(outbound: JsonObject): SbOutbound | null {
  const protocol = asString(outbound['protocol']).toLowerCase();
  const settings = asObject(outbound['settings']) ?? {};
  const stream = asObject(outbound['streamSettings']) ?? {};
  const tls = buildTls(stream);
  const transport = buildTransport(stream);

  if (protocol === 'vless') {
    const server = firstObject(settings['vnext']);
    if (server === undefined) {
      return null;
    }
    const user = firstObject(server['users']);
    if (user === undefined) {
      return null;
    }
    const out: SbOutbound = {
      type: 'vless',
      tag: 'proxy',
      server: asString(server['address']),
      server_port: asNumber(server['port']),
      uuid: asString(user['id']),
      packet_encoding: 'xudp'
    };
    const flow = asString(user['flow']);
    if (flow.length > 0) {
      out.flow = flow;
    }
    if (tls !== undefined) {
      out.tls = tls;
    }
    if (transport !== undefined) {
      out.transport = transport;
    }
    return out;
  }

  if (protocol === 'vmess') {
    const server = firstObject(settings['vnext']);
    if (server === undefined) {
      return null;
    }
    const user = firstObject(server['users']);
    if (user === undefined) {
      return null;
    }
    const security = asString(user['security']);
    const out: SbOutbound = {
      type: 'vmess',
      tag: 'proxy',
      server: asString(server['address']),
      server_port: asNumber(server['port']),
      uuid: asString(user['id']),
      security: security.length > 0 ? security : 'auto',
      alter_id: asNumber(user['alterId'])
    };
    if (tls !== undefined) {
      out.tls = tls;
    }
    if (transport !== undefined) {
      out.transport = transport;
    }
    return out;
  }

  if (protocol === 'trojan') {
    const server = firstObject(settings['servers']);
    if (server === undefined) {
      return null;
    }
    const out: SbOutbound = {
      type: 'trojan',
      tag: 'proxy',
      server: asString(server['address']),
      server_port: asNumber(server['port']),
      password: asString(server['password'])
    };
    if (tls !== undefined) {
      out.tls = tls;
    }
    if (transport !== undefined) {
      out.transport = transport;
    }
    return out;
  }

  if (protocol === 'shadowsocks') {
    const server = firstObject(settings['servers']);
    if (server === undefined) {
      return null;
    }
    const out: SbOutbound = {
      type: 'shadowsocks',
      tag: 'proxy',
      server: asString(server['address']),
      server_port: asNumber(server['port']),
      method: asString(server['method']),
      password: asString(server['password'])
    };
    return out;
  }

  if (protocol === 'anytls') {
    const server = firstObject(settings['servers']);
    if (server === undefined) {
      return null;
    }
    const out: SbOutbound = {
      type: 'anytls',
      tag: 'proxy',
      server: asString(server['address']),
      server_port: asNumber(server['port']),
      password: asString(server['password']),
      tls: buildServerTls(server)
    };
    return out;
  }

  return null;
}

// ---- 完整配置组装 ----

export function buildSingboxConfig(outboundJson: string, settings?: AppSettings): GeneratedSingboxConfig {
  let parsed: JsonObject | undefined;
  try {
    parsed = asObject(JSON.parse(outboundJson) as JsonField);
  } catch (error) {
    return { ok: false, message: 'sing-box: 节点 JSON 解析失败。', configJson: '' };
  }
  if (parsed === undefined) {
    return { ok: false, message: 'sing-box: 节点配置不是有效对象。', configJson: '' };
  }

  const protocol = asString(parsed['protocol']).toLowerCase();
  const proxy = convertOutbound(parsed);
  if (proxy === null) {
    return {
      ok: false,
      message: `sing-box 暂不支持该节点（协议: ${protocol.length > 0 ? protocol : '未知'}）。当前预览仅支持 VLESS / VMess / Trojan / Shadowsocks / AnyTLS。`,
      configJson: ''
    };
  }
  if (proxy.server === undefined || proxy.server.length === 0 || (proxy.server_port ?? 0) <= 0) {
    return { ok: false, message: 'sing-box: 节点缺少有效的地址或端口。', configJson: '' };
  }

  const remoteDns = (settings?.remoteDns ?? '').trim().length > 0 ? (settings as AppSettings).remoteDns.trim() : '1.1.1.1';
  const directDns = (settings?.domesticDns ?? '').trim().length > 0 ? (settings as AppSettings).domesticDns.trim() : '223.5.5.5';
  const ipv6Enabled = settings?.ipv6Enabled === true;
  const logLevel = (settings?.logLevel ?? '').trim().length > 0 ? (settings as AppSettings).logLevel.trim() : 'warn';

  // tun2socks 数据面：sing-box 起一个本地 mixed(SOCKS+HTTP) 入站，监听与 Xray 相同的
  // VPN_DATA_SOCKS 端口，由 libheytun2socks.so 把 Harmony TUN fd 的流量转发进来。
  // 因此 sing-box 不需要 tun 入站 / OpenTun / gvisor tun 栈——甩掉了最难且最易出问题的一环。
  const socksIn: SbInbound = {
    type: 'mixed',
    tag: 'socks-in',
    listen: VPN_DATA_SOCKS_HOST,
    listen_port: VPN_DATA_SOCKS_PORT,
    sniff: true,
    sniff_override_destination: false
  };

  const directOut: SbOutbound = { type: 'direct', tag: 'direct' };
  const dnsOut: SbOutbound = { type: 'dns', tag: 'dns-out' };

  const dns: SbDns = {
    servers: [
      { tag: 'proxy-dns', address: remoteDns, detour: 'proxy' },
      { tag: 'direct-dns', address: directDns, detour: 'direct' }
    ],
    final: 'proxy-dns',
    strategy: ipv6Enabled ? 'prefer_ipv4' : 'ipv4_only'
  };

  const route: SbRoute = {
    rules: [
      { protocol: 'dns', outbound: 'dns-out' },
      { ip_is_private: true, outbound: 'direct' }
    ],
    final: 'proxy',
    auto_detect_interface: false
  };

  const config: SbConfig = {
    log: { level: logLevel, timestamp: true },
    dns,
    inbounds: [socksIn],
    outbounds: [proxy, directOut, dnsOut],
    route
  };

  return { ok: true, message: 'ok', configJson: JSON.stringify(config) };
}
