import { AppColor, FontSz, Space } from '../theme/Theme';

@Component
export struct SectionHeader {
  @Prop title: string = '';
  @Prop detail: string = '';
  // 左右内边距基准。默认 Space.lg（容器无左右 padding 时自带缩进）；
  // 若父容器已设左右 padding，传 0 避免双倍缩进（实际缩进 = 容器 padding + 4/0）。
  @Prop sidePadding: number = Space.lg;

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
    .padding({ left: this.sidePadding + Space.xs, right: this.sidePadding, top: Space.lg, bottom: Space.sm })
  }
}
