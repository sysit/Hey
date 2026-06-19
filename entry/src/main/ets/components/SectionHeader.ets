import { AppColor, FontSz, Space } from '../theme/Theme';

@Component
export struct SectionHeader {
  @Prop title: string = '';
  @Prop detail: string = '';

  build() {
    Column({ space: 2 }) {
      Text(this.title)
        .fontSize(FontSz.footnote)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColor.textTertiary)
        .width('100%')
      if (this.detail.length > 0) {
        Text(this.detail)
          .fontSize(FontSz.caption)
          .fontColor(AppColor.textTertiary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: Space.lg + Space.xs, right: Space.lg, top: Space.lg, bottom: Space.sm })
  }
}
