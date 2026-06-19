export const V2RAYNG_DNS_PROXY: string = '1.1.1.1';
export const V2RAYNG_DNS_DIRECT: string = '223.5.5.5';
export const V2RAYNG_DNS_VPN: string = '1.1.1.1';

const V2RAYNG_IPV4_REGEX: RegExp =
  /^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/;
const V2RAYNG_IPV6_REGEX: RegExp =
  /^(((?:[0-9A-Fa-f]{1,4}))?((?::[0-9A-Fa-f]{1,4}))*::((?:[0-9A-Fa-f]{1,4}))?((?::[0-9A-Fa-f]{1,4}))*|((?:[0-9A-Fa-f]{1,4}))((?::[0-9A-Fa-f]{1,4})){7})$/;

export function isV2rayNgPureIpAddress(value: string): boolean {
  const address = value.trim();
  if (address.length === 0) {
    return false;
  }
  return V2RAYNG_IPV4_REGEX.test(address) || V2RAYNG_IPV6_REGEX.test(stripIpAddressBrackets(address));
}

export function isV2rayNgCoreDnsAddress(value: string): boolean {
  const address = value.trim();
  return address.startsWith('https') || address.startsWith('tcp') || address.startsWith('quic') || address === 'localhost';
}

export function normalizeV2rayNgDnsServers(value: string | undefined, fallback: string, allowCoreDns: boolean = true): Array<string> {
  const source = value === undefined ? fallback : value;
  const result = filterV2rayNgDnsServers(source, allowCoreDns);
  if (result.length === 0) {
    return [fallback];
  }
  return result;
}

export function normalizeV2rayNgVpnDnsServers(value?: string): Array<string> {
  if (value === undefined || value.trim().length === 0) {
    return [V2RAYNG_DNS_VPN];
  }
  const result = filterV2rayNgDnsServers(value, false);
  if (result.length === 0) {
    return [V2RAYNG_DNS_VPN];
  }
  return result;
}

function filterV2rayNgDnsServers(value: string, allowCoreDns: boolean): Array<string> {
  const result = new Array<string>();
  const parts = value.split(',');
  for (let index = 0; index < parts.length; index++) {
    const address = parts[index].trim();
    if (address.length === 0 || result.indexOf(address) >= 0) {
      continue;
    }
    if (isV2rayNgPureIpAddress(address) || (allowCoreDns && isV2rayNgCoreDnsAddress(address))) {
      result.push(address);
    }
  }
  return result;
}

function stripIpAddressBrackets(value: string): string {
  if (value.startsWith('[') && value.endsWith(']')) {
    return value.substring(1, value.length - 1);
  }
  return value;
}
