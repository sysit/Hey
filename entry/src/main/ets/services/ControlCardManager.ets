import { common } from '@kit.AbilityKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { AppLanguage, ConnectionStatus } from '../core/Profile';
import { ControlCardFormData, buildControlCardFormData } from '../core/ControlCard';
import { ControlCardStore } from '../storage/ControlCardStore';
import { DiagnosticLog } from './DiagnosticLog';

const CONTROL_CARD_REFRESH_INTERVAL_MS: number = 3000;

export class ControlCardManager {
  private lastSyncAt: number = 0;
  private lastImmediateKey: string = '';

  async registerForm(context: common.Context, formId: string): Promise<void> {
    if (formId.length === 0) {
      return;
    }
    await ControlCardStore.addFormId(context, formId);
    await this.updateOne(context, formId, await ControlCardStore.loadState(context));
  }

  async unregisterForm(context: common.Context, formId: string): Promise<void> {
    if (formId.length === 0) {
      return;
    }
    await ControlCardStore.removeFormId(context, formId);
  }

  async refreshForm(context: common.Context, formId: string): Promise<void> {
    if (formId.length === 0) {
      return;
    }
    await this.updateOne(context, formId, await ControlCardStore.loadState(context));
  }

  async sync(
    context: common.Context,
    status: ConnectionStatus,
    elapsedText: string,
    language: AppLanguage,
    lastError: string
  ): Promise<void> {
    const now = Date.now();
    const immediateKey = `${language}|${status}|${lastError}`;
    if (this.shouldSkipSync(now, immediateKey)) {
      return;
    }
    const state = await ControlCardStore.saveState(context, buildControlCardFormData(language, status, elapsedText, lastError));
    const formIds = await ControlCardStore.loadFormIds(context);
    for (let index = 0; index < formIds.length; index++) {
      await this.updateOne(context, formIds[index], state);
    }
    this.lastSyncAt = now;
    this.lastImmediateKey = immediateKey;
  }

  private shouldSkipSync(now: number, immediateKey: string): boolean {
    if (immediateKey !== this.lastImmediateKey) {
      return false;
    }
    return now - this.lastSyncAt < CONTROL_CARD_REFRESH_INTERVAL_MS;
  }

  private async updateOne(context: common.Context, formId: string, state: ControlCardFormData): Promise<void> {
    try {
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(state));
    } catch (error) {
      DiagnosticLog.append(context, {
        at: Date.now(),
        level: 'warn',
        source: 'form',
        message: 'Control card update failed.',
        details: JSON.stringify(error)
      });
    }
  }
}

export const CONTROL_CARD_MANAGER: ControlCardManager = new ControlCardManager();
