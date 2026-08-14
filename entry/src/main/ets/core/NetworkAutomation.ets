// 网络场景自动化 —— 纯决策器
//
// 根据当前网络（WiFi SSID / 蜂窝 / 其他）+ 用户配置的「可信网络」，
// 决定是否自动连接或断开 VPN。全程幂等：期望态==当前态时返回 noop，绝不与用户较劲。
//
// 本文件为纯函数、无任何系统 API 依赖，可被 LocalUnit 单测直接覆盖。

import {
  NetAutomationDirection,
  NET_AUTOMATION_DIRECTION_BOTH,
  NET_AUTOMATION_DIRECTION_CONNECT_ONLY,
  NET_AUTOMATION_DIRECTION_DISCONNECT_ONLY
} from './Profile';

// 当前网络承载类型
export type NetKind = 'wifi' | 'cellular' | 'other' | 'none';
export const NET_KIND_WIFI: NetKind = 'wifi';
export const NET_KIND_CELLULAR: NetKind = 'cellular';
export const NET_KIND_OTHER: NetKind = 'other';
export const NET_KIND_NONE: NetKind = 'none';

// 决策动作
export type AutoAction = 'connect' | 'disconnect' | 'noop';
export const NET_ACTION_CONNECT: AutoAction = 'connect';
export const NET_ACTION_DISCONNECT: AutoAction = 'disconnect';
export const NET_ACTION_NOOP: AutoAction = 'noop';

// 当前网络上下文；ssid 仅 wifi 有意义，拿不到（无权限/隐藏 SSID）时为 undefined
export interface NetContext {
  kind: NetKind;
  ssid?: string;
}

// 自动化配置（来自 AppSettings 的相关子集）
export interface NetAutomationConfig {
  enabled: boolean;
  direction: NetAutomationDirection;
  trustedSsids: string[];
  cellularTrusted: boolean;
}

/**
 * 判定当前网络是否「可信」。
 * - 蜂窝：由 cellularTrusted 决定。
 * - WiFi：SSID 命中可信列表则可信；拿不到 SSID 按「不可信」处理（fail-secure，宁可代理）。
 * - none/other：不参与，返回 false。
 */
export function isTrustedNetwork(ctx: NetContext, cfg: NetAutomationConfig): boolean {
  if (ctx.kind === NET_KIND_CELLULAR) {
    return cfg.cellularTrusted;
  }
  if (ctx.kind === NET_KIND_WIFI) {
    const ssid = ctx.ssid;
    if (ssid === undefined || ssid.length === 0) {
      return false;
    }
    return cfg.trustedSsids.includes(ssid);
  }
  return false;
}

/**
 * 返回应执行的动作。幂等——期望态已满足则返回 noop。
 * @param currentlyRunning VPN 隧道当前是否在运行
 */
export function decideNetAutomationAction(
  ctx: NetContext,
  cfg: NetAutomationConfig,
  currentlyRunning: boolean
): AutoAction {
  if (!cfg.enabled) {
    return NET_ACTION_NOOP;
  }
  // 无网络 / 未知承载：不动
  if (ctx.kind === NET_KIND_NONE || ctx.kind === NET_KIND_OTHER) {
    return NET_ACTION_NOOP;
  }

  const trusted = isTrustedNetwork(ctx, cfg);
  const allowDisconnect =
    cfg.direction === NET_AUTOMATION_DIRECTION_BOTH || cfg.direction === NET_AUTOMATION_DIRECTION_DISCONNECT_ONLY;
  const allowConnect =
    cfg.direction === NET_AUTOMATION_DIRECTION_BOTH || cfg.direction === NET_AUTOMATION_DIRECTION_CONNECT_ONLY;

  if (trusted) {
    // 可信网络：候选动作 = 断开（仅运行中且方向允许）
    if (currentlyRunning && allowDisconnect) {
      return NET_ACTION_DISCONNECT;
    }
    return NET_ACTION_NOOP;
  }
  // 不可信网络：候选动作 = 连接（仅已断开且方向允许）
  if (!currentlyRunning && allowConnect) {
    return NET_ACTION_CONNECT;
  }
  return NET_ACTION_NOOP;
}
