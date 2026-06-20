import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { DEFAULT_LANGUAGE, translate } from '../core/I18n';
import { AppLanguage, ConnectionStatus, RuntimeStats } from '../core/Profile';
import { RuntimeLogPanel } from '../features/logs/LogPanel';
import { filterLogItems, formatLogcatText } from '../features/logs/LogOperations';
import { RuntimeStatusPanel } from '../features/runtime/RuntimePanel';
import { RuntimeViewState, SHARED_RUNTIME_CONTROLLER } from '../features/runtime/RuntimeController';
import { SETTINGS_CONTROLLER } from '../features/settings/SettingsController';
import { shareText, TextShareResult } from '../services/SystemShare';
import { SectionHeader } from '../components/SectionHeader';
import { PageHeader } from '../shell/PageHeader';
import { formatBytes } from '../utils/Formatters';
import { localizeCoreMessage } from '../utils/LocalizationPresenter';
import { AppColor, Space } from '../theme/Theme';

const EMPTY_STATS: RuntimeStats = {
  uploadBytes: 0,
  downloadBytes: 0,
  xrayRunning: false,
  tunRunning: false,
  lastMessage: translate(DEFAULT_LANGUAGE, 'runtime.nativeBridgeNotQueried')
};

@Entry
@Component
struct LogsPage {
  private timerId: number = -1;

  @StorageProp('appLanguage') private language: AppLanguage = DEFAULT_LANGUAGE;
  @State private status: ConnectionStatus = ConnectionStatus.IDLE;
  @State private elapsedText: string = '00:00';
  @State private logs: Array<string> = [];
  @State private searchQuery: string = '';
  @State private stats: RuntimeStats = EMPTY_STATS;
  @State private speedEnabled: boolean = false;

  aboutToAppear(): void {
    this.loadState();
    if (this.timerId < 0) {
      this.timerId = setInterval(() => {
        this.refreshRuntime();
      }, 1000);
    }
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  build() {
    Column() {
      PageHeader({
        title: this.t('screen.logs.title'),
        showBack: true
      })
      Scroll() {
        Column({ space: Space.lg }) {
          SectionHeader({ title: this.t('runtime.title') })
          RuntimeStatusPanel({
            durationLabel: this.t('runtime.duration'),
            durationValue: this.elapsedText,
            uploadLabel: this.t('runtime.upload'),
            uploadValue: formatBytes(this.stats.uploadBytes),
            downloadLabel: this.t('runtime.download'),
            downloadValue: formatBytes(this.stats.downloadBytes),
            showTraffic: this.speedEnabled,
            xrayActive: this.stats.xrayRunning,
            tunActive: this.stats.tunRunning,
            lastMessage: this.localizeCoreMessage(this.stats.lastMessage)
          })

          SectionHeader({ title: this.t('logs.title') })
          Search({ value: this.searchQuery, placeholder: this.t('logs.searchPlaceholder') })
            .height(40)
            .width('100%')
            .margin({ left: Space.lg, right: Space.lg })
            .backgroundColor(AppColor.surface)
            .borderRadius(20)
            .onChange((value: string) => {
              this.searchQuery = value;
            })
          RuntimeLogPanel({
            clearLabel: this.t('action.clear'),
            copyLabel: this.t('logs.copyAll'),
            shareLabel: this.t('logs.shareAll'),
            emptyLabel: this.t('logs.empty'),
            items: this.visibleLogs(),
            onClear: () => {
              this.clearLogs();
            },
            onCopy: () => {
              this.copyVisibleLogs();
            },
            onShare: () => {
              this.shareVisibleLogs();
            },
            onCopyItem: (item: string) => {
              this.copyLogItem(item);
            }
          })
        }
        .width('100%')
        .padding({ top: Space.sm, bottom: Space.xxl })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor(AppColor.bg)
  }

  private async loadState(): Promise<void> {
    const context = getContext(this) as common.Context;
    const settings = await SETTINGS_CONTROLLER.load(context);
    this.language = settings.language;
    this.speedEnabled = settings.speedEnabled;
    await this.refreshRuntime();
  }

  private async refreshRuntime(): Promise<void> {
    const context = getContext(this) as common.Context;
    this.applyRuntimeState(await SHARED_RUNTIME_CONTROLLER.refresh(context, this.language));
  }

  private clearLogs(): void {
    const context = getContext(this) as common.Context;
    this.applyRuntimeState(SHARED_RUNTIME_CONTROLLER.clearLogs(context, this.language));
  }

  private copyVisibleLogs(): void {
    this.copyLogText(this.visibleLogText());
  }

  private copyLogItem(item: string): void {
    this.copyLogText(item);
  }

  private async shareVisibleLogs(): Promise<void> {
    const content = this.visibleLogText();
    if (content.trim().length === 0) {
      promptAction.showToast({ message: this.t('logs.empty') });
      return;
    }
    const context = getContext(this) as common.UIAbilityContext;
    const result = await shareText(context, this.t('screen.logs.title'), content);
    this.handleShareResult(result);
  }

  private copyLogText(content: string): void {
    const text = content.trim();
    if (text.length === 0) {
      promptAction.showToast({ message: this.t('logs.empty') });
      return;
    }
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard.setDataSync(pasteData);
      promptAction.showToast({ message: this.t('logs.copied') });
    } catch (error) {
      promptAction.showToast({ message: this.f1('logs.copyFailed', 'error', JSON.stringify(error)) });
    }
  }

  private handleShareResult(result: TextShareResult): void {
    if (result.systemShareStarted) {
      promptAction.showToast({ message: this.t('share.started') });
      return;
    }
    if (result.copiedToClipboard) {
      promptAction.showToast({ message: this.t('share.fallbackCopied') });
      return;
    }
    promptAction.showToast({ message: this.f1('share.failed', 'error', result.errorMessage) });
  }

  private visibleLogs(): Array<string> {
    return filterLogItems(this.logs, this.searchQuery);
  }

  private visibleLogText(): string {
    return formatLogcatText(this.visibleLogs());
  }

  private applyRuntimeState(state: RuntimeViewState): void {
    this.status = state.status;
    this.elapsedText = state.elapsedText;
    this.logs = state.logs;
    this.stats = state.stats;
  }

  private localizeCoreMessage(message: string): string {
    return localizeCoreMessage(this.language, message);
  }

  private t(key: string): string {
    return translate(this.language, key);
  }

  private f1(key: string, name: string, value: string): string {
    return translate(this.language, key).replace(`{${name}}`, value);
  }
}
