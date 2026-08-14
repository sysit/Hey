// Xray 核心的规则数据文件名。文件名是上游核心的既定约定，与任何地区策略无关。
// 应用不内置任何下载源——用户自行填写 URL 或从本地导入。
export const GEOSITE_FILE_NAME: string = 'geosite.dat';
export const GEOIP_FILE_NAME: string = 'geoip.dat';

export const BUILTIN_GEO_DATA_FILE_NAMES: Array<string> = [
  GEOSITE_FILE_NAME,
  GEOIP_FILE_NAME
];

export function buildAssetDownloadUrl(sourceUrl: string, fileName: string): string {
  const normalizedSource = sourceUrl.endsWith('/') ? sourceUrl : `${sourceUrl}/`;
  return `${normalizedSource}${fileName}`;
}
