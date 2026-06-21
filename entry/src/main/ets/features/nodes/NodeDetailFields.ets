// 把节点的 outboundJson 解析成「分组 + 字段」结构，供节点详情页只读展示。
// 参照 V2rayNG ServerActivity 的字段维度，覆盖 基本信息 / 传输层 / 安全(TLS·REALITY)。
// 纯逻辑、无闭包、严格类型，与 NodeOperations.ets 的安全取值风格保持一致。

// 单个展示字段。labelKey 为 i18n key；sensitive=true 的字段（UUID/密码等）在 UI 默认打码。
export interface NodeDetailField {
  labelKey: string;
  value: string;
  sensitive: boolean;
}

// 一个分组（基本信息 / 传输层 / 安全）。titleKey 为 i18n key。
export interface NodeDetailSection {
  titleKey: string;
  fields: Array<NodeDetailField>;
}

// 主入口：解析 outboundJson，返回非空分组列表。解析失败返回空数组。
export function buildNodeDetailSections(outboundJson: string, protocol: string): Array<NodeDetailSection> {
  const sections: Array<NodeDetailSection> = [];
  let outbound: Record<string, Object> | null = null;
  try {
    outbound = objectValue(JSON.parse(outboundJson) as Object);
  } catch (_error) {
    return sections;
  }
  if (outbound === null) {
    return sections;
  }

  const parsedProtocol: string = stringValue(outbound['protocol']).toLowerCase();
  const proto: string = parsedProtocol.length > 0 ? parsedProtocol : protocol.toLowerCase();
  const settings: Record<string, Object> | null = objectValue(outbound['settings']);
  const stream: Record<string, Object> | null = objectValue(outbound['streamSettings']);

  pushSection(sections, 'node.section.basics', buildBasics(proto, settings));
  if (stream !== null) {
    pushSection(sections, 'node.section.transport', buildTransport(stream));
    pushSection(sections, 'node.section.security', buildSecurity(stream));
  }
  return sections;
}

// ---- 基本信息：地址/端口/认证/加密，按协议分支 ----
function buildBasics(proto: string, settings: Record<string, Object> | null): Array<NodeDetailField> {
  const fields: Array<NodeDetailField> = [];
  pushField(fields, 'node.field.protocol', proto.toUpperCase(), false);
  if (settings === null) {
    return fields;
  }

  if (proto === 'vless' || proto === 'vmess') {
    const server: Record<string, Object> | null = firstRecord(settings['vnext']);
    const user: Record<string, Object> | null = firstRecord(server?.['users']);
    pushField(fields, 'node.field.address', stringValue(server?.['address']), false);
    pushField(fields, 'node.field.port', stringValue(server?.['port']), false);
    pushField(fields, 'node.field.id', stringValue(user?.['id']), true);
    if (proto === 'vmess') {
      pushField(fields, 'node.field.encryption', stringValue(user?.['security']), false);
      const alterId: string = stringValue(user?.['alterId']);
      if (alterId.length > 0 && alterId !== '0') {
        pushField(fields, 'node.field.alterId', alterId, false);
      }
    } else {
      pushField(fields, 'node.field.encryption', stringValue(user?.['encryption']), false);
      pushField(fields, 'node.field.flow', stringValue(user?.['flow']), false);
    }
    return fields;
  }

  if (proto === 'wireguard') {
    const peer: Record<string, Object> | null = firstRecord(settings['peers']);
    pushField(fields, 'node.field.address', stringValue(peer?.['endpoint']), false);
    pushField(fields, 'node.field.secretKey', stringValue(settings['secretKey']), true);
    pushField(fields, 'node.field.publicKey', stringValue(peer?.['publicKey']), false);
    pushField(fields, 'node.field.preSharedKey', stringValue(peer?.['preSharedKey']), true);
    return fields;
  }

  const server: Record<string, Object> | null = firstRecord(settings['servers']);
  pushField(fields, 'node.field.address', stringValue(server?.['address']), false);
  pushField(fields, 'node.field.port', stringValue(server?.['port']), false);
  if (proto === 'shadowsocks') {
    pushField(fields, 'node.field.encryption', stringValue(server?.['method']), false);
    pushField(fields, 'node.field.password', stringValue(server?.['password']), true);
  } else if (proto === 'trojan') {
    pushField(fields, 'node.field.password', stringValue(server?.['password']), true);
    pushField(fields, 'node.field.flow', stringValue(server?.['flow']), false);
  } else if (proto === 'hysteria2') {
    pushField(fields, 'node.field.password', stringValue(server?.['password']), true);
    pushField(fields, 'node.field.obfsPassword', stringValue(server?.['obfsPassword']), true);
    pushField(fields, 'node.field.portHopping', stringValue(server?.['portHopping']), false);
  } else if (proto === 'anytls') {
    pushField(fields, 'node.field.password', stringValue(server?.['password']), true);
  } else {
    const user: Record<string, Object> | null = firstRecord(server?.['users']);
    pushField(fields, 'node.field.username', stringValue(user?.['user']), false);
    pushField(fields, 'node.field.password', stringValue(user?.['pass']), true);
  }
  return fields;
}

// ---- 传输层：按 network 分支显示 path/host/serviceName/mode/mtu 等 ----
function buildTransport(stream: Record<string, Object>): Array<NodeDetailField> {
  const fields: Array<NodeDetailField> = [];
  const network: string = stringValue(stream['network']).length > 0 ? stringValue(stream['network']) : 'tcp';
  pushField(fields, 'node.field.network', network, false);

  const ws: Record<string, Object> | null = objectValue(stream['wsSettings']);
  if (ws !== null) {
    pushField(fields, 'node.field.path', stringValue(ws['path']), false);
    pushField(fields, 'node.field.host', stringValue(objectValue(ws['headers'])?.['Host']), false);
    return fields;
  }

  const grpc: Record<string, Object> | null = objectValue(stream['grpcSettings']);
  if (grpc !== null) {
    pushField(fields, 'node.field.serviceName', stringValue(grpc['serviceName']), false);
    if (stringValue(grpc['multiMode']) === 'true') {
      pushField(fields, 'node.field.mode', 'multi', false);
    }
    return fields;
  }

  const httpup: Record<string, Object> | null = objectValue(stream['httpupgradeSettings']);
  if (httpup !== null) {
    pushField(fields, 'node.field.path', stringValue(httpup['path']), false);
    pushField(fields, 'node.field.host', stringValue(httpup['host']), false);
    return fields;
  }

  const xhttp: Record<string, Object> | null = objectValue(stream['xhttpSettings']);
  if (xhttp !== null) {
    pushField(fields, 'node.field.path', stringValue(xhttp['path']), false);
    pushField(fields, 'node.field.host', stringValue(xhttp['host']), false);
    pushField(fields, 'node.field.mode', stringValue(xhttp['mode']), false);
    return fields;
  }

  const http: Record<string, Object> | null = objectValue(stream['httpSettings']);
  if (http !== null) {
    pushField(fields, 'node.field.host', joinStringArray(http['host']), false);
    pushField(fields, 'node.field.path', stringValue(http['path']), false);
    return fields;
  }

  const kcp: Record<string, Object> | null = objectValue(stream['kcpSettings']);
  if (kcp !== null) {
    pushField(fields, 'node.field.mtu', stringValue(kcp['mtu']), false);
    pushField(fields, 'node.field.tti', stringValue(kcp['tti']), false);
    return fields;
  }

  const tcp: Record<string, Object> | null = objectValue(stream['tcpSettings']);
  if (tcp !== null) {
    const header: Record<string, Object> | null = objectValue(tcp['header']);
    const headerType: string = stringValue(header?.['type']);
    if (headerType.length > 0 && headerType !== 'none') {
      pushField(fields, 'node.field.headerType', headerType, false);
      const request: Record<string, Object> | null = objectValue(header?.['request']);
      const headers: Record<string, Object> | null = objectValue(request?.['headers']);
      pushField(fields, 'node.field.host', joinStringArray(headers?.['Host']), false);
      pushField(fields, 'node.field.path', joinStringArray(request?.['path']), false);
    }
  }
  return fields;
}

// ---- 安全：security=tls/reality 时展示 SNI/指纹/ALPN/REALITY 公钥等 ----
function buildSecurity(stream: Record<string, Object>): Array<NodeDetailField> {
  const fields: Array<NodeDetailField> = [];
  const security: string = stringValue(stream['security']).toLowerCase();
  if (security !== 'tls' && security !== 'reality') {
    return fields;
  }
  pushField(fields, 'node.field.security', security.toUpperCase(), false);

  const tls: Record<string, Object> | null = objectValue(stream['tlsSettings']) ?? objectValue(stream['realitySettings']);
  if (tls !== null) {
    pushField(fields, 'node.field.sni', stringValue(tls['serverName']), false);
    pushField(fields, 'node.field.fingerprint', stringValue(tls['fingerprint']), false);
    pushField(fields, 'node.field.alpn', joinStringArray(tls['alpn']), false);
    if (stringValue(tls['allowInsecure']) === 'true') {
      pushField(fields, 'node.field.allowInsecure', 'true', false);
    }
    pushField(fields, 'node.field.publicKey', stringValue(tls['publicKey']), false);
    pushField(fields, 'node.field.shortId', stringValue(tls['shortId']), false);
    pushField(fields, 'node.field.spiderX', stringValue(tls['spiderX']), false);
  }
  return fields;
}

// ---- 工具 ----

function pushSection(sections: Array<NodeDetailSection>, titleKey: string, fields: Array<NodeDetailField>): void {
  if (fields.length > 0) {
    sections.push({ titleKey, fields });
  }
}

function pushField(fields: Array<NodeDetailField>, labelKey: string, value: string, sensitive: boolean): void {
  const trimmed: string = value.trim();
  if (trimmed.length > 0) {
    fields.push({ labelKey, value: trimmed, sensitive });
  }
}

function joinStringArray(value: Object | undefined): string {
  if (!Array.isArray(value)) {
    return '';
  }
  const values: Array<Object> = value as Array<Object>;
  const parts: Array<string> = [];
  for (let i = 0; i < values.length; i++) {
    const part: string = stringValue(values[i]);
    if (part.length > 0) {
      parts.push(part);
    }
  }
  return parts.join(', ');
}

function firstRecord(value: Object | undefined): Record<string, Object> | null {
  if (!Array.isArray(value) || value.length === 0) {
    return null;
  }
  const values: Array<Object> = value as Array<Object>;
  return objectValue(values[0]);
}

function objectValue(value: Object | undefined): Record<string, Object> | null {
  if (value === undefined || value === null || typeof value !== 'object' || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, Object>;
}

function stringValue(value: Object | undefined): string {
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return `${value}`;
  }
  return '';
}
