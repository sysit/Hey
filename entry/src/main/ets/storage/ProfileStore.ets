import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { DEFAULT_PROFILE_ID, ProxyProfile } from '../core/Profile';

const PREFERENCES_NAME: string = 'hey_vpn_profile';
const PROFILE_KEY: string = 'default_profile';

export class ProfileStore {
  static async load(context: common.Context): Promise<ProxyProfile> {
    const store = await preferences.getPreferences(context, PREFERENCES_NAME);
    const rawValue = await store.get(PROFILE_KEY, '');
    const raw = rawValue.toString();
    if (raw.length === 0) {
      return ProfileStore.createEmptyProfile();
    }

    try {
      const profile = JSON.parse(raw) as ProxyProfile;
      if (profile.id.length === 0) {
        return ProfileStore.createEmptyProfile();
      }
      return profile;
    } catch (error) {
      return ProfileStore.createEmptyProfile();
    }
  }

  static async save(context: common.Context, outboundJson: string): Promise<ProxyProfile> {
    const profile: ProxyProfile = {
      id: DEFAULT_PROFILE_ID,
      name: 'Default Xray Profile',
      outboundJson,
      updatedAt: Date.now()
    };
    const store = await preferences.getPreferences(context, PREFERENCES_NAME);
    await store.put(PROFILE_KEY, JSON.stringify(profile));
    await store.flush();
    return profile;
  }

  private static createEmptyProfile(): ProxyProfile {
    return {
      id: DEFAULT_PROFILE_ID,
      name: 'Default Xray Profile',
      outboundJson: '',
      updatedAt: 0
    };
  }
}
