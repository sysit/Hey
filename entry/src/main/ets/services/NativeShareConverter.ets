import { extractOutboundsFromXrayConfig } from '../core/XrayOutbounds';
import { normalizeConfigInput } from '../core/XrayConfig';
import { convertNativeShareLinksToXrayJson } from '../native/HeyNative';

export interface NativeShareOutbound {
  name: string;
  outboundJson: string;
  protocol: string;
}

export interface NativeShareConversionResult {
  ok: boolean;
  outbounds: Array<NativeShareOutbound>;
  message: string;
}

export function convertNativeShareTextToOutbounds(text: string): NativeShareConversionResult {
  const converted = convertNativeShareLinksToXrayJson(text);
  if (!converted.ok) {
    return { ok: false, outbounds: [], message: converted.message };
  }

  try {
    const extracted = extractOutboundsFromXrayConfig(converted.configJson);
    const outbounds = new Array<NativeShareOutbound>();
    extracted.forEach(item => {
      const validation = normalizeConfigInput(item.outboundJson, 'outbound');
      if (validation.valid) {
        outbounds.push({
          name: item.name,
          outboundJson: validation.normalizedJson,
          protocol: validation.protocol
        });
      }
    });

    if (outbounds.length === 0) {
      return { ok: false, outbounds: [], message: 'Native share conversion found no supported outbounds.' };
    }
    return { ok: true, outbounds, message: '' };
  } catch (error) {
    return { ok: false, outbounds: [], message: `Native share conversion failed: ${JSON.stringify(error)}` };
  }
}
