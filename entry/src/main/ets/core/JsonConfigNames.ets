import { XrayConfigType } from './Profile';

export function defaultJsonConfigNodeName(configType?: XrayConfigType): string {
  if (configType === 'full') {
    return '完整配置导入';
  }
  if (configType === 'proxy-chain') {
    return '代理链导入';
  }
  if (configType === 'policy-group') {
    return '策略组导入';
  }
  return 'JSON导入';
}

export function resolveJsonConfigNodeName(configJson: string, configType?: XrayConfigType, fallback: string = ''): string {
  const trimmedFallback = fallback.trim();
  try {
    const obj = JSON.parse(configJson) as Record<string, Object>;
    const tag = stringField(obj, 'tag');
    if (tag.length > 0) {
      return tag;
    }
    if (configType === 'full' || configType === 'proxy-chain' || configType === 'policy-group') {
      const remarks = stringField(obj, 'remarks');
      if (remarks.length > 0) {
        return remarks;
      }
      const name = stringField(obj, 'name');
      if (name.length > 0) {
        return name;
      }
    }
  } catch (error) {
  }
  return trimmedFallback.length > 0 ? trimmedFallback : defaultJsonConfigNodeName(configType);
}

function stringField(obj: Record<string, Object>, key: string): string {
  const value = obj[key];
  return typeof value === 'string' ? value.trim() : '';
}
