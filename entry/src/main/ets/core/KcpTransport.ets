export interface KcpShareParams {
  headerType: string;
  host: string;
  seed: string;
}

interface KcpFinalMaskSettings {
  domain?: string;
  password?: string;
}

interface KcpFinalMaskEntry {
  type: string;
  settings?: KcpFinalMaskSettings;
}

interface KcpFinalMask {
  udp: Array<KcpFinalMaskEntry>;
}

export function normalizeKcpHeaderType(headerType: string): string {
  const normalized = headerType.trim().toLowerCase();
  if (normalized === 'srtp' ||
    normalized === 'utp' ||
    normalized === 'wechat-video' ||
    normalized === 'dtls' ||
    normalized === 'wireguard' ||
    normalized === 'dns') {
    return normalized;
  }
  return 'none';
}

export function buildKcpFinalMask(headerType: string, host: string, seed: string): Object {
  const normalizedHeader = normalizeKcpHeaderType(headerType);
  const udp = new Array<KcpFinalMaskEntry>();
  const trimmedHost = host.trim();
  const trimmedSeed = seed.trim();

  if (normalizedHeader !== 'none') {
    const headerEntry: KcpFinalMaskEntry = {
      type: normalizedHeader === 'wechat-video' ? 'header-wechat' : `header-${normalizedHeader}`
    };
    if (normalizedHeader === 'dns' && trimmedHost.length > 0) {
      headerEntry.settings = {
        domain: trimmedHost
      };
    }
    udp.push(headerEntry);
  }

  if (trimmedSeed.length === 0) {
    udp.push({
      type: 'mkcp-original'
    });
  } else {
    udp.push({
      type: 'mkcp-aes128gcm',
      settings: {
        password: trimmedSeed
      }
    });
  }

  const finalMask: KcpFinalMask = {
    udp
  };
  return finalMask as Object;
}

export function readKcpShareParamsFromFinalMask(finalMask?: Object): KcpShareParams {
  const params: KcpShareParams = {
    headerType: 'none',
    host: '',
    seed: ''
  };
  if (finalMask === undefined) {
    return params;
  }

  const record = finalMask as Record<string, Object>;
  const rawUdp = record['udp'];
  if (!Array.isArray(rawUdp)) {
    return params;
  }

  const entries = rawUdp as Array<KcpFinalMaskEntry>;
  for (let index = 0; index < entries.length; index++) {
    const entry = entries[index];
    const type = typeof entry.type === 'string' ? entry.type : '';
    if (type === 'header-wechat') {
      params.headerType = 'wechat-video';
    } else if (type.startsWith('header-')) {
      params.headerType = normalizeKcpHeaderType(type.substring('header-'.length));
    } else if (type === 'mkcp-aes128gcm') {
      const password = entry.settings?.password ?? '';
      if (password.length > 0) {
        params.seed = password;
      }
    }

    if (params.headerType === 'dns') {
      const domain = entry.settings?.domain ?? '';
      if (domain.length > 0) {
        params.host = domain;
      }
    }
  }
  return params;
}

export function isCanonicalKcpFinalMask(finalMask?: Object): boolean {
  if (finalMask === undefined) {
    return false;
  }
  const params = readKcpShareParamsFromFinalMask(finalMask);
  const canonical = buildKcpFinalMask(params.headerType, params.host, params.seed);
  return JSON.stringify(finalMask) === JSON.stringify(canonical);
}
