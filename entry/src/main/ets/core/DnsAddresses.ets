export const CLIENT_COMPAT_DNS_PROXY: string = '1.1.1.1';
export const CLIENT_COMPAT_DNS_DIRECT: string = '223.5.5.5';
export const CLIENT_COMPAT_DNS_VPN: string = '1.1.1.1';

const CLIENT_COMPAT_IPV4_REGEX: RegExp =
  /^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/;
const CLIENT_COMPAT_IPV6_REGEX: RegExp =
  /^(((?:[0-9A-Fa-f]{1,4}))?((?::[0-9A-Fa-f]{1,4}))*::((?:[0-9A-Fa-f]{1,4}))?((?::[0-9A-Fa-f]{1,4}))*|((?:[0-9A-Fa-f]{1,4}))((?::[0-9A-Fa-f]{1,4})){7})$/;

export function isClientCompatPureIpAddress(value: string): boolean {
  const address = value.trim();
  if (address.length === 0) {
    return false;
  }
  return CLIENT_COMPAT_IPV4_REGEX.test(address) || CLIENT_COMPAT_IPV6_REGEX.test(stripIpAddressBrackets(address));
}

export function isClientCompatCoreDnsAddress(value: string): boolean {
  const address = value.trim();
  return address.startsWith('https') || address.startsWith('tcp') || address.startsWith('quic') || address === 'localhost';
}

export function normalizeClientCompatDnsServers(value: string | undefined, fallback: string, allowCoreDns: boolean = true): Array<string> {
  const source = value === undefined ? fallback : value;
  const result = filterClientCompatDnsServers(source, allowCoreDns);
  if (result.length === 0) {
    return [fallback];
  }
  return result;
}

export function normalizeClientCompatVpnDnsServers(value?: string): Array<string> {
  if (value === undefined || value.trim().length === 0) {
    return [CLIENT_COMPAT_DNS_VPN];
  }
  const result = filterClientCompatDnsServers(value, false);
  if (result.length === 0) {
    return [CLIENT_COMPAT_DNS_VPN];
  }
  return result;
}

function filterClientCompatDnsServers(value: string, allowCoreDns: boolean): Array<string> {
  const result = new Array<string>();
  const parts = value.split(',');
  for (let index = 0; index < parts.length; index++) {
    const address = parts[index].trim();
    if (address.length === 0 || result.indexOf(address) >= 0) {
      continue;
    }
    if (isClientCompatPureIpAddress(address) || (allowCoreDns && isClientCompatCoreDnsAddress(address))) {
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
