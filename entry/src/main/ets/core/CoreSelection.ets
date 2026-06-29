import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

/**
 * 内核选择（全局开关，预览功能）。
 *
 * 用独立的轻量 preferences 存储，而不是塞进庞大的 AppSettings 管线 —— 把 sing-box
 * 这个预览特性隔离开，便于以后正式化或回退。当前是 Xray / sing-box 二选一的全局开关。
 */
export type CoreType = 'xray' | 'singbox';

export const CORE_TYPE_XRAY: CoreType = 'xray';
export const CORE_TYPE_SINGBOX: CoreType = 'singbox';
export const DEFAULT_CORE_TYPE: CoreType = CORE_TYPE_XRAY;

const PREFERENCES_NAME: string = 'hey_core_selection';
const CORE_TYPE_KEY: string = 'core_type';

export function normalizeCoreType(value: string | undefined): CoreType {
  return value === CORE_TYPE_SINGBOX ? CORE_TYPE_SINGBOX : CORE_TYPE_XRAY;
}

export function isSingboxCore(value: CoreType | string | undefined): boolean {
  return normalizeCoreType(value as string | undefined) === CORE_TYPE_SINGBOX;
}

// 仅 sing-box 内核支持的协议：Xray-core 没有对应 outbound（如 anytls / tuic）。
// 命中这些协议的节点必须用 sing-box 跑，无论全局内核开关选的是什么——否则丢给
// Xray 会因找不到 outbound handler 而启动失败。
const SINGBOX_ONLY_PROTOCOLS: Array<string> = ['anytls', 'tuic'];

export function isSingboxOnlyProtocol(protocol: string | undefined): boolean {
  if (protocol === undefined) {
    return false;
  }
  return SINGBOX_ONLY_PROTOCOLS.indexOf(protocol.trim().toLowerCase()) >= 0;
}

export class CoreSelectionStore {
  static async load(context: common.Context): Promise<CoreType> {
    try {
      const store = await preferences.getPreferences(context, PREFERENCES_NAME);
      const raw = (await store.get(CORE_TYPE_KEY, DEFAULT_CORE_TYPE)).toString();
      return normalizeCoreType(raw);
    } catch (error) {
      return DEFAULT_CORE_TYPE;
    }
  }

  static async save(context: common.Context, coreType: CoreType): Promise<CoreType> {
    const normalized = normalizeCoreType(coreType);
    try {
      const store = await preferences.getPreferences(context, PREFERENCES_NAME);
      await store.put(CORE_TYPE_KEY, normalized);
      await store.flush();
    } catch (error) {
      // ignore
    }
    return normalized;
  }
}
