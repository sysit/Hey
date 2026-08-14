import { LogEntry, LogLevelCounts, LogLevelFilter } from './LogModel';

/** 按等级 + 关键字过滤结构化日志（搜索匹配整行原文，大小写不敏感）。 */
export function filterLogEntries(entries: Array<LogEntry>, level: LogLevelFilter, query: string): Array<LogEntry> {
  const keyword = query.trim().toLowerCase();
  const result = new Array<LogEntry>();
  for (let index = 0; index < entries.length; index++) {
    const entry = entries[index];
    if (level !== 'all' && entry.level !== level) {
      continue;
    }
    if (keyword.length > 0 && entry.raw.toLowerCase().indexOf(keyword) < 0) {
      continue;
    }
    result.push(entry);
  }
  return result;
}

/** 统计各等级数量，驱动过滤胶囊的计数。 */
export function countLogLevels(entries: Array<LogEntry>): LogLevelCounts {
  const counts: LogLevelCounts = { all: entries.length, debug: 0, info: 0, warn: 0, error: 0 };
  for (let index = 0; index < entries.length; index++) {
    const level = entries[index].level;
    if (level === 'debug') {
      counts.debug += 1;
    } else if (level === 'warn') {
      counts.warn += 1;
    } else if (level === 'error') {
      counts.error += 1;
    } else {
      counts.info += 1;
    }
  }
  return counts;
}

/** 把结构化日志拼回纯文本（复制 / 分享用），每行取整行原文。 */
export function formatLogEntriesText(entries: Array<LogEntry>): string {
  const lines = new Array<string>();
  for (let index = 0; index < entries.length; index++) {
    lines.push(entries[index].raw);
  }
  return lines.join('\n');
}

export function filterLogItems(items: Array<string>, query: string): Array<string> {
  const keyword = query.trim();
  if (keyword.length === 0) {
    return copyLogItems(items);
  }
  const result = new Array<string>();
  for (let index = 0; index < items.length; index++) {
    if (items[index].indexOf(keyword) >= 0) {
      result.push(items[index]);
    }
  }
  return result;
}

export function formatLogcatText(items: Array<string>): string {
  return items.join('\n');
}

function copyLogItems(items: Array<string>): Array<string> {
  const result = new Array<string>();
  for (let index = 0; index < items.length; index++) {
    result.push(items[index]);
  }
  return result;
}
