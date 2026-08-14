export interface ProtocolH2HttpSettings {
  host: Array<string>;
  path: string;
}

export function splitH2Hosts(value: string): Array<string> {
  return value.split(',').map((item: string) => item.trim()).filter((item: string) => item.length > 0);
}

export function buildH2HttpSettings(hostCsv: string, path: string): ProtocolH2HttpSettings {
  const normalizedPath = path.trim();
  return {
    host: splitH2Hosts(hostCsv),
    path: normalizedPath.length > 0 ? normalizedPath : '/'
  };
}
