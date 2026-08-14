import { ProxyProfile, XrayConfigType, resolveDelayTestUrl } from '../core/Profile';
import { DelayTester, DelayTestResult } from './DelayTester';

export interface RuntimeDelayResult extends DelayTestResult {
  url: string;
  fallbackUsed: boolean;
  attemptedUrls: Array<string>;
}

export function canMeasureRuntimeDelayProfile(profile: ProxyProfile): boolean {
  const configType = profile.configType ?? 'outbound';
  return configType === 'outbound' || configType === 'full' || configType === 'proxy-chain' || configType === 'policy-group';
}

// 只使用用户填写的探测地址，不追加任何内置地址。
// 未填写时返回单个空串，DelayTester 收到空 url 会退化为到服务器的 TCP 握手时延。
export function resolveRuntimeDelayTestUrls(delayTestUrl: string | undefined): Array<string> {
  return [resolveDelayTestUrl(delayTestUrl)];
}

export async function measureRuntimeProfileDelay(
  profile: ProxyProfile,
  datDir: string,
  delayTestUrl: string,
  timeoutMs: number = 8000
): Promise<RuntimeDelayResult> {
  if (!canMeasureRuntimeDelayProfile(profile)) {
    return failedRuntimeDelay('unsupported-config', [], '', false);
  }
  return measureRuntimeOutboundDelay(profile.outboundJson, datDir, delayTestUrl, timeoutMs, profile.configType);
}

export async function measureRuntimeOutboundDelay(
  outboundJson: string,
  datDir: string,
  delayTestUrl: string,
  timeoutMs: number = 8000,
  configType?: XrayConfigType
): Promise<RuntimeDelayResult> {
  const urls = resolveRuntimeDelayTestUrls(delayTestUrl);
  let lastResult: DelayTestResult = {
    ok: false,
    delayMs: -1,
    status: 'not-tested'
  };
  for (let index = 0; index < urls.length; index++) {
    const url = urls[index];
    lastResult = await DelayTester.measureNodeOutbound(outboundJson, datDir, url, timeoutMs, configType);
    if (lastResult.ok) {
      return {
        ok: true,
        delayMs: lastResult.delayMs,
        status: lastResult.status,
        url,
        fallbackUsed: index > 0,
        attemptedUrls: urls.slice(0, index + 1)
      };
    }
  }
  const fallbackUsed = urls.length > 1;
  const lastUrl = urls.length > 0 ? urls[urls.length - 1] : '';
  return failedRuntimeDelay(lastResult.status, urls, lastUrl, fallbackUsed);
}

function failedRuntimeDelay(status: string, attemptedUrls: Array<string>, url: string, fallbackUsed: boolean): RuntimeDelayResult {
  return {
    ok: false,
    delayMs: -1,
    status,
    url,
    fallbackUsed,
    attemptedUrls
  };
}
