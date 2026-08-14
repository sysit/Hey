export interface ClientCompatH2HttpSettings {
  host: Array<string>;
  path: string;
}

export function splitClientCompatH2Hosts(value: string): Array<string> {
  return value.split(',').map((item: string) => item.trim()).filter((item: string) => item.length > 0);
}

export function buildClientCompatH2HttpSettings(hostCsv: string, path: string): ClientCompatH2HttpSettings {
  const normalizedPath = path.trim();
  return {
    host: splitClientCompatH2Hosts(hostCsv),
    path: normalizedPath.length > 0 ? normalizedPath : '/'
  };
}
