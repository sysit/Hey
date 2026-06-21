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
    const store = await preferences.getPreferences(context, PREFERENCES_NAME);
    await store.put(CORE_TYPE_KEY, normalized);
    await store.flush();
    return normalized;
  }
}
