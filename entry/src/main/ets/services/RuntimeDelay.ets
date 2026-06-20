import { DEFAULT_DELAY_TEST_URL_SECONDARY, ProxyProfile, XrayConfigType, resolveDelayTestUrl } from '../core/Profile';
import { DelayTester, DelayTestResult } from './DelayTester';

export interface RuntimeDelayResult extends DelayTestResult {
  url: string;
  fallbackUsed: boolean;
  attemptedUrls: Array<string>;
}

export function canMeasureRuntimeDelayProfile(profile: ProxyProfile): boolean {
  return (profile.configType ?? 'outbound') === 'outbound';
}

export function resolveRuntimeDelayTestUrls(delayTestUrl: string | undefined): Array<string> {
  const primary = resolveDelayTestUrl(delayTestUrl);
  const urls: Array<string> = [primary];
  if (primary !== DEFAULT_DELAY_TEST_URL_SECONDARY) {
    urls.push(DEFAULT_DELAY_TEST_URL_SECONDARY);
  }
  return urls;
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
