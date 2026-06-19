import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

export const READ_PASTEBOARD_PERMISSION: Permissions = 'ohos.permission.READ_PASTEBOARD';

export async function ensureReadPasteboardPermission(context: common.Context): Promise<boolean> {
  try {
    const atManager = abilityAccessCtrl.createAtManager();
    const result = await atManager.requestPermissionsFromUser(
      context as common.UIAbilityContext,
      [READ_PASTEBOARD_PERMISSION]
    );
    const index = result.permissions.indexOf(READ_PASTEBOARD_PERMISSION);
    if (index < 0 || index >= result.authResults.length) {
      return false;
    }
    return result.authResults[index] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  } catch (error) {
    return false;
  }
}
