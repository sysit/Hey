import { AppColor, FontSz, Radius, Space } from '../../theme/Theme';

export type ClearLogHandler = () => void;
export type LogActionHandler = () => void;
export type CopyLogItemHandler = (item: string) => void;

@Component
export struct RuntimeLogPanel {
  clearLabel: string = '';
  copyLabel: string = '';
  shareLabel: string = '';
  items: Array<string> = [];
  emptyLabel: string = '';
  onClear: ClearLogHandler = () => {};
  onCopy: LogActionHandler = () => {};
  onShare: LogActionHandler = () => {};
  onCopyItem: CopyLogItemHandler = (_item: string) => {};

  build() {
    Column({ space: Space.md }) {
      Row({ space: Space.sm }) {
        Blank()
        Button(this.copyLabel)
          .height(30)
          .fontSize(FontSz.footnote)
          .backgroundColor(AppColor.surfaceAlt)
          .fontColor(AppColor.textSecondary)
          .borderRadius(Radius.sm)
          .padding({ left: Space.md, right: Space.md })
          .onClick(() => {
            this.onCopy();
          })
        Button(this.shareLabel)
          .height(30)
          .fontSize(FontSz.footnote)
          .backgroundColor(AppColor.surfaceAlt)
          .fontColor(AppColor.textSecondary)
          .borderRadius(Radius.sm)
          .padding({ left: Space.md, right: Space.md })
          .onClick(() => {
            this.onShare();
          })
        Button(this.clearLabel)
          .height(30)
          .fontSize(FontSz.footnote)
          .backgroundColor(AppColor.surfaceAlt)
          .fontColor(AppColor.textSecondary)
          .borderRadius(Radius.sm)
          .padding({ left: Space.md, right: Space.md })
          .onClick(() => {
            this.onClear();
          })
      }
      .width('100%')

      Column({ space: Space.sm }) {
        if (this.items.length === 0) {
          Text(this.emptyLabel)
            .fontSize(FontSz.footnote)
            .fontColor(AppColor.textTertiary)
            .width('100%')
        } else {
          ForEach(this.items, (item: string, index: number) => {
            Text(item)
              .fontSize(FontSz.footnote)
              .fontColor(index === 0 ? AppColor.textPrimary : AppColor.textTertiary)
              .width('100%')
              .onClick(() => {
                this.onCopyItem(item);
              })
          }, (item: string, index: number) => `${index}-${item}`)
        }
      }
      .width('100%')
      .padding(Space.md)
      .backgroundColor(AppColor.surfaceAlt)
      .borderRadius(Radius.md)
      .constraintSize({ minHeight: 120 })
    }
    .width('100%')
    .padding(Space.lg)
    .backgroundColor(AppColor.surface)
    .borderRadius(Radius.lg)
    .margin({ left: Space.lg, right: Space.lg })
  }
}
