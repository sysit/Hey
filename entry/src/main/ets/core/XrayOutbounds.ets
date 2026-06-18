export interface ExtractedXrayOutbound {
  outboundJson: string;
  name: string;
  protocol: string;
}

interface XrayOutboundDocument {
  protocol?: string;
  tag?: string;
  remarks?: string;
  name?: string;
  settings?: Object;
}

interface XrayConfigDocument {
  outbounds?: Array<XrayOutboundDocument>;
  outbound?: XrayOutboundDocument;
}

export function extractOutboundsFromXrayConfig(configJson: string): Array<ExtractedXrayOutbound> {
  const result = new Array<ExtractedXrayOutbound>();
  const config = JSON.parse(configJson) as XrayConfigDocument;
  const outbounds = collectOutbounds(config);

  outbounds.forEach(outbound => {
    const protocol = normalizeText(outbound.protocol).toLowerCase();
    if (protocol.length === 0 || outbound.settings === undefined) {
      return;
    }
    result.push({
      outboundJson: JSON.stringify(outbound, null, 2),
      name: resolveOutboundName(outbound, result.length),
      protocol
    });
  });
  return result;
}

function collectOutbounds(config: XrayConfigDocument): Array<XrayOutboundDocument> {
  if (Array.isArray(config.outbounds)) {
    return config.outbounds;
  }
  if (config.outbound !== undefined) {
    const outbounds = new Array<XrayOutboundDocument>();
    outbounds.push(config.outbound);
    return outbounds;
  }
  return [];
}

function resolveOutboundName(outbound: XrayOutboundDocument, index: number): string {
  const candidates = [outbound.tag, outbound.remarks, outbound.name];
  for (let candidateIndex = 0; candidateIndex < candidates.length; candidateIndex++) {
    const value = normalizeText(candidates[candidateIndex]);
    if (value.length > 0) {
      return value;
    }
  }
  const protocol = normalizeText(outbound.protocol).toUpperCase();
  return protocol.length > 0 ? `${protocol}-${index + 1}` : `Node-${index + 1}`;
}

function normalizeText(value: string | undefined): string {
  return value === undefined ? '' : value.trim();
}
