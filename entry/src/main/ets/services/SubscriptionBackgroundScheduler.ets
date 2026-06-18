import { common } from '@kit.AbilityKit';
import { workScheduler } from '@kit.BackgroundTasksKit';
import {
  SUBSCRIPTION_AUTO_UPDATE_WORK_ABILITY,
  SUBSCRIPTION_AUTO_UPDATE_WORK_BUNDLE_NAME,
  SUBSCRIPTION_AUTO_UPDATE_WORK_ID,
  SubscriptionAutoUpdateSchedulePlan,
  buildSubscriptionAutoUpdateSchedulePlan
} from '../core/SubscriptionSchedulerPlan';
import { SubscriptionStore } from '../storage/SubscriptionStore';

export interface SubscriptionBackgroundScheduleResult {
  scheduled: boolean;
  enabledGroupCount: number;
  repeatCycleTimeMs: number;
  message: string;
}

export class SubscriptionBackgroundScheduler {
  static async sync(context: common.Context): Promise<SubscriptionBackgroundScheduleResult> {
    const profile = await SubscriptionStore.load(context);
    const plan = buildSubscriptionAutoUpdateSchedulePlan(profile.groups);
    if (!plan.enabled) {
      return SubscriptionBackgroundScheduler.cancel('No enabled subscription auto-update groups.');
    }

    try {
      SubscriptionBackgroundScheduler.stopExistingWork();
      workScheduler.startWork(SubscriptionBackgroundScheduler.buildWorkInfo(plan));
      return {
        scheduled: true,
        enabledGroupCount: plan.enabledGroupCount,
        repeatCycleTimeMs: plan.repeatCycleTimeMs,
        message: `Subscription background auto-update scheduled for ${plan.enabledGroupCount} group(s).`
      };
    } catch (error) {
      return {
        scheduled: false,
        enabledGroupCount: plan.enabledGroupCount,
        repeatCycleTimeMs: plan.repeatCycleTimeMs,
        message: `Subscription background auto-update schedule failed: ${SubscriptionBackgroundScheduler.stringifyError(error)}`
      };
    }
  }

  static cancel(reason: string = 'Subscription background auto-update disabled.'): SubscriptionBackgroundScheduleResult {
    try {
      workScheduler.stopWork(SubscriptionBackgroundScheduler.buildCancelWorkInfo(), true);
    } catch (error) {
      return {
        scheduled: false,
        enabledGroupCount: 0,
        repeatCycleTimeMs: 0,
        message: `${reason} Stop request ignored: ${SubscriptionBackgroundScheduler.stringifyError(error)}`
      };
    }

    return {
      scheduled: false,
      enabledGroupCount: 0,
      repeatCycleTimeMs: 0,
      message: reason
    };
  }

  private static stopExistingWork(): void {
    try {
      workScheduler.stopWork(SubscriptionBackgroundScheduler.buildCancelWorkInfo(), true);
    } catch (error) {
      // WorkScheduler throws when there is no existing work. Registering the new
      // work below is still the source of truth for schedule success.
    }
  }

  private static buildWorkInfo(plan: SubscriptionAutoUpdateSchedulePlan): workScheduler.WorkInfo {
    return {
      workId: SUBSCRIPTION_AUTO_UPDATE_WORK_ID,
      bundleName: SUBSCRIPTION_AUTO_UPDATE_WORK_BUNDLE_NAME,
      abilityName: SUBSCRIPTION_AUTO_UPDATE_WORK_ABILITY,
      isPersisted: true,
      networkType: workScheduler.NetworkType.NETWORK_TYPE_ANY,
      isRepeat: true,
      repeatCycleTime: plan.repeatCycleTimeMs,
      parameters: {
        source: 'subscription-auto-update',
        enabledGroupCount: plan.enabledGroupCount,
        intervalMinutes: plan.intervalMinutes
      }
    };
  }

  private static buildCancelWorkInfo(): workScheduler.WorkInfo {
    return {
      workId: SUBSCRIPTION_AUTO_UPDATE_WORK_ID,
      bundleName: SUBSCRIPTION_AUTO_UPDATE_WORK_BUNDLE_NAME,
      abilityName: SUBSCRIPTION_AUTO_UPDATE_WORK_ABILITY
    };
  }

  private static stringifyError(error: Error | Object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return JSON.stringify(error);
  }
}
