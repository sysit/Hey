import { Want } from '@kit.AbilityKit';
import { FormExtensionAbility, formBindingData } from '@kit.FormKit';
import { buildControlCardFormData } from '../core/ControlCard';
import { CONTROL_CARD_MANAGER } from '../services/ControlCardManager';

const FORM_IDENTITY_KEY: string = 'ohos.extra.param.key.form_identity';

export default class ControlCardAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = this.formIdFromWant(want);
    CONTROL_CARD_MANAGER.registerForm(this.context, formId).catch((error: Error) => {
    });
    return formBindingData.createFormBindingData(buildControlCardFormData());
  }

  onUpdateForm(formId: string): void {
    CONTROL_CARD_MANAGER.refreshForm(this.context, formId).catch((error: Error) => {
    });
  }

  onRemoveForm(formId: string): void {
    CONTROL_CARD_MANAGER.unregisterForm(this.context, formId).catch((error: Error) => {
    });
  }

  private formIdFromWant(want: Want): string {
    const parameters = want.parameters;
    if (parameters === undefined) {
      return '';
    }
    const value = parameters[FORM_IDENTITY_KEY];
    if (typeof value === 'string') {
      return value;
    }
    if (typeof value === 'number') {
      return value.toString();
    }
    return '';
  }
}
