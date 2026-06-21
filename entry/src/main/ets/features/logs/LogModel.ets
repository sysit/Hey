/**
 * 结构化日志模型。
 *
 * 旧实现把日志压平成 Array<string>，丢掉了等级信息，无法做分级过滤/着色。
 * 这里保留每条日志的 time/level/source/message，并用 raw 承载整行原文供搜索/复制/分享。
 */

/** 日志等级（四级，归一化自 DiagnosticEvent.level 与应用内日志）。 */
export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

/** 等级过滤选择：四级之一或「全部」。 */
export type LogLevelFilter = LogLevel | 'all';

/** 结构化日志条目。 */
export interface LogEntry {
  at: number;       // 毫秒时间戳，用于跨来源（诊断 / 应用）合并排序
  time: string;     // 已格式化时钟，如 14:32:07
  level: LogLevel;
  source: string;   // 诊断来源标签，应用内日志为空串
  message: string;  // 正文
  raw: string;      // 整行原文，用于搜索 / 复制 / 分享
}

/** 各等级计数，驱动过滤胶囊上的数字。 */
export interface LogLevelCounts {
  all: number;
  debug: number;
  info: number;
  warn: number;
  error: number;
}

/** 把任意等级字符串归一化为四级之一（warning→warn，err/fatal→error，未知→info）。
 *  容错：诊断文件跨版本累积，旧行可能缺 level 或非字符串——绝不能抛，否则整页日志清空。 */
export function normalizeLogLevel(value: string): LogLevel {
  const normalized = typeof value === 'string' ? value.trim().toLowerCase() : '';
  if (normalized === 'debug' || normalized === 'verbose' || normalized === 'trace') {
    return 'debug';
  }
  if (normalized === 'warn' || normalized === 'warning') {
    return 'warn';
  }
  if (normalized === 'error' || normalized === 'err' || normalized === 'fatal') {
    return 'error';
  }
  return 'info';
}

/** 等级显示名（控制台徽标与胶囊用，技术术语统一英文，不走 i18n）。 */
export function logLevelLabel(level: LogLevel): string {
  if (level === 'debug') {
    return 'Debug';
  }
  if (level === 'warn') {
    return 'Warning';
  }
  if (level === 'error') {
    return 'Error';
  }
  return 'Info';
}
