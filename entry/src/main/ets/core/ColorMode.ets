import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { AppUiModeNight, UI_MODE_NIGHT_DARK, UI_MODE_NIGHT_LIGHT } from './Profile';

export function applyColorMode(context: common.Context, uiModeNight: AppUiModeNight): void {
  let colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  if (uiModeNight === UI_MODE_NIGHT_LIGHT) {
    colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  } else if (uiModeNight === UI_MODE_NIGHT_DARK) {
    colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }
  try {
    context.getApplicationContext().setColorMode(colorMode);
  } catch (e) {
    // ignore
  }
}
