import { window, display, mediaquery } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AppUiModeNight, UI_MODE_NIGHT_DARK, UI_MODE_NIGHT_LIGHT } from './Profile';

// 页面读取安全区高度的 AppStorage 键。缺省 0 → 退化为非沉浸留白，不会破版。
export const TOP_SAFE_HEIGHT_KEY: string = 'topSafeHeight';
export const BOTTOM_SAFE_HEIGHT_KEY: string = 'bottomSafeHeight';

// 解析当前是否深色：显式深/浅直接返回；跟随系统时用 mediaquery 探测有效色彩模式。
function resolveIsDark(uiModeNight: AppUiModeNight): boolean {
  if (uiModeNight === UI_MODE_NIGHT_DARK) {
    return true;
  }
  if (uiModeNight === UI_MODE_NIGHT_LIGHT) {
    return false;
  }
  try {
    return mediaquery.matchMediaSync('(dark-mode: true)').matches;
  } catch (e) {
    return false;
  }
}

function pxToVp(px: number): number {
  try {
    const density = display.getDefaultDisplaySync().densityPixels;
    return density > 0 ? px / density : px;
  } catch (e) {
    return px;
  }
}

function updateSafeAreaInsets(win: window.Window): void {
  try {
    const top = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    const bottom = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    AppStorage.setOrCreate(TOP_SAFE_HEIGHT_KEY, pxToVp(top.topRect.height));
    AppStorage.setOrCreate(BOTTOM_SAFE_HEIGHT_KEY, pxToVp(bottom.bottomRect.height));
  } catch (e) {
    // 取不到安全区则保持 0，页面按非沉浸方式布局
  }
}

// 状态栏 / 导航栏透明，图标色随主题（浅色深图标 / 深色浅图标）。
function applyBarProperties(win: window.Window, isDark: boolean): void {
  try {
    win.setWindowSystemBarProperties({
      statusBarColor: '#00000000',
      navigationBarColor: '#00000000',
      statusBarContentColor: isDark ? '#FFFFFF' : '#000000',
      navigationBarContentColor: isDark ? '#FFFFFF' : '#000000'
    });
  } catch (e) {
    // ignore
  }
}

// 冷启动时开启全屏沉浸、采集安全区、设置系统栏，并监听安全区变化（旋转 / 折叠屏）。
export function setupImmersive(windowStage: window.WindowStage, context: common.Context, uiModeNight: AppUiModeNight): void {
  if (AppStorage.get<number>(TOP_SAFE_HEIGHT_KEY) === undefined) {
    AppStorage.setOrCreate(TOP_SAFE_HEIGHT_KEY, 0);
  }
  if (AppStorage.get<number>(BOTTOM_SAFE_HEIGHT_KEY) === undefined) {
    AppStorage.setOrCreate(BOTTOM_SAFE_HEIGHT_KEY, 0);
  }
  try {
    const win = windowStage.getMainWindowSync();
    win.setWindowLayoutFullScreen(true).then(() => {
      updateSafeAreaInsets(win);
    }).catch(() => {
      updateSafeAreaInsets(win);
    });
    updateSafeAreaInsets(win);
    applyBarProperties(win, resolveIsDark(uiModeNight));
    win.on('avoidAreaChange', () => {
      updateSafeAreaInsets(win);
    });
  } catch (e) {
    // 全屏失败则维持系统默认（非沉浸），安全区读到 0 不影响功能
  }
}

// 主题变化后刷新系统栏图标色（启动 / 前台 / 设置里切换主题时经 applyColorMode 调用）。
export function refreshStatusBarContentColor(context: common.Context, uiModeNight: AppUiModeNight): void {
  try {
    window.getLastWindow(context).then((win) => {
      applyBarProperties(win, resolveIsDark(uiModeNight));
    }).catch(() => {});
  } catch (e) {
    // ignore
  }
}
