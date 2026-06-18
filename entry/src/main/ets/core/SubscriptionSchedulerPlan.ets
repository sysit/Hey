import { SubscriptionGroup } from './Profile';
import { normalizeSubscriptionUpdateInterval } from './SubscriptionGroups';

export const SUBSCRIPTION_AUTO_UPDATE_WORK_ID: number = 260618;
export const SUBSCRIPTION_AUTO_UPDATE_WORK_BUNDLE_NAME: string = 'com.lmlm.hey';
export const SUBSCRIPTION_AUTO_UPDATE_WORK_ABILITY: string = 'SubscriptionUpdateWorkAbility';

export interface SubscriptionAutoUpdateSchedulePlan {
  enabled: boolean;
  enabledGroupCount: number;
  intervalMinutes: number;
  repeatCycleTimeMs: number;
}

export function buildSubscriptionAutoUpdateSchedulePlan(groups: Array<SubscriptionGroup>): SubscriptionAutoUpdateSchedulePlan {
  let enabledGroupCount = 0;
  let intervalMinutes = 0;

  for (let index = 0; index < groups.length; index++) {
    const group = groups[index];
    if (!isSubscriptionAutoUpdateSchedulable(group)) {
      continue;
    }

    const normalizedInterval = normalizeSubscriptionUpdateInterval(group.updateIntervalMinutes);
    enabledGroupCount++;
    if (intervalMinutes === 0 || normalizedInterval < intervalMinutes) {
      intervalMinutes = normalizedInterval;
    }
  }

  return {
    enabled: enabledGroupCount > 0,
    enabledGroupCount,
    intervalMinutes,
    repeatCycleTimeMs: intervalMinutes > 0 ? intervalMinutes * 60 * 1000 : 0
  };
}

export function isSubscriptionAutoUpdateSchedulable(group: SubscriptionGroup): boolean {
  return group.enabled && (group.autoUpdate ?? false) && group.url.trim().length > 0;
}
