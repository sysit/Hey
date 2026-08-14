import { LogEntry, LogLevel, logLevelLabel } from './LogModel';
import { AppColor, FontSz, Radius, Space } from '../../theme/Theme';

export type CopyLogItemHandler = (raw: string) => void;

/**
 * 分级色标日志控制台。
 *
 * 每行：时间戳 + 等级徽标（按严重度着色）+ 消息；左边框按等级着色，Warning/Error 行底色加重。
 * 点任意行复制整行原文。entries 必须用 @Prop——页面每秒刷新，普通成员会冻结。
 * 详见 arkui-child-component-prop-sync。
 */
@Component
export struct LogConsole {
  @Prop entries: Array<LogEntry> = [];
  @Prop emptyTitle: string = '';
  @Prop emptyHint: string = '';
  onCopyItem: CopyLogItemHandler = (_raw: string) => {};

  build() {
    Column() {
      if (this.entries.length === 0) {
        Column({ space: Space.xs }) {
          Text(this.emptyTitle)
            .fontSize(FontSz.body)
            .fontColor(AppColor.textTertiary)
          if (this.emptyHint.length > 0) {
            Text(this.emptyHint)
              .fontSize(FontSz.footnote)
              .fontColor(AppColor.textTertiary)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.entries, (entry: LogEntry, index: number) => {
            ListItem() {
              Row({ space: Space.sm }) {
                Text(entry.time)
                  .fontSize(FontSz.caption)
                  .fontColor(AppColor.textTertiary)
                  .width(56)
                  .flexShrink(0)
                Text(logLevelLabel(entry.level).toUpperCase())
                  .fontSize(10)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.accentColor(entry.level))
                  .width(56)
                  .flexShrink(0)
                Text(entry.message)
                  .fontSize(FontSz.footnote)
                  .lineHeight(18)
                  .fontColor(this.messageColor(entry.level))
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
              .padding({ left: Space.md, right: Space.md, top: Space.xs + 2, bottom: Space.xs + 2 })
              .backgroundColor(this.rowBackground(entry.level))
              .border({ width: { left: 2.5 }, color: this.accentColor(entry.level) })
              .onClick(() => {
                this.onCopyItem(entry.raw);
              })
            }
          }, (entry: LogEntry, index: number) => `${index}-${entry.at}-${entry.level}`)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColor.surface)
    .border({ width: 0.5, color: AppColor.border })
    .borderRadius({ topLeft: Radius.md, topRight: Radius.md })
    .clip(true)
    .padding({ top: Space.xs, bottom: Space.xs })
  }

  // 等级主色：左边框 + 等级徽标着色。
  private accentColor(level: LogLevel): ResourceColor {
    if (level === 'warn') {
      return AppColor.warning;
    }
    if (level === 'error') {
      return AppColor.danger;
    }
    if (level === 'debug') {
      return AppColor.textSecondary;
    }
    return AppColor.info;
  }

  // 行底色用半透明叠加（ARGB），自动适配明暗主题；仅 Warning/Error 加重。
  private rowBackground(level: LogLevel): string {
    if (level === 'error') {
      return '#1FDC2626';
    }
    if (level === 'warn') {
      return '#17D97706';
    }
    return '#00000000';
  }

  private messageColor(level: LogLevel): ResourceColor {
    return level === 'error' ? AppColor.danger : AppColor.textPrimary;
  }
}
