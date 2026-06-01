import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { ProxyNode, SubscriptionProfile } from '../core/Profile';

const PREFERENCES_NAME: string = 'hey_vpn_subscription';
const SUBSCRIPTION_KEY: string = 'subscription_profile';

export class SubscriptionStore {
  static async load(context: common.Context): Promise<SubscriptionProfile> {
    const store = await preferences.getPreferences(context, PREFERENCES_NAME);
    const rawValue = await store.get(SUBSCRIPTION_KEY, '');
    const raw = rawValue.toString();
    if (raw.length === 0) {
      return SubscriptionStore.createEmpty();
    }

    try {
      const profile = JSON.parse(raw) as SubscriptionProfile;
      if (profile.nodes === undefined) {
        return SubscriptionStore.createEmpty();
      }
      return profile;
    } catch (error) {
      return SubscriptionStore.createEmpty();
    }
  }

  static async saveUrl(context: common.Context, url: string): Promise<SubscriptionProfile> {
    const profile = await SubscriptionStore.load(context);
    profile.url = url;
    await SubscriptionStore.save(context, profile);
    return profile;
  }

  static async saveNodes(context: common.Context, url: string, nodes: Array<ProxyNode>, selectedNodeId: string): Promise<SubscriptionProfile> {
    const profile: SubscriptionProfile = {
      url,
      selectedNodeId,
      nodes,
      updatedAt: Date.now()
    };
    await SubscriptionStore.save(context, profile);
    return profile;
  }

  static async selectNode(context: common.Context, selectedNodeId: string): Promise<SubscriptionProfile> {
    const profile = await SubscriptionStore.load(context);
    profile.selectedNodeId = selectedNodeId;
    await SubscriptionStore.save(context, profile);
    return profile;
  }

  private static async save(context: common.Context, profile: SubscriptionProfile): Promise<void> {
    const store = await preferences.getPreferences(context, PREFERENCES_NAME);
    await store.put(SUBSCRIPTION_KEY, JSON.stringify(profile));
    await store.flush();
  }

  private static createEmpty(): SubscriptionProfile {
    return {
      url: '',
      selectedNodeId: '',
      nodes: [],
      updatedAt: 0
    };
  }
}
