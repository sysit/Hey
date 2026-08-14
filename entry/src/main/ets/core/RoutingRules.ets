import { RoutingRule } from './Profile';

// 导入失败原因。出厂不带任何规则，导入是用户建立规则表的主路径，
// 因此失败必须能说清是哪一步出的问题，而不是只报一个"失败"。
export type RoutingImportFailure = 'none' | 'empty' | 'invalidJson' | 'notArray' | 'noValidRule';

// 被跳过的单条规则：index 为 1 起的原始下标，便于直接告诉用户第几条有问题。
export interface RoutingRuleSkip {
  index: number;
  reason: string;
}

export interface RoutingRuleImportResult {
  success: boolean;
  rules: Array<RoutingRule>;
  count: number;
  failure: RoutingImportFailure;
  skipped: Array<RoutingRuleSkip>;
}

function failedImport(failure: RoutingImportFailure, skipped: Array<RoutingRuleSkip> = []): RoutingRuleImportResult {
  return { success: false, rules: [], count: 0, failure, skipped };
}

export function importRoutingRulesJson(existing: Array<RoutingRule>, content: string): RoutingRuleImportResult {
  const trimmed = content.trim();
  if (trimmed.length === 0) {
    return failedImport('empty');
  }

  let rawRules: Array<RoutingRule>;
  try {
    rawRules = JSON.parse(trimmed) as Array<RoutingRule>;
  } catch (error) {
    return failedImport('invalidJson');
  }
  if (!Array.isArray(rawRules)) {
    return failedImport('notArray');
  }

  const imported = new Array<RoutingRule>();
  const skipped = new Array<RoutingRuleSkip>();
  for (let index = 0; index < rawRules.length; index++) {
    const raw = rawRules[index];
    if (raw === null || raw === undefined || typeof raw !== 'object' || Array.isArray(raw)) {
      skipped.push({ index: index + 1, reason: 'notObject' });
      continue;
    }
    const rule = normalizeRoutingRule(raw, `imported-routing-rule-${index + 1}`);
    if (!hasRoutingMatcher(rule)) {
      // 一条规则至少要有一个匹配条件（域名/IP/进程/端口/协议/网络），否则永不命中。
      skipped.push({ index: index + 1, reason: 'noMatcher' });
      continue;
    }
    imported.push(rule);
  }

  if (imported.length === 0) {
    return failedImport('noValidRule', skipped);
  }

  return {
    success: true,
    rules: preserveLockedRules(existing).concat(imported),
    count: imported.length,
    failure: 'none',
    skipped
  };
}

export function exportRoutingRulesJson(rules: Array<RoutingRule>): string {
  return JSON.stringify(copyRoutingRules(rules), null, 2);
}

export function copyRoutingRules(rules: Array<RoutingRule>): Array<RoutingRule> {
  const result = new Array<RoutingRule>();
  for (let index = 0; index < rules.length; index++) {
    result.push(copyRoutingRule(rules[index]));
  }
  return result;
}

export function normalizeRoutingRules(rules: Array<RoutingRule> | undefined): Array<RoutingRule> {
  if (!Array.isArray(rules)) {
    return [];
  }
  const result = new Array<RoutingRule>();
  for (let index = 0; index < rules.length; index++) {
    const rule = normalizeRoutingRule(rules[index], `routing-rule-${index + 1}`);
    if (rule.remarks.length > 0 || hasRoutingMatcher(rule)) {
      result.push(rule);
    }
  }
  return result;
}

export function hasRoutingMatcher(rule: RoutingRule): boolean {
  return rule.domain.length > 0 || rule.ip.length > 0 || rule.process.length > 0 ||
    rule.port.length > 0 || rule.protocol.length > 0 || rule.network.length > 0;
}

function preserveLockedRules(rules: Array<RoutingRule>): Array<RoutingRule> {
  const locked = new Array<RoutingRule>();
  for (let index = 0; index < rules.length; index++) {
    if (rules[index].locked) {
      locked.push(copyRoutingRule(rules[index]));
    }
  }
  return locked;
}

function normalizeRoutingRule(item: RoutingRule, fallbackId: string): RoutingRule {
  return {
    id: nonEmptyString(item.id, fallbackId),
    remarks: stringValue(item.remarks, '').trim(),
    domain: cleanStringArray(item.domain),
    ip: cleanStringArray(item.ip),
    process: cleanStringArray(item.process),
    outboundTag: outboundTagValue(item.outboundTag),
    port: stringValue(item.port, '').trim(),
    network: networkValue(item.network),
    protocol: cleanStringArray(item.protocol),
    enabled: boolValue(item.enabled, true),
    locked: boolValue(item.locked, false)
  };
}

function copyRoutingRule(rule: RoutingRule): RoutingRule {
  return {
    id: rule.id,
    remarks: rule.remarks,
    domain: rule.domain.slice(),
    ip: rule.ip.slice(),
    process: rule.process.slice(),
    outboundTag: rule.outboundTag,
    port: rule.port,
    network: rule.network,
    protocol: rule.protocol.slice(),
    enabled: rule.enabled,
    locked: rule.locked
  };
}

function cleanStringArray(value: string[] | undefined): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  const result = new Array<string>();
  for (let index = 0; index < value.length; index++) {
    const item = stringValue(value[index], '').trim();
    if (item.length > 0 && result.indexOf(item) < 0) {
      result.push(item);
    }
  }
  return result;
}

function nonEmptyString(value: string | undefined, fallback: string): string {
  const normalized = stringValue(value, '').trim();
  return normalized.length > 0 ? normalized : fallback;
}

function stringValue(value: string | undefined, fallback: string): string {
  return value === undefined ? fallback : `${value}`;
}

function boolValue(value: boolean | undefined, fallback: boolean): boolean {
  return value === undefined ? fallback : value;
}

function outboundTagValue(value: string | undefined): string {
  const normalized = stringValue(value, 'proxy').trim();
  if (normalized === 'direct' || normalized === 'block' || normalized === 'proxy' ||
    normalized === 'proxy-chain' || normalized === 'policy-group') {
    return normalized;
  }
  return 'proxy';
}

function networkValue(value: string | undefined): string {
  const normalized = stringValue(value, '').trim().toLowerCase();
  if (normalized === 'tcp' || normalized === 'udp' || normalized === 'tcp,udp' || normalized === 'udp,tcp') {
    return normalized === 'udp,tcp' ? 'tcp,udp' : normalized;
  }
  return '';
}
