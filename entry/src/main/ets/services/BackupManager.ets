import { common } from '@kit.AbilityKit';
import { ProfileStore } from '../storage/ProfileStore';
import { SubscriptionStore } from '../storage/SubscriptionStore';
import { SettingsStore } from '../storage/SettingsStore';
import { AssetStore } from '../storage/AssetStore';
import { buildConfigBackup, ConfigBackup } from '../core/ConfigBackup';

// 全量配置备份的聚合层：把四块配置 Store 一次性读出/写回。
// 字段归一化交给各 Store 的 save/normalize，这里只负责协调读写顺序。
export class BackupManager {
  // 读取四块配置 Store，组装一份全量备份对象。
  static async collectBackup(context: common.Context): Promise<ConfigBackup> {
    const profile = await ProfileStore.load(context);
    const subscriptions = await SubscriptionStore.load(context);
    const settings = await SettingsStore.load(context);
    const assets = await AssetStore.load(context);
    return buildConfigBackup(profile, subscriptions, settings, assets, Date.now());
  }

  // 用备份覆盖现有配置（覆盖语义）。调用方应在此之前先留一份安全副本。
  static async applyBackup(context: common.Context, backup: ConfigBackup): Promise<void> {
    await ProfileStore.save(context, backup.profile.outboundJson, backup.profile.configType ?? 'outbound');
    await SubscriptionStore.restoreProfile(context, backup.subscriptions);
    await SettingsStore.save(context, backup.settings);
    await AssetStore.save(context, backup.assets);
  }
}
