import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { ControlCardFormData, buildControlCardFormData, normalizeControlCardFormData } from '../core/ControlCard';

const PREFERENCES_NAME: string = 'hey_control_card';
const FORM_IDS_KEY: string = 'form_ids';
const STATE_KEY: string = 'state';

export class ControlCardStore {
  static async loadFormIds(context: common.Context): Promise<Array<string>> {
    try {
      const store = await preferences.getPreferences(context, PREFERENCES_NAME);
      const rawValue = await store.get(FORM_IDS_KEY, '[]');
      return ControlCardStore.parseIds(rawValue.toString());
    } catch (e) {
      return [];
    }
  }

  static async addFormId(context: common.Context, formId: string): Promise<Array<string>> {
    if (formId.length === 0) {
      return ControlCardStore.loadFormIds(context);
    }
    const ids = await ControlCardStore.loadFormIds(context);
    if (ids.indexOf(formId) < 0) {
      ids.push(formId);
      await ControlCardStore.saveFormIds(context, ids);
    }
    return ids;
  }

  static async removeFormId(context: common.Context, formId: string): Promise<Array<string>> {
    const ids = await ControlCardStore.loadFormIds(context);
    const next = ids.filter((id: string) => id !== formId);
    if (next.length !== ids.length) {
      await ControlCardStore.saveFormIds(context, next);
    }
    return next;
  }

  static async loadState(context: common.Context): Promise<ControlCardFormData> {
    try {
      const store = await preferences.getPreferences(context, PREFERENCES_NAME);
      const rawValue = await store.get(STATE_KEY, '');
      const raw = rawValue.toString();
      if (raw.length === 0) {
        return buildControlCardFormData();
      }
      return normalizeControlCardFormData(JSON.parse(raw) as ControlCardFormData);
    } catch (error) {
      return buildControlCardFormData();
    }
  }

  static async saveState(context: common.Context, state: ControlCardFormData): Promise<ControlCardFormData> {
    const normalized = normalizeControlCardFormData(state);
    try {
      const store = await preferences.getPreferences(context, PREFERENCES_NAME);
      await store.put(STATE_KEY, JSON.stringify(normalized));
      await store.flush();
    } catch (error) {
      // ignore
    }
    return normalized;
  }

  private static async saveFormIds(context: common.Context, ids: Array<string>): Promise<void> {
    try {
      const store = await preferences.getPreferences(context, PREFERENCES_NAME);
      await store.put(FORM_IDS_KEY, JSON.stringify(ControlCardStore.uniqueIds(ids)));
      await store.flush();
    } catch (error) {
      // ignore
    }
  }

  private static parseIds(raw: string): Array<string> {
    try {
      const parsed = JSON.parse(raw) as Array<string>;
      return Array.isArray(parsed) ? ControlCardStore.uniqueIds(parsed) : [];
    } catch (error) {
      return [];
    }
  }

  private static uniqueIds(ids: Array<string>): Array<string> {
    const result = new Array<string>();
    for (let index = 0; index < ids.length; index++) {
      const id = ids[index];
      if (id.length > 0 && result.indexOf(id) < 0) {
        result.push(id);
      }
    }
    return result;
  }
}
